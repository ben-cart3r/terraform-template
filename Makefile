AWS_PROFILE 			?= example
AWS_DEFAULT_REGION		?= eu-west-1
TERRAFORM_VERSION		?= 1.1.7
TERRAFORM_LOG_LEVEL		?= ERROR
TFSEC_VERSION			?= v1.13.2-amd64
INFRACOST_VERSION		?= ci-0.9
ENVIRONMENT 			?= dev
CUR_DIR					:= $(shell pwd)# ${PWD} is incosistent in GitHub Actions

export

clean:
	rm -rf terraform/.terraform
	rm -rf terraform/plan.tfplan
	rm -rf terraform/plan.json

fmt:
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-w /src \
		hashicorp/terraform:${TERRAFORM_VERSION} fmt -recursive

sec-scan:
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		tfsec/tfsec:${TFSEC_VERSION} /src/terraform

infracost: show-plan
	docker run -it --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-v ${HOME}/.config/infracost:/root/.config/infracost \
		infracost/infracost:${INFRACOST_VERSION} breakdown \
		--path=/src/terraform/plan.json

init-ci: clean
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-v ${HOME}/.gitconfig:/root/.gitconfig \
		-w /src/terraform \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		-e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
		-e TF_LOG=${TERRAFORM_LOG_LEVEL} \
		hashicorp/terraform:${TERRAFORM_VERSION} init \
		-backend-config=../environments/${ENVIRONMENT}/backend.tfvars

init: clean
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-v ${HOME}/.aws:/root/.aws/ \
		-v ${HOME}/.ssh:/root/.ssh/ \
		-w /src/terraform \
		-e AWS_PROFILE=${AWS_PROFILE} \
		hashicorp/terraform:${TERRAFORM_VERSION} init \
		-backend-config=../environments/${ENVIRONMENT}/backend.tfvars

init-no-backend:
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-v ${HOME}/.ssh:/root/.ssh/ \
		-v ${HOME}/.gitconfig:/root/.gitconfig \
		-w /src/terraform \
		hashicorp/terraform:${TERRAFORM_VERSION} init \
		-backend=false

validate: clean init-no-backend
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-w /src/terraform \
		hashicorp/terraform:${TERRAFORM_VERSION} validate

refresh-ci:
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-w /src/terraform \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		-e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		-e TF_LOG=${TERRAFORM_LOG_LEVEL} \
		hashicorp/terraform:${TERRAFORM_VERSION} refresh \
		-var-file=../environments/${ENVIRONMENT}/terraform.tfvars

plan-ci:
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-w /src/terraform \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		-e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		-e TF_LOG=${TERRAFORM_LOG_LEVEL} \
		hashicorp/terraform:${TERRAFORM_VERSION} plan \
		-var-file=../environments/${ENVIRONMENT}/terraform.tfvars \
		-refresh=false \
		-out=plan.tfplan

plan:
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-v ${HOME}/.aws:/root/.aws/ \
		-v ${HOME}/.ssh:/root/.ssh/ \
		-w /src/terraform \
		-e AWS_PROFILE=${AWS_PROFILE} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		hashicorp/terraform:${TERRAFORM_VERSION} plan \
		-var-file=../environments/${ENVIRONMENT}/terraform.tfvars \
		-out=plan.tfplan

apply-ci:
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-w /src/terraform \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		-e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		-e TF_LOG=${TERRAFORM_LOG_LEVEL} \
		hashicorp/terraform:${TERRAFORM_VERSION} apply plan.tfplan

apply:
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-v ${HOME}/.aws:/root/.aws/ \
		-v ${HOME}/.ssh:/root/.ssh/ \
		-w /src/terraform \
		-e AWS_PROFILE=${AWS_PROFILE} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		hashicorp/terraform:${TERRAFORM_VERSION} apply plan.tfplan

show-plan-ci:
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-w /src/terraform \
		-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		-e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		-e TF_LOG=${TERRAFORM_LOG_LEVEL} \
		hashicorp/terraform:${TERRAFORM_VERSION} show -no-color plan.tfplan \
		| sed -E 's/^([[:space:]]+)([-+])/\2\1/g' > plan.txt

show-plan:
	docker run --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-v ${HOME}/.aws:/root/.aws/ \
		-w /src/terraform \
		-e AWS_PROFILE=${AWS_PROFILE} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		hashicorp/terraform:${TERRAFORM_VERSION} show -json plan.tfplan > terraform/plan.json

destroy:
	docker run -it --platform=linux/amd64 \
		-v ${CUR_DIR}:/src \
		-v ${HOME}/.aws:/root/.aws/ \
		-v ${HOME}/.ssh:/root/.ssh/ \
		-w /src/terraform \
		-e AWS_PROFILE=${AWS_PROFILE} \
		-e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
		hashicorp/terraform:${TERRAFORM_VERSION} destroy \
		-var-file=../environments/${ENVIRONMENT}/terraform.tfvars
