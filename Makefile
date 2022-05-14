AWS_PROFILE 			?= example
AWS_DEFAULT_REGION		?= eu-west-1
TERRAFORM_VERSION		?= 1.1.7
TFSEC_VERSION			?= v1.13.2-amd64
INFRACOST_VERSION		?= ci-0.9
ENVIRONMENT 			?= dev

export

clean:
	rm -rf ./terraform/.terraform
	rm -rf ./terraform/plan.tfplan
	rm -rf ./terraform/plan.json

fmt:
	docker run --platform=linux/amd64 \
		-v ${PWD}:/src \
		-w /src \
		hashicorp/terraform:${TERRAFORM_VERSION} fmt -recursive

sec-scan:
	docker run --platform=linux/amd64 \
		-v ${PWD}:/src \
		tfsec/tfsec:${TFSEC_VERSION} /src/terraform

infracost: show-plan
	docker run -it --platform=linux/amd64 \
		-v ${PWD}:/src \
		-v ${HOME}/.config/infracost:/root/.config/infracost \
		infracost/infracost:${INFRACOST_VERSION} breakdown \
		--path=/src/terraform/plan.json

init-local: clean
	docker run --platform=linux/amd64 \
		-v ${PWD}:/src \
		-v ${HOME}/.aws:/root/.aws/ \
		-v ${HOME}/.ssh:/root/.ssh/ \
		-w /src/terraform \
		-e AWS_PROFILE=${AWS_PROFILE} \
		hashicorp/terraform:${TERRAFORM_VERSION} init \
		-backend-config=../environments/${ENVIRONMENT}/backend.tfvars

init-no-backend:
	docker run --platform=linux/amd64 \
		-v ${PWD}:/src \
		-w /src/terraform \
		hashicorp/terraform:${TERRAFORM_VERSION} init \
		-backend=false

validate: clean init-no-backend
	docker run --platform=linux/amd64 \
		-v ${PWD}:/src \
		-w /src/terraform \
		hashicorp/terraform:${TERRAFORM_VERSION} validate

plan-local:
	docker run --platform=linux/amd64 \
		-v ${PWD}:/src \
		-v ${HOME}/.aws:/root/.aws/ \
		-v ${HOME}/.ssh:/root/.ssh/ \
		-w /src/terraform \
		-e AWS_PROFILE=${AWS_PROFILE} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		hashicorp/terraform:${TERRAFORM_VERSION} plan \
		-var-file=../environments/${ENVIRONMENT}/terraform.tfvars \
		-out=plan.tfplan

apply-local:
	docker run --platform=linux/amd64 \
		-v ${PWD}:/src \
		-v ${HOME}/.aws:/root/.aws/ \
		-v ${HOME}/.ssh:/root/.ssh/ \
		-w /src/terraform \
		-e AWS_PROFILE=${AWS_PROFILE} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		hashicorp/terraform:${TERRAFORM_VERSION} apply plan.tfplan

show-plan:
	docker run --platform=linux/amd64 \
		-v ${PWD}:/src \
		-v ${HOME}/.aws:/root/.aws/ \
		-w /src/terraform \
		-e AWS_PROFILE=${AWS_PROFILE} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		hashicorp/terraform:${TERRAFORM_VERSION} show -json plan.tfplan > terraform/plan.json

destroy-local:
	docker run -it --platform=linux/amd64 \
		-v ${PWD}:/src \
		-v ${HOME}/.aws:/root/.aws/ \
		-v ${HOME}/.ssh:/root/.ssh/ \
		-w /src/terraform \
		-e AWS_PROFILE=${AWS_PROFILE} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		hashicorp/terraform:${TERRAFORM_VERSION} destroy \
		-var-file=../environments/${ENVIRONMENT}/terraform.tfvars
