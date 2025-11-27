.PHONY: all check-updates check-deps ensure-venv

VENV_DIR = $(PWD)/.venv
PYTHON = $(VENV_DIR)/bin/python
PIP = $(VENV_DIR)/bin/pip
REQUIREMENTS_CHECK = $(VENV_DIR)/bin/requirementscheck

all: check-updates

ensure-venv:
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "Error: Virtual environment $(VENV_DIR) does not exist. Aborting."; \
		exit 1; \
	fi

check-deps: ensure-venv
	@if [ ! -f "$(REQUIREMENTS_CHECK)" ]; then \
		echo "Installing requirementscheck..."; \
		$(PIP) install requirementscheck || { echo "Error: Failed to install requirementscheck. Aborting."; exit 1; }; \
	fi

check-updates: check-deps
	@for file in $$(find . -maxdepth 2 -mindepth 2 -name requirements.txt); do \
		cd $$(dirname "$$file"); \
		$(REQUIREMENTS_CHECK) --no-confirm || { echo "Error: requirementscheck failed for $$file. Aborting."; exit 1; }; \
		cd - > /dev/null; \
	done

dryrun:
	docker run -it --rm \
		-v $HOME/.cache/root:/root/.cache \
		-v ./requirements.txt:/requirements.txt \
		python:3.13-slim-bookworm \
		bash -c " \
			apt-get update && \
			apt-get install -y --no-install-recommends build-essential && \
			pip install -r requirements.txt --extra-index-url https://pypi.nvidia.com \
		"
