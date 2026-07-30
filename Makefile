PYTHON ?= python3

.PHONY: changelog check-changelog ctan dashboard dashboard-test doc doc-basic \
	example examples examples-basic install prepare-release release save test

changelog:
	$(PYTHON) scripts/release_notes.py changelog

check-changelog:
	$(PYTHON) scripts/release_notes.py check

dashboard:
	$(PYTHON) scripts/workflow_dashboard.py --open

dashboard-test:
	$(PYTHON) scripts/test_workflow_dashboard.py

example:
	latexmk -xelatex example-single.tex

examples:
	latexmk -xelatex example-single.tex
	latexmk -xelatex example-multiple.tex

examples-basic:
	cd examples-basic && latexmk -xelatex 00-minimal.tex
	cd examples-basic && latexmk -xelatex 01-first-exam.tex
	cd examples-basic && latexmk -xelatex 02-math-basic.tex

ctan:
	l3build ctan

doc:
	cd doc && latexmk -xelatex exam-zh-doc.tex

doc-basic:
	cd doc-basic && latexmk -xelatex exam-zh-doc-basic.tex

install:
	l3build install

release:
	$(PYTHON) scripts/build.py $(VERSION)

prepare-release:
	$(PYTHON) scripts/release_notes.py prepare --version "$(VERSION)" --date "$(DATE)"

save:
	bash tools/l3build-save.sh

test:
	l3build check
