.PHONY: ship lint check
ship:
	bash src/scripts/ship/ship.sh
lint:
	find src -type f \( -name '*.sh' -o -name dv \) -print0 | xargs -0 shellcheck -x -e SC1091
check: lint
