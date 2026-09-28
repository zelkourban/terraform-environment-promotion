ENV ?= dev
DIR := envs/$(ENV)

VALID_ENVS := dev staging prod

.PHONY: check-env init fmt validate lint plan apply output destroy orphans clean

check-env:
	@echo "$(VALID_ENVS)" | grep -qw "$(ENV)" \
		|| { echo "ENV must be one of: $(VALID_ENVS)"; exit 1; }

init: check-env
	terraform -chdir=$(DIR) init -input=false

fmt:
	terraform fmt -recursive

validate: check-env
	terraform -chdir=$(DIR) validate

lint:
	tflint --recursive
	tfsec .

plan: check-env
	terraform -chdir=$(DIR) plan -input=false

# Local apply is for dev only. staging and prod go through the pipeline so the
# change is reviewed, approved and recorded.
apply: check-env
	@[ "$(ENV)" = "dev" ] || { \
		echo "Refusing to apply $(ENV) locally - use the deploy workflow."; exit 1; }
	terraform -chdir=$(DIR) apply -input=false

output: check-env
	terraform -chdir=$(DIR) output

# Same rule as apply: prod teardown is deliberate, manual and not from here.
destroy: check-env
	@[ "$(ENV)" = "prod" ] && { \
		echo "Refusing to destroy prod. See envs/prod/README.md."; exit 1; } || true
	terraform -chdir=$(DIR) destroy -input=false

# Anything still carrying the project tag after a destroy is an orphan,
# usually left by a cancelled apply.
orphans:
	aws resourcegroupstaggingapi get-resources \
		--tag-filters Key=Project,Values=acme \
		--query 'ResourceTagMappingList[].ResourceARN' --output table

clean:
	find . -type d -name .terraform -prune -exec rm -rf {} +
	find . -type f -name tfplan -delete
