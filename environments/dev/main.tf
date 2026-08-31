# global configurations =======================================================================
provider "aws" {
  region = var.globalConfigs.region
}

# remote backend configuration ==================================================================
terraform {
  backend "s3" {
    bucket       = "agent-context-tfstate"
    key          = "env/dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

# storage : s3 buckets (created dynamically) =====================================================
module "s3_buckets" {
  source = "../../modules/storage/s3"

  # globals
  globalConfigs = var.globalConfigs

  # buckets
  s3Buckets = var.s3Buckets
}

# compute : lambda functions (created dynamically) ================================================
module "lambda" {
  source = "../../modules/compute/lambda"

  # globals
  globalConfigs = var.globalConfigs

  # s3 buckets the lambdas can read/write
  s3BucketNames = module.s3_buckets.bucket_names
  s3BucketArns  = module.s3_buckets.bucket_arns
}

# api gateway (routes created dynamically) =======================================================
module "api_gateway" {
  source = "../../modules/apiGateway"

  # globals
  globalConfigs = var.globalConfigs

  # lambda functions to wire into the API
  lambda_arns = module.lambda.lambda_arns

  # api configuration
  apiConfig = var.apiConfig
}

# observability : cloudwatch (log groups created dynamically) =====================================
module "cloudwatch" {
  source = "../../modules/observability/cloudwatch"

  # globals
  globalConfigs = var.globalConfigs

  # cloudwatch common configs
  cloudwatchCommonConfigs = var.cloudwatchCommonConfigs

  # lambda names
  all_lambda_names = module.lambda.all_lambda_names
}
