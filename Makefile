# Types of lines:
#  * Starting with (-), the flow continues even when the command fails.
#  * Starting with (@), the command is not printed on the screen.

BOLD=$(shell tput bold)
RED=$(shell tput setaf 1)
RESET=$(shell tput sgr0)

CURRENT_DIR = $(shell pwd)

#.PHONY: help init plan apply destroy rs-init
.PHONY: help build run

all: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

### Docker Build and Run

build: ## Build aws-devops-toolkit image with "tag:latest"
	@echo "Building $(RED)$(BOLD)khma-toolbox$(RESET) image with "latest" tag."
	docker build -t aws-devops-toolkit:latest .
	docker image ls aws-devops-toolkit

run: ## Run aws-devops-toolkit container from "tag:latest"
	@echo "Running $(RED)$(BOLD)khma-toolbox$(RESET) container from "latest" tag."
	docker run -it --rm \
		--name aws-devops-toolkit \
		-v $(CURRENT_DIR)/:/root/aws-devops-toolkit/ \
		-v ~/.ssh/:/root/.ssh/ \
		aws-devops-toolkit:latest