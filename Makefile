ENV ?= dev
TF_DIR := environments/$(ENV)

.PHONY: fmt init validate validate-all plan apply destroy output security-scan

fmt:
	terraform fmt -recursive

init:
	terraform -chdir=$(TF_DIR) init

validate:
	terraform -chdir=$(TF_DIR) validate

validate-all:
	terraform -chdir=environments/dev validate
	terraform -chdir=environments/test validate
	terraform -chdir=environments/prod validate

plan:
	terraform -chdir=$(TF_DIR) plan -out=tfplan

apply:
	terraform -chdir=$(TF_DIR) apply tfplan

destroy:
	terraform -chdir=$(TF_DIR) destroy

output:
	terraform -chdir=$(TF_DIR) output

security-scan:
	checkov -d $(TF_DIR) --framework terraform
