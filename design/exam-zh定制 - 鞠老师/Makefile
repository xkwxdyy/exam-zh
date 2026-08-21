.PHONY: all single multiple compile test check doctor package clean help

WORKFLOW := scripts/workflow.zsh

all: test

single:
	zsh $(WORKFLOW) compile example-single.tex

multiple:
	zsh $(WORKFLOW) compile example-multiple.tex

compile:
	zsh $(WORKFLOW) compile $(FILE)

test check:
	zsh $(WORKFLOW) test

doctor:
	zsh $(WORKFLOW) doctor

package:
	zsh $(WORKFLOW) package $(if $(FORCE),--force,) $(VERSION) $(DATE)

clean:
	zsh $(WORKFLOW) clean

help:
	zsh $(WORKFLOW) help
