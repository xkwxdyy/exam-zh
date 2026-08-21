# CHANGELOG

## Unreleased

### Changed

- 统一开发、测试、清理和发布流程到 `scripts/workflow.zsh`。
- 将构建产物、发布包和历史文件分离到 `build/`、`dist/` 和 `archive/`。
- 增加环境检查、双示例回归编译和发布压缩包完整性校验。
- 加固发布流程：默认先编译示例，校验版本与日期，拒绝无意覆盖，并支持锁、`--dry-run`、`--force` 和 `--skip-test`。

## v2.10 - 2024-04-28

### Changed

- 修改 `\frac` 的定义
