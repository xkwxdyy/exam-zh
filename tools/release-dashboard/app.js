(() => {
  "use strict";

  const apiVersion = 3;
  const state = { workflows: [], status: null, token: "", filter: "all", activeJob: null, cursor: 0, pollTimer: null, backendCompatible: true };
  const $ = (selector) => document.querySelector(selector);
  const $$ = (selector) => [...document.querySelectorAll(selector)];
  const riskText = { safe: "本地 · 可重复", write: "本地 · 写入文件", interactive: "Claude · 终端确认", mutating: "会改变仓库", external: "外部 · 需确认" };
  const stageText = { changes: "Changes", verify: "Verify", package: "Package", publish: "Publish", observe: "Observe" };
  const statusText = { queued: "排队中", running: "运行中", success: "完成", failed: "失败", cancelled: "已取消" };
  const commonChainSteps = [
    ["校验 Changelog", "校验片段、归档、清单与 Markdown"],
    ["发布工具测试", "验证发布脚本与元数据"],
    ["XeTeX 回归测试", "执行 l3build check"],
    ["固化发布说明", "生成版本清单并归档片段"],
    ["编译并构建归档", "编译示例、双手册并生成两个发布包"],
    ["检查 CTAN ZIP", "检查压缩包完整性"],
    ["校验 CTAN 元数据", "核对版本、日期和公告"],
    ["Git 提交", "暂存并提交当前发布变更"],
    ["创建 Git Tag", "创建带注释的 vX.Y.Z Tag"],
    ["推送 GitHub main", "推送发布提交到 GitHub"],
    ["推送 GitHub Tag", "推送 Tag 到 GitHub"],
    ["推送 Gitee main", "推送发布提交到 Gitee"],
    ["推送 Gitee Tag", "推送 Tag 到 Gitee"],
    ["生成 Release 说明", "从版本清单渲染中文 Release notes"],
    ["发布 GitHub Release", "上传 Release 用户包并发布"],
    ["发布 Gitee Release", "上传 Release 用户包并发布"],
  ];
  const ctanChainSteps = [
    ["检查 CTAN 发布条件", "核对已存在 Tag 的版本与发布元数据"],
    ["触发 CTAN 发布", "调用 CTAN GitHub Actions 工作流"],
  ];

  function chainStepsForTarget(target) {
    if (target === "ctan") return ctanChainSteps;
    const steps = [...commonChainSteps];
    if (target === "all") steps.push(["触发 CTAN 发布", "调用 CTAN GitHub Actions 工作流"]);
    return steps;
  }

  function iconRefresh() {
    if (window.lucide?.createIcons) window.lucide.createIcons({ attrs: { "stroke-width": 1.7 } });
  }

  async function api(path, options = {}) {
    const headers = { ...(options.body ? { "Content-Type": "application/json" } : {}), ...(options.headers || {}) };
    const response = await fetch(path, { ...options, headers });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(data.error || `请求失败（${response.status}）`);
    return data;
  }

  function setConnection(kind, text) {
    const element = $("#connection-state");
    element.className = `connection ${kind}`;
    element.innerHTML = `<span class="status-dot"></span>${text}`;
  }

  function toast(message, kind = "") {
    const item = document.createElement("div");
    item.className = `toast ${kind}`;
    item.textContent = message;
    $("#toast-region").append(item);
    window.setTimeout(() => item.remove(), 4500);
  }

  function readParams() {
    return {
      version: $("#version-input").value.trim(),
      date: $("#date-input").value,
      message: $("#message-input").value.trim(),
      skipCompile: $("#skip-compile-input").checked,
      publishTarget: $("input[name='publish-target']:checked")?.value || "platforms",
    };
  }

  function renderChain(job = null) {
    const target = $("input[name='publish-target']:checked")?.value || "platforms";
    const chainSteps = chainStepsForTarget(target);
    const count = chainSteps.length;
    const current = Number(job?.stepNumber || 0);
    const running = ["queued", "running"].includes(job?.status);
    const terminal = job?.status === "success";
    const failed = job?.status === "failed" || job?.status === "cancelled";
    $("#release-chain").innerHTML = chainSteps.slice(0, count).map(([title, description], index) => {
      const number = index + 1;
      let kind = "pending";
      if (running && number < current) kind = "done";
      if (running && number === current) kind = "active";
      if (failed && number < current) kind = "done";
      if (failed && number === current) kind = "failed";
      if (terminal) kind = number < count || job.status === "success" ? "done" : "awaiting";
      return `<li class="chain-step ${kind}"><b>${title}</b><small>${description}</small></li>`;
    }).join("");
    $("#pipeline-state").textContent = job ? `${statusText[job.status] || job.status}${job.step ? ` · ${job.step}` : ""}` : "按编号从上到下执行";
    iconRefresh();
  }

  function renderStatus(status) {
    state.status = status;
    $("#branch-value").textContent = status.branch || "detached";
    $("#head-value").textContent = status.head || "--";
    $("#updated-value").textContent = status.refreshedAt ? status.refreshedAt.slice(11, 16) : "--";
    $("#version-value").textContent = status.version ? `v${status.version}` : "v--";
    $("#date-value").textContent = status.releaseDate || "未设置日期";
    if (!$("#version-input").dataset.initialized && status.version) {
      const parts = status.version.split(".").map(Number);
      $("#version-input").value = parts.length === 3 && parts.every(Number.isInteger) ? `${parts[0]}.${parts[1]}.${parts[2] + 1}` : status.version;
      $("#version-input").dataset.initialized = "true";
    }
    if (!$("#date-input").dataset.initialized) {
      $("#date-input").value = status.today || "";
      $("#date-input").dataset.initialized = "true";
    }
    $("#dirty-value").textContent = status.dirtyCount ? `${status.dirtyCount} 项` : "干净";
    $("#dirty-detail").textContent = status.dirtyFiles?.[0]?.replace(/^..\s/, "") || "无未提交文件";
    $("#fragment-value").textContent = String(status.fragmentCount ?? "--");
    $("#changelog-value").textContent = status.changelogOk ? "通过" : "待处理";
    $("#changelog-value").style.color = status.changelogOk ? "var(--green)" : "var(--yellow)";
    $("#changelog-detail").textContent = status.changelogOk ? "结构同步" : "运行 check-changelog";
    $("#tag-value").textContent = status.latestTag || "无 Tag";
    const checks = [
      ["Python", status.tools?.python], ["l3build", status.tools?.l3build], ["git", status.tools?.git], ["gh", status.tools?.gh], ["Claude", status.tools?.claude], ["Gitee token", status.tools?.giteeToken],
    ];
    $("#tool-checks").innerHTML = checks.map(([label, ready]) => `<span class="tool-check ${ready ? "ready" : ""}"><i></i>${label}</span>`).join("");
    renderArtifacts(status.artifacts || []);
    renderJobs(status.jobs || []);
    renderChain(state.activeJob);
  }

  function renderArtifacts(artifacts) {
    $("#artifact-list").innerHTML = artifacts.map((item) => {
      const size = item.exists ? `${Math.max(1, Math.round(item.size / 1024))} KB` : "未生成";
      return `<div class="artifact-item ${item.exists ? "exists" : ""}" title="${item.path}"><i data-lucide="${item.exists ? "check-circle-2" : "circle-dashed"}"></i><b>${item.path}</b><small>${size}</small></div>`;
    }).join("");
    iconRefresh();
  }

  function renderJobs(jobs) {
    if (!jobs.length) {
      $("#job-history").innerHTML = `<span class="empty-state">还没有运行记录</span>`;
      return;
    }
    $("#job-history").innerHTML = jobs.slice(0, 6).map((job) => {
      const time = job.createdAt ? job.createdAt.slice(11, 16) : "--";
      return `<div class="job-row ${job.status}"><i></i><span><b>${job.title}</b><small>${statusText[job.status] || job.status}</small></span><time>${time}</time></div>`;
    }).join("");
    $("#last-job-time").textContent = jobs[0].createdAt ? jobs[0].createdAt.replace("T", " ").slice(0, 16) : "--";
  }

  function renderWorkflows() {
    const filtered = state.workflows.filter((item) => item.id !== "release-pipeline" && (state.filter === "all" || item.stage === state.filter));
    $("#action-count").textContent = `${filtered.length} 项`;
    $("#action-list").innerHTML = filtered.map((item) => {
      const risk = item.risk || "safe";
      const buttonIcon = item.executor === "claude" ? "terminal" : "play";
      return `<article class="action-card" data-risk="${risk}" data-stage="${item.stage}">
        <div class="action-card-top"><span class="action-icon"><i data-lucide="${item.icon || "play"}"></i></span><div><h3>${item.title}</h3><p>${item.description}</p></div></div>
        <div class="action-footer"><span class="risk-label ${risk}">${riskText[risk] || stageText[item.stage]}</span><button class="run-button" type="button" data-workflow-id="${item.id}"><i data-lucide="${buttonIcon}"></i>${item.executor === "claude" ? "打开终端" : "执行"}</button></div>
      </article>`;
    }).join("");
    if (!filtered.length) $("#action-list").innerHTML = `<div class="loading-block">这个阶段暂时没有可执行动作。</div>`;
    iconRefresh();
    $$(".run-button").forEach((button) => button.addEventListener("click", () => requestRun(button.dataset.workflowId)));
    updateRunAvailability();
  }

  function updateRunAvailability() {
    const running = Boolean(state.activeJob && ["queued", "running"].includes(state.activeJob.status));
    $$(".run-button").forEach((button) => { button.disabled = running; });
    $("#pipeline-launch").disabled = running || !state.backendCompatible;
    $("#manual-changelog").disabled = running || !state.backendCompatible;
  }

  function workflowFor(id) { return state.workflows.find((item) => item.id === id); }

  function requestRun(id) {
    const workflow = workflowFor(id);
    if (!workflow) {
      toast(id === "release-pipeline" ? "Dashboard 服务端版本过旧，请重新运行 make dashboard" : "工作流不存在，请刷新页面", "error");
      return;
    }
    const params = readParams();
    const missing = (workflow.requires || []).filter((name) => !params[name]);
    if (missing.length) {
      const labels = { version: "目标版本", date: "发布日期", message: "提交信息" };
      toast(`请先填写：${missing.map((name) => labels[name] || name).join("、")}`, "error");
      return;
    }
    const confirmation = workflow.confirmation;
    if (!confirmation) return runWorkflow(id, params);
    const dialog = $("#confirm-dialog");
    $("#dialog-title").textContent = workflow.title;
    $("#dialog-description").textContent = workflow.description;
    $("#dialog-command").textContent = workflow.command.replaceAll("{version}", params.version || "X.Y.Z").replaceAll("{date}", params.date || "YYYY-MM-DD");
    $("#confirm-prompt").textContent = confirmation === "VERSION" ? `输入版本号 ${params.version || "X.Y.Z"} 继续` : `输入 ${confirmation} 继续`;
    $("#confirm-input").value = "";
    $("#confirm-input-wrap").hidden = false;
    $("#dialog-confirm").innerHTML = `<i data-lucide="play"></i>继续执行`;
    dialog.dataset.targetConfirmation = "false";
    dialog.dataset.workflowId = id;
    dialog.dataset.params = JSON.stringify(params);
    if (typeof dialog.showModal === "function") dialog.showModal(); else dialog.setAttribute("open", "");
    window.setTimeout(() => $("#confirm-input").focus(), 40);
  }

  function closeDialog() { const dialog = $("#confirm-dialog"); if (dialog.open) dialog.close(); else dialog.removeAttribute("open"); }

  async function confirmDialogRun() {
    const dialog = $("#confirm-dialog");
    const workflow = workflowFor(dialog.dataset.workflowId);
    if (!workflow) return closeDialog();
    const params = JSON.parse(dialog.dataset.params || "{}");
    const targetConfirmation = dialog.dataset.targetConfirmation === "true";
    const expected = workflow.confirmation === "VERSION" ? String(params.version || "").replace(/^v/, "") : workflow.confirmation;
    if (!targetConfirmation && $("#confirm-input").value.trim() !== expected) { toast(`确认词不匹配，应为 ${expected}`, "error"); return; }
    closeDialog();
    await runWorkflow(workflow.id, params);
  }

  async function runWorkflow(id, params) {
    try {
      const job = await api("/api/run", { method: "POST", headers: { "X-Workflow-Token": state.token }, body: JSON.stringify({ workflowId: id, params }) });
      state.activeJob = job; state.cursor = 0;
      $("#console-output").textContent = "";
      setConsole(job, true);
      pollJob(job.id);
    } catch (error) { toast(error.message, "error"); }
  }

  function setConsole(job, running = false) {
    const dock = $("#console-dock");
    dock.classList.toggle("has-output", running || Boolean($("#console-output").textContent.trim()));
    dock.classList.toggle("running", running || job.status === "running" || job.status === "queued");
    dock.classList.toggle("success", job.status === "success");
    dock.classList.toggle("failed", ["failed", "cancelled"].includes(job.status));
    $("#console-title").textContent = job.title || "任务控制台";
    $("#console-status").textContent = running ? "运行中" : (statusText[job.status] || "等待操作");
    $("#cancel-button").disabled = !running;
    renderChain(job);
  }

  async function pollJob(id) {
    window.clearTimeout(state.pollTimer);
    try {
      const job = await api(`/api/jobs/${id}?cursor=${state.cursor}`);
      state.activeJob = { ...state.activeJob, ...job }; state.cursor = job.cursor;
      if (job.logs?.length) { const output = $("#console-output"); if (output.querySelector(".console-placeholder")) output.textContent = ""; output.textContent += `${output.textContent ? "\n" : ""}${job.logs.join("\n")}`; output.scrollTop = output.scrollHeight; $("#console-dock").classList.add("has-output"); }
      setConsole(state.activeJob, ["queued", "running"].includes(job.status));
      if (["queued", "running"].includes(job.status)) state.pollTimer = window.setTimeout(() => pollJob(id), 650);
      else { await refreshStatus(); toast(`${job.title}：${statusText[job.status] || job.status}`, job.status === "success" ? "success" : "error"); updateRunAvailability(); }
    } catch (error) { toast(error.message, "error"); }
  }

  async function refreshStatus() {
    try { renderStatus(await api("/api/status")); setConnection("ready", "本地服务已连接"); }
    catch (error) { setConnection("error", "服务不可用"); toast(error.message, "error"); }
  }

  function bindUI() {
    $$("[data-stage-filter]").forEach((button) => button.addEventListener("click", () => { state.filter = button.dataset.stageFilter; $$("[data-stage-filter]").forEach((item) => item.classList.toggle("active", item === button)); renderWorkflows(); }));
    $("#pipeline-launch").addEventListener("click", () => requestRun("release-pipeline"));
    $("#manual-changelog").addEventListener("click", () => requestRun("ai-changelog"));
    $$(`input[name="publish-target"]`).forEach((input) => input.addEventListener("change", () => {
      $$(".target-option").forEach((option) => option.classList.toggle("selected", option.querySelector("input") === input && input.checked));
      renderChain(state.activeJob);
    }));
    $("#refresh-button").addEventListener("click", refreshStatus); $("#status-refresh").addEventListener("click", refreshStatus);
    $("#clear-console").addEventListener("click", () => { $("#console-output").innerHTML = `<span class="console-placeholder">选择上方工作流，执行日志会显示在这里。</span>`; $("#console-dock").classList.remove("has-output"); });
    $("#cancel-button").addEventListener("click", async () => { if (!state.activeJob) return; try { state.activeJob = await api(`/api/jobs/${state.activeJob.id}/cancel`, { method: "POST", headers: { "X-Workflow-Token": state.token }, body: "{}" }); setConsole(state.activeJob, true); pollJob(state.activeJob.id); } catch (error) { toast(error.message, "error"); } });
    $("#dialog-cancel").addEventListener("click", closeDialog); $("#dialog-confirm").addEventListener("click", confirmDialogRun);
    $("#confirm-dialog").addEventListener("click", (event) => { if (event.target === $("#confirm-dialog")) closeDialog(); });
    $("#confirm-input").addEventListener("keydown", (event) => { if (event.key === "Enter") confirmDialogRun(); });
    window.setInterval(refreshStatus, 5000);
  }

  async function bootstrap() {
    try {
      const data = await api("/api/bootstrap");
      state.backendCompatible = data.apiVersion === apiVersion;
      state.token = data.token;
      state.workflows = data.workflows;
      renderStatus(data.status);
      renderChain(null);
      renderWorkflows();
      if (!state.backendCompatible) toast("前后端版本不一致，请重新运行 make dashboard", "error");
      setConnection("ready", "本地服务已连接");
      bindUI();
      const active = (data.status.jobs || []).find((job) => job.id === data.status.activeJobId);
      if (active) {
        state.activeJob = active;
        state.cursor = 0;
        $("#console-output").textContent = "";
        setConsole(active, true);
        pollJob(active.id);
        updateRunAvailability();
      }
    } catch (error) { setConnection("error", "服务不可用"); $("#action-list").innerHTML = `<div class="loading-block">无法连接本地 dashboard：${error.message}</div>`; }
  }

  bootstrap();
})();
