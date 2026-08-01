# Retained Visual Fixtures

Alongside `l3build` inputs and expected logs, this directory contains a small
set of reviewed visual fixtures.  Each manual fixture keeps the minimal TeX
source required to reproduce it and a final PNG for quick inspection.

- `fillin-auto-width-demo.tex` and `.png` demonstrate `width = auto` in
  student and teacher versions, including punctuation immediately after a
  fill-in.
- `cjkunderline-punct-test.tex` and `.png` compare a CJK underline with
  punctuation outside and inside the underline, preserving the line-break
  behavior that must be checked visually.
- `fillin-auto-hidden-edge-cases-1.png` and `-2.png` are the reviewed student
  and teacher renderings of `fillin-auto-hidden-edge-cases.tex`.

Compile candidates into `tmp/`, inspect them, and replace a retained rendering
only when the visual change is intentional.  Remove all contents of `tmp/`
afterward.
