DOCKER_COMPOSE?=docker compose -f config/local/docker-compose.yaml
DOCKER?=docker
COMPOSER=$(DOCKER_COMPOSE) exec -T php composer
CONTAINERS=$(DOCKER) ps -a -q
RUN=$(DOCKER_COMPOSE) run --rm php
NODE=$(DOCKER_COMPOSE) run --rm node
NETWORK_NAME=api-skeleton

projects=$(shell ls -d endpoints/*/ 2>/dev/null | xargs -n1 basename)

env?=dev
profile?=dev

.DEFAULT_GOAL := help

help:
	@grep -E '(^[0-9a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

##
## Manage docker containers
##---------------------------------------------------------------------------


start: clear-containers up ## Remove & start containers

up: network ## Run containers
	$(DOCKER_COMPOSE) up -d --remove-orphans

network: ## Create Docker network
	$(DOCKER) network create $(NETWORK_NAME) | true

clear-containers: ## Remove containers
	$(DOCKER) stop `$(CONTAINERS)`
	$(DOCKER) rm `$(CONTAINERS)` --force
	$(DOCKER_COMPOSE) rm `$(CONTAINERS)` --force

update-images:
	$(DOCKER_COMPOSE) down --rmi all
	$(DOCKER_COMPOSE) up -d --remove-orphans

up-docker-chmod:
	sudo chmod a+rwx /var/run/docker.sock
	sudo chmod a+rwx /var/run/docker.pid

docker-login:
	aws --profile dev --region eu-west-3 ecr get-login-password | \
	  docker login --username AWS --password-stdin \
	  944708720531.dkr.ecr.eu-west-3.amazonaws.com


##
## Project setup
##---------------------------------------------------------------------------
composer-install: up ## Install php dependencies
	$(foreach project,$(projects),$(RUN) bash -c "echo '==> $(project)' && composer install -n --working-dir=endpoints/$(project)";) \

composer-update: up ## Install php dependencies
	$(foreach project,$(projects),$(RUN) bash -c "echo '==> $(project)' && composer update -n --working-dir=endpoints/$(project)";) \

composer-install-prod: up ## Install php dependencies
	$(foreach project,$(projects),$(RUN) bash -c "echo '==> $(project)' && composer install -n --no-dev --optimize-autoloader --working-dir=endpoints/$(project)";) \

##
## Project tools
##---------------------------------------------------------------------------

logs: ## Show PHP logs
	$(DOCKER_COMPOSE) logs -f php

php-console: up ## Start php console
	$(DOCKER_COMPOSE) run --rm php sh

pint-fix: up ## Run pint formatter
	$(foreach project,$(projects),$(RUN) bash -c "echo '##### $(project) #####' && cd endpoints/$(project) && php vendor/bin/pint --parallel";) \

pint-check: up ## Run pint tests
	$(foreach project,$(projects),$(RUN) bash -c "echo '##### $(project) #####' && cd endpoints/$(project) && php vendor/bin/pint --test";) \

test-coverage: up ## Run tests with coverage check (must be 100%)
	$(foreach project,$(projects),$(RUN) bash -c "echo '##### $(project) #####' && cd endpoints/$(project) && php vendor/bin/phpunit --coverage-text";) \

analyze: up ## Run phpstan analysis
	$(foreach project,$(projects),$(RUN) bash -c "echo '##### $(project) #####' && cd endpoints/$(project) && php vendor/bin/phpstan analyse app tests";) \

##
## Deployment
##---------------------------------------------------------------------------

TF_CMD=$(DOCKER) run --rm \
	-v $(shell pwd):/workspace \
	-v $(HOME)/.aws/config:/root/.aws/config:ro \
	-v $(HOME)/.aws/credentials:/root/.aws/credentials:ro \
	-e AWS_PROFILE=$(profile) \
	-w /workspace \
	944708720531.dkr.ecr.eu-west-3.amazonaws.com/terraform:latest \
	terraform -chdir=config/web

tf-init: ## Run terraform init (use profile=xxx)
	$(TF_CMD) init -reconfigure

tf-fix: ## Run terraform fmt
	$(TF_CMD) fmt -recursive

tf-plan: ## Run terraform plan (use env=dev/sbx/prod profile=xxx)
	$(TF_CMD) plan -var-file=environments/$(env).tfvars

tf-apply: ## Run terraform apply (use env=dev/sbx/prod profile=xxx)
	$(TF_CMD) apply -auto-approve -var-file=environments/$(env).tfvars

tf-destroy: ## Run terraform destroy (use env=dev/sbx/prod profile=xxx)
	$(TF_CMD) destroy -var-file=environments/$(env).tfvars