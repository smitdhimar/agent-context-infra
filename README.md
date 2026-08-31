# agent-context-infra

Terraform infrastructure for **agent-context** over AWS.

This repository follows the same module-based, environment-driven structure as
[`zombie-cleaner/zombie-cleaner-infra`](https://github.com/zombie-cleaner/zombie-cleaner-infra).
All resources are created **dynamically** from declarative maps/lists (via `for_each`), so adding
a bucket, lambda, or API route is a config-only change.

## Structure

```
.
├── Makefile
├── environments/
│   ├── dev/                     # active environment
│   │   ├── main.tf              # provider + backend + module wiring
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── prod/                    # placeholder, mirrors dev when promoted
└── modules/
    ├── apiGateway/              # REST API, routes/methods/integrations (dynamic)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── compute/
    │   └── lambda/              # lambda functions + layers (dynamic)
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── outputs.tf
    │       ├── functions/
    │       │   ├── admin_api/         # GET /health, GET /context, GET /context/{id}
    │       │   └── process_context/   # POST /context
    │       └── layers/
    │           └── api-helper/nodejs/ # shared helpers + logger
    ├── observability/
    │   └── cloudwatch/          # lambda log groups (dynamic)
    └── storage/
        └── s3/                  # S3 buckets (dynamic via for_each)
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
```

## What gets created

| Category     | Resource                                              | How it's made dynamic |
| ------------ | ----------------------------------------------------- | --------------------- |
| S3           | `web-assets`, `context-data`, `policies` buckets      | `for_each` over `s3Buckets` map |
| Lambda       | `admin_api`, `process_context` (+ `api-helper` layer) | `for_each` over `locals.lambda_functions` |
| API Gateway  | REST API, resources, methods, integrations, stage     | `for_each` over `apiConfig.routes` |
| CloudWatch   | one log group per lambda                              | `for_each` over lambda names |

Naming convention follows the reference repo: `<name>-<environment>-<appName>`
(e.g. `admin_api-dev-agent-context`, `agent-context-context-data-dev-agent-context`).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- AWS credentials configured (`aws configure` / environment / role)

## Getting started

```bash
# 1. (one-time) create the state bucket, or point the backend at an existing one
aws s3api create-bucket --bucket agent-context-tfstate --region us-east-1

# 2. configure the environment
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
# edit values as needed

# 3. deploy
make agent-context-dev-init
make agent-context-dev-plan
make agent-context-dev-apply
```

## Adding resources

- **S3 bucket**: add an entry to `s3Buckets` in `terraform.tfvars`.
- **Lambda function**: create a folder under
  `modules/compute/lambda/functions/<name>/` and add an entry to
  `locals.lambda_functions` in `modules/compute/lambda/main.tf`.
- **API route**: add an entry to `apiConfig.routes` in `terraform.tfvars`.
  Nested paths (e.g. `context/{id}`) are handled automatically.

## Notes

- `*.tfvars` files are git-ignored; commit only `terraform.tfvars.example`.
- Generated lambda `.zip` archives are git-ignored and rebuilt by Terraform.
- Backend state bucket is hardcoded in `environments/dev/main.tf` (mirrors the
  reference repo); override with `terraform init -backend-config` if needed.
