<div align="center">
  <br />
  <h3 align="center">terraform-template</h3>

  <p align="center">
    Preferred layout and tooling for terraform projects
    <br />
  </p>
</div>

<details open>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li>
      <a href="#usage">Usage</a>
      <ul>
        <li><a href="#formatting">Formatting</a></li>
        <li><a href="#validating">Validating</a></li>
        <li><a href="#planning">Planning</a></li>
        <li><a href="#applying">Applying</a></li>
      </ul>
    </li>
  </ol>
</details>

## About the project

This repo intends to be a boilerplate to speed up the development of new terraform projects. 

Features:
- Static analysis tooling ([tfsec](https://aquasecurity.github.io/tfsec/v1.21.0/), [infracost](https://www.infracost.io/))
- Continuous integration / deployment pipelines ([GitHub Actions](https://github.com/features/actions))

It contains tooling such as static analysis tools and continuous integrations pipelines 

## Getting Started

### Prerequisites

Ensure all of the following pre-requisites are installed.

- [docker](https://docs.docker.com/desktop/mac/install/)
- [Make](https://www.gnu.org/software/make/)
- [pre-commit](https://pre-commit.com/#install)

### Installation

Pre-commit hooks are used to validate the changes to the repo and help to maintain good standards. Usage of the pre-commit hooks provides faster feedback to the developer by checking the changes on every commit.

```shell
pre-commit install
```

Sometimes, it will be necessary to skip some of the pre-commit checks:

```shell
SKIP=terraform_fmt,terraform_validate git commit -m "<msg>"
```

or all of the checks:

```shell
git commit -m "<msg>" --no-verify
```

## Usage

The Makefile contains a number of useful commands to make the development of terraform configurations easier. Each terraform command is run using the official terraform docker image. This is to remove the need to install terraform locally and also reduces the need to manage multiple versions of terraform.

### Formatting

To format the terraform configuration (and environments):

```shell
make fmt
```

### Validating

The validate the terraform configuration:

```shell
make validate
```

### Planning

To create a plan of the changes to the infrastructure locally, first initialise the providers and modules:

```shell
make init-local
```

Now create the plan:

```shell
make plan-local
```

> N.B. This will create a plan for the default environment specified in the Makefile. To create a plan for other environments, override the `ENVIRONMENT` variable.

```shell
ENVIRONMENT=<env> make init-local
```

```shell
ENVIRONMENT=<env> make plan-local
```

> N.B. If the other environment is within a different AWS account, override the `AWS_PROFILE` in addition to the `ENVIRONMENT` variable.

```shell
AWS_PROFILE=<profile> ENVIRONMENT=<env> make init-local
```

```shell
AWS_PROFILE=<profile> ENVIRONMENT=<env> make plan-local
```

### Applying

It is generally advisable to not apply changes to the infrastructure from a local machine. However, if it is necessary, run:

```shell
make apply-local
```

> N.B. The same `AWS_PROFILE` must be used for both the plan and apply commands.

```shell
AWS_PROFILE=<profile> make plan-local
```

## Layout

### Terraform

The terraform configuration is stored in the `/terraform` directory to avoid polluting the root directory with too many files. 

Make sure to update the `versions.tf` file with information about the required versions of each provider. This is to ensure repeatability of the IaC and to ensure that no unexpected behaviour is introduced with new versions of the providers.

### Environments

Environments are defined in the `environments/` directory. Each environment consists of a `backend.tfvars` file which provides terraform with the details of the remote backend. 

Deployment to each environment is controlled using the `AWS_PROFILE` environment variable. In CI pipelines, deployment to each environment is controlled using the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.
