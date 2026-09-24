# pf-common has no build/install step of its own -- it's a library of shared
# Makefile snippets and scripts consumed by other repos (see README.md), not
# a service that gets deployed or run. This Makefile exists solely to
# activate this repo's own .githooks/pre-commit (word-check against the pf
# ecosystem), consistent with `make install` in every other pf-* repo.

.PHONY: install

install:
	git config core.hooksPath .githooks
