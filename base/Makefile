SHELL := /usr/bin/env bash

.PHONY: clean
clean:
	rm -rf .terraform

.PHONY: plan
plan: 
	terraform init && terraform validate && terraform plan --var-file=cluster.tfvars

.PHONY: apply
apply:
	terraform apply --var-file=cluster.tfvars

.PHONY: destroy
destroy: plan
	terraform destroy --var-file=cluster.tfvars
