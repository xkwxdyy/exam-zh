#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const defaultInput =
  '/Users/xiakangwei/Downloads/2021-2026高考数学合集-LaTeX排版，带目录链接跳转）-20260810172915/' +
  '2021-2026高考数学合集-LaTeX排版，带目录链接跳转）.tex';
const defaultOutput = 'exam-zh-examples/math';

function option(name, fallback) {
  const position = process.argv.indexOf(name);
  return position === -1 ? fallback : process.argv[position + 1];
}

const inputPath = path.resolve(option('--input', defaultInput));
const outputDirectory = path.resolve(option('--output-dir', defaultOutput));
const source = fs.readFileSync(inputPath, 'utf8');

function cleanTitle(title) {
  return title
    .replace(/\s*数\s*学\s*$/u, ' 数学')
    .replace(/\s+/gu, ' ')
    .trim();
}

function displayTitle(title) {
  return cleanTitle(title).replace(/\s+数学$/u, '');
}

function normalizeProsePunctuation(text) {
  const replacements = new Map([
    [',', '，'],
    [';', '；'],
    [':', '：'],
    ['!', '！'],
    ['?', '？'],
  ]);
  let inMath = false;
  let normalized = '';
  for (let index = 0; index < text.length; index += 1) {
    const character = text[index];
    if (character === '$' && text[index - 1] !== '\\') {
      inMath = !inMath;
      normalized += character;
      continue;
    }
    if (!inMath && (replacements.has(character) || character === '.')) {
      let lookahead = index + 1;
      while (/\s/u.test(text[lookahead] ?? '')) lookahead += 1;
      const next = text[lookahead] ?? '';
      const previous = text[index - 1] ?? '';
      const nextIsCjkOrMath = /[\u3400-\u9fff$]/u.test(next);
      const isDecimalPoint = character === '.' && /\d/u.test(previous) && /\d/u.test(next);
      const isChoiceLabel = character === '.' && /[A-D]/u.test(previous);
      const shouldReplace = character === '.'
        ? !isDecimalPoint && !isChoiceLabel && (nextIsCjkOrMath || next === '')
        : nextIsCjkOrMath;
      if (shouldReplace) {
        normalized = normalized.replace(/\s+$/u, '');
        if (/[\$\]]/u.test(previous)) normalized += '\\nobreak ';
        normalized += character === '.' ? '。' : replacements.get(character);
        continue;
      }
    }
    normalized += character;
  }
  return normalized;
}

function normalizeLatex(text) {
  return normalizeProsePunctuation(text
    .replace(
      /\(187373ha\\_\\_书\)，2030昆hemonth，2030ha\\_\\_上，2030ha\\_fig，m。3 小题满分 8 分[.。]/gu,
      '(16 分) 本题共有 3 个小题，第 1 小题满分 4 分，第 2 小题满分 4 分，第 3 小题满分 8 分。',
    )
    .replace(/\\\(/gu, '$')
    .replace(/\\\)/gu, '$')
    .replace(/\\circled\{([^{}]+)\}/gu, '\\tikzcirclednumber{$1}')
    .replace(/\\mathrm\{e\}/gu, '\\eu{}')
    .replace(/\\mathrm\{i\}/gu, '\\iu{}')
    .replace(/\\pi\b/gu, '\\uppi')
    .replace(/⏜/gu, '\\frown')
    .replace(/\\bot\b/gu, '\\perp')
    .replace(/\/\//gu, '\\parallel{}')
    .replace(/\\hspace\*\{3em\}\s*/gu, '')
    .replace(
      /\\includegraphics\[max width\s*=\s*([^\]]+)\]\{images\/([^}]+)\}/gu,
      '\\includegraphics[width = $1]{$2}',
    )
    .replace(/\{images\/([^}]+)\}/gu, '{$1}')
    .replace(/(?:\\_){3,}/gu, '\\fillin[width = 5em][]')
    .replace(/^\s+$/gmu, '')
    .trim());
}

function extractPoints(text) {
  const match = text.match(
    /^\s*(?<prefix>\[[^\]\r\n]+\]\s*)?[（(]+\s*(?<score>[^()（）]+?)[）)]+\s*/u,
  );
  if (!match) {
    return { points: undefined, text };
  }

  const scoreText = match.groups.score.trim();
  const prefix = match.groups.prefix?.trimEnd();
  const remainingText = `${prefix ? `${prefix} ` : ''}${text.slice(match[0].length)}`;
  const total = scoreText.match(
    /^(?:(?:本题|本小题)\s*)?(?:满分\s*)?(\d+)\s*分$/u,
  );
  if (total) {
    return { points: total[1], text: remainingText };
  }

  const subquestionPattern = /第\s*\d+\s*小题\s*满分\s*(\d+)\s*分/gu;
  const subquestionPoints = [...scoreText.matchAll(subquestionPattern)];
  const remainder = scoreText
    .replace(subquestionPattern, '')
    .replace(/[\s，,、；;。.]+/gu, '');
  if (subquestionPoints.length > 0 && remainder === '') {
    const points = subquestionPoints.reduce((sum, item) => sum + Number(item[1]), 0);
    return { points: String(points), text: remainingText };
  }

  return { points: undefined, text };
}

function extractDetailedPoints(text) {
  const detail = text.match(/^本题共有\s*\d+\s*个小题[^。.]*[。.]/u);
  if (!detail) return undefined;

  const points = [...detail[0].matchAll(/第\s*\d+\s*小题\s*满分\s*(\d+)\s*分/gu)];
  if (points.length === 0) return undefined;
  const normalizedDetail = detail[0].replace(
    /^本题共有\s*\d+\s*个小题/u,
    `本题共有 ${points.length} 个小题`,
  );
  return {
    points: points.reduce((sum, item) => sum + Number(item[1]), 0),
    detail: normalizedDetail,
    text: text.slice(detail[0].length).trimStart(),
  };
}

function convertNestedSubquestions(text) {
  const marker = /^\s*(?:\(([ivxlcdm]+)\)|（([ivxlcdm]+)）)\s*/gmu;
  const matches = [...text.matchAll(marker)];
  if (matches.length === 0) {
    return text.trim();
  }

  const introductoryText = text.slice(0, matches[0].index).trim();
  const items = matches.map((match, index) => {
    const next = matches[index + 1];
    return text.slice(match.index + match[0].length, next?.index).trim();
  });
  const prefix = introductoryText ? `${introductoryText}\n\n` : '';
  return `${prefix}\\begin{enumerate}\n${items
    .map((item) => `  \\item ${item}`)
    .join('\n')}\n\\end{enumerate}`;
}

function convertSubquestions(text) {
  const marker = /^\s*(?:\((\d+)\)|（(\d+)）)\s*/gmu;
  const matches = [...text.matchAll(marker)];
  if (matches.length === 0) {
    return text.trim();
  }

  const introductoryText = text.slice(0, matches[0].index).trim();
  const items = matches.map((match, index) => {
    const next = matches[index + 1];
    const item = text.slice(match.index + match[0].length, next?.index).trim();
    return convertNestedSubquestions(item);
  });
  const prefix = introductoryText ? `${introductoryText}\n\n` : '';
  return `${prefix}\\begin{enumerate}\n${items
    .map((item) => `  \\item ${item}`)
    .join('\n')}\n\\end{enumerate}`;
}

function figureWidth(graphic) {
  const match = graphic.match(/width\s*=\s*([0-9.]+)\\(?:text|line)width/u);
  return match ? Number(match[1]) : undefined;
}

function applyFigureLayout(text) {
  const centerPattern = /\\begin\{center\}\s*(\\includegraphics(?:\[[^\]]*\])?\{[^}]+\})\s*\\end\{center\}/gu;
  const constrainedText = text.replace(centerPattern, (block, graphic) => {
    if (figureWidth(graphic) <= 0.5) {
      return block;
    }
    return block.replace(/\\textwidth/gu, '\\linewidth');
  });
  const matches = [...constrainedText.matchAll(centerPattern)];
  if (matches.length !== 1 || !matches[0][1] || figureWidth(matches[0][1]) > 0.5) {
    return constrainedText;
  }

  const graphic = matches[0][1];
  const prose = `${constrainedText.slice(0, matches[0].index)}${constrainedText.slice(
    matches[0].index + matches[0][0].length,
  )}`.trim();
  if (!prose) {
    return constrainedText;
  }

  return `\\textfigure[fig-pos = right, auto-text-width = true, min-text-width = .45\\linewidth, top = 1]{\n${prose}\n}{\n  ${graphic}\n}`;
}

function splitChoices(text) {
  const marker = /(?:^|\s)([ABCD])\.\s+/gmu;
  const matches = [...text.matchAll(marker)];
  const labels = matches.map((match) => match[1]);
  if (!['A', 'B', 'C', 'D'].every((label) => labels.includes(label))) {
    return { stem: text, options: undefined };
  }

  const first = matches.find((match) => match[1] === 'A');
  const ordered = matches.filter(
    (match) => match.index >= first.index && ['A', 'B', 'C', 'D'].includes(match[1]),
  );
  const firstFour = [];
  for (const label of ['A', 'B', 'C', 'D']) {
    const match = ordered.find((candidate) => candidate[1] === label && !firstFour.includes(candidate));
    if (!match) {
      return { stem: text, options: undefined };
    }
    firstFour.push(match);
  }
  if (firstFour.some((match, index) => index > 0 && match.index <= firstFour[index - 1].index)) {
    return { stem: text, options: undefined };
  }

  const markerStart = (match) => match.index + match[0].lastIndexOf(match[1]);
  const stem = text.slice(0, markerStart(firstFour[0])).trim();
  const options = firstFour.map((match, index) => {
    const next = firstFour[index + 1];
    return text
      .slice(match.index + match[0].length, next ? markerStart(next) : text.length)
      .trim();
  });
  return { stem, options };
}

function normalizeChoiceItem(text) {
  return text
    .replace(
      /\\begin\{center\}\s*(\\includegraphics(?:\[[^\]]*\])?\{[^}]+\})\s*\\end\{center\}/gu,
      '$1',
    )
    .trim();
}

function convertQuestion(rawText, kind, sectionTitle) {
  let text = normalizeLatex(rawText);
  let { points, text: textWithoutPoints } = kind === 'problem' ? extractPoints(text) : { text };
  text = textWithoutPoints;
  const pointDetails = kind === 'problem' ? extractDetailedPoints(text) : undefined;
  if (pointDetails !== undefined) {
    points = String(pointDetails.points);
    text = pointDetails.text;
  }

  const options = kind === 'question' && /选择题/u.test(sectionTitle) ? splitChoices(text) : undefined;
  let body;
  if (options?.options) {
    const stem = applyFigureLayout(`${options.stem} \\paren`);
    body = `${stem}\n\n\\begin{choices}\n${options.options
      .map((item) => `  \\item ${normalizeChoiceItem(item)}`)
      .join('\n')}\n\\end{choices}`;
  } else {
    body = kind === 'problem'
      ? applyFigureLayout(convertSubquestions(text))
      : applyFigureLayout(text);
  }
  if (pointDetails !== undefined) {
    body = `${pointDetails.detail}${body ? ` ${body}` : ''}`;
  }
  if (body.startsWith('[')) {
    body = `\\relax\n${body}`;
  }

  const pointOptions = [];
  if (points) pointOptions.push(`points = ${points}`);
  if (pointDetails !== undefined) pointOptions.push('points-separate-par = false');
  const pointOption = pointOptions.length > 0 ? `[${pointOptions.join(', ')}]` : '';
  return `\\begin{${kind}}${pointOption}\n${body}\n\\end{${kind}}`;
}

function convertSection(title, rawText, inheritedKind) {
  const normalizedTitle = cleanTitle(normalizeLatex(title));
  const isMainSection = /^[一二三四五六七八九十]+、/u.test(normalizedTitle);
  const sectionTitle = isMainSection
    ? normalizedTitle.replace(/^[一二三四五六七八九十]+、\s*/u, '')
    : normalizedTitle;
  const kind = /解答题/u.test(normalizedTitle)
    ? 'problem'
    : /(?:选择题|填空题)/u.test(normalizedTitle)
      ? 'question'
      : inheritedKind;
  const questionMarker = /^(\d+)\.(?!\d)\s*/gmu;
  const matches = [...rawText.matchAll(questionMarker)];

  const sectionCommand = isMainSection ? 'section' : 'subsection';
  if (matches.length === 0) {
    return { kind, output: `\\${sectionCommand}{${sectionTitle}}\n${normalizeLatex(rawText)}` };
  }

  const prefix = normalizeLatex(rawText.slice(0, matches[0].index));
  const questions = matches.map((match, index) => {
    const next = matches[index + 1];
    return convertQuestion(
      rawText.slice(match.index + match[0].length, next?.index),
      kind,
      normalizedTitle,
    );
  });
  return {
    kind,
    output: `\\${sectionCommand}{${sectionTitle}}\n\\questionsetup{index = 1}${prefix ? `\n${prefix}` : ''}\n\n${questions.join('\n\n')}`,
  };
}

function convertIntroduction(rawText) {
  const text = normalizeLatex(rawText)
    .replace(/\\section\*\{(\d+\.\s*[^{}]+)\}/gu, '$1')
    .replace(/绝密\s*\\ding\{72\}\s*启用前试卷类型\s*:?\s*[A-Z]?/gu, '')
    .trim();
  const firstItem = text.match(/(?:^|\n)\s*(?:注意事项[：:]\s*)?1[.。]\s*/u);
  if (!firstItem?.index && firstItem?.index !== 0) {
    return text;
  }

  const introduction = text.slice(0, firstItem.index).trim();
  const noticeText = text.slice(firstItem.index).replace(/^\s*注意事项[：:]\s*/u, '');
  const marker = /(?:^|\n)\s*([1-4])[.。]\s*/gmu;
  const matches = [...noticeText.matchAll(marker)];
  if (matches.length === 0) {
    return introduction;
  }
  const items = matches.map((match, index) => {
    const next = matches[index + 1];
    return noticeText.slice(match.index + match[0].length, next?.index).trim();
  });
  return `${introduction ? `${introduction}\n\n` : ''}\\begin{notice}\n${items
    .map((item) => `  \\item ${item}`)
    .join('\n')}\n\\end{notice}`;
}

function convertPaper(title, rawText) {
  rawText = rawText
    .replace(/绝密\s*\\ding\{72\}\s*启用前试卷类型\s*:?\s*[A-Z][\s\S]*$/u, '')
    .replace(/\n\s*20\d{2}\s*高考[\s\S]*$/u, '')
    .replace(/\n\s*绝密[\s\S]*$/u, '');
  const sectionPattern = /^(?:\\section\*\{([^\n{}]+)\}|([一二三四五六七八九十]+、(?:选择题|填空题|解答题)[^\n]*))\s*$/gmu;
  const matchedSections = [...rawText.matchAll(sectionPattern)];
  const sectionHeading = (section) => section?.[1] ?? section?.[2] ?? '';
  const malformedNotice = sectionHeading(matchedSections[0]).match(/^[1-4]\.\s+/u);
  const sections = malformedNotice ? matchedSections.slice(1) : matchedSections;
  const introductoryText = malformedNotice
    ? `${rawText.slice(0, matchedSections[0].index)}${sectionHeading(matchedSections[0])}\n${rawText.slice(
        matchedSections[0].index + matchedSections[0][0].length,
        sections[0]?.index,
      )}`
    : rawText.slice(0, sections[0]?.index);
  let kind = 'question';
  const convertedSections = sections.map((section, index) => {
    const next = sections[index + 1];
    const converted = convertSection(
      sectionHeading(section),
      rawText.slice(section.index + section[0].length, next?.index),
      kind,
    );
    kind = converted.kind;
    return converted.output;
  });
  const paperDisplayTitle = displayTitle(title);
  return `\\setcounter{section}{0}\n\\phantomsection\n\\addcontentsline{toc}{chapter}{${paperDisplayTitle}}\n\\title{${paperDisplayTitle}}\n\\subject{数学}\n\\secret\n\\maketitle\n\n${convertIntroduction(
    introductoryText,
  )}\n\n${convertedSections.join('\n\n')}`;
}

const beginDocument = source.indexOf('\\begin{document}');
if (beginDocument === -1) {
  throw new Error('The source does not contain \\begin{document}.');
}
const documentBody = source
  .slice(beginDocument + '\\begin{document}'.length)
  .replace(/\\end\{document\}[\s\S]*$/u, '');
const paperPattern = /^\\section\*\{(20\d{2} 年普通高等学校招生全国统一考试[^\n{}]*数\s*学)\}\s*$/gmu;
const papers = [...documentBody.matchAll(paperPattern)];
if (papers.length === 0) {
  throw new Error('No exam-paper headings were found.');
}

const convertedPapers = papers.map((paper, index) => {
  const next = papers[index + 1];
  return convertPaper(
    paper[1],
    documentBody.slice(paper.index + paper[0].length, next?.index),
  );
});
const imageNames = [
  ...new Set(
    [...documentBody.matchAll(/\\includegraphics(?:\[[^\]]*\])?\{images\/([^}]+)\}/gu)].map(
      (match) => match[1],
    ),
  ),
];

const setup = `% !TeX program = xelatex
\\usepackage{esint,stmaryrd}
\\usepackage{adjustbox}
\\usepackage{graphicx}
\\usepackage{booktabs,array,multirow,tabularx,makecell}
\\xeCJKsetup{CheckFullRight = true}

\\graphicspath{{images/}}

\\examsetup{
  page = {
    size = a3paper,
    show-columnline = false,
    foot-type = separate
  },
  style/fullwidth-stop = catcode,
  choices = {
    label = \\Alph*.,
    label-pos = top-left
  },
  textfigure = {
    column-gap = 1em,
    bottom-sep = 1ex plus .5ex minus .5ex
  }
}

\\everymath{\\displaystyle}
`;
const document = `% !TeX program = xelatex
\\documentclass[zihao = -4]{exam-zh}
\\input{gaokao-2021-2026-setup.tex}
\\raggedbottom

\\begin{document}

\\begin{center}
  {\\LARGE\\bfseries 2021--2026 高考数学合集\\par}
  \\vspace{.5\\baselineskip}
  {\\large 使用 exam-zh 重新编排\\par}
  \\vspace{.75\\baselineskip}
  {\\Large\\bfseries 目录\\par}
\\end{center}
\\vspace{.5\\baselineskip}
\\makeatletter
\\@starttoc{toc}
\\makeatother
\\clearpage

${convertedPapers.join('\n\n\\clearpage\n\n')}

\\end{document}
`;

fs.mkdirSync(outputDirectory, { recursive: true });
fs.writeFileSync(path.join(outputDirectory, 'gaokao-2021-2026-setup.tex'), setup);
fs.writeFileSync(path.join(outputDirectory, 'gaokao-2021-2026.tex'), document);

const inputImages = path.join(path.dirname(inputPath), 'images');
const outputImages = path.join(outputDirectory, 'images');
fs.mkdirSync(outputImages, { recursive: true });
for (const imageName of imageNames) {
  fs.copyFileSync(path.join(inputImages, imageName), path.join(outputImages, imageName));
}

const questionCount = (document.match(/\\begin\{question\}/gu) ?? []).length;
const problemCount = (document.match(/\\begin\{problem\}/gu) ?? []).length;
const choicesCount = (document.match(/\\begin\{choices\}/gu) ?? []).length;
console.log(
  `Converted ${papers.length} papers, ${questionCount} question environments, ${problemCount} problem environments, ${choicesCount} choice groups, and ${imageNames.length} images.`,
);
