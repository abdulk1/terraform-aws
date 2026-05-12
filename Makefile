ENV ?= dev
TF_DIR := environments/$(ENV)

.PHONY: fmt init validate plan apply destroy output

fmt:
	terraform fmt -recursive

init:
	terraform -chdir=$(TF_DIR) init

validate:
	terraform -chdir=$(TF_DIR) validate

plan:
	terraform -chdir=$(TF_DIR) plan -out=tfplan

apply:
	terraform -chdir=$(TF_DIR) apply tfplan

destroy:
	terraform -chdir=$(TF_DIR) destroy

output:
	terraform -chdir=$(TF_DIR) output
