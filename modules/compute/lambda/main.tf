# Lambda functions & layers are defined declaratively here and created dynamically with for_each.
# To add a new function, drop a folder under functions/ and add an entry to local.lambda_functions.
locals {
  lambda_functions = [
    {
      name        = "admin_api"
      description = "Admin panel API handler for agent-context"
      handler     = "index.handler"
      runtime     = "nodejs18.x"
      code_path   = "${path.module}/functions/admin_api"
      layers      = ["api-helper"]
      environment_variables = {
        "REGION"         = var.globalConfigs.region
        "APP_NAME"       = var.globalConfigs.appName
        "ENVIRONMENT"    = var.globalConfigs.environment
        "CONTEXT_BUCKET" = lookup(var.s3BucketNames, "agent-context-context-data", "")
      }
      enable_cloudwatch_logs = true
    },
    {
      name        = "process_context"
      description = "Ingests and stores agent context data"
      handler     = "index.handler"
      runtime     = "nodejs18.x"
      code_path   = "${path.module}/functions/process_context"
      layers      = ["api-helper"]
      environment_variables = {
        "REGION"         = var.globalConfigs.region
        "APP_NAME"       = var.globalConfigs.appName
        "ENVIRONMENT"    = var.globalConfigs.environment
        "CONTEXT_BUCKET" = lookup(var.s3BucketNames, "agent-context-context-data", "")
      }
      enable_cloudwatch_logs = true
    }
  ]

  lambda_layers = [
    {
      name      = "api-helper"
      code_path = "${path.module}/layers/api-helper"
    }
  ]
}

# Zip each lambda function source directory =====================================================
data "archive_file" "lambda_zips" {
  for_each = { for lambda in local.lambda_functions : lambda.name => lambda }

  type        = "zip"
  source_dir  = each.value.code_path
  output_path = "${path.module}/functions/${each.value.name}.zip"
  excludes    = ["**/*.zip"]
}

# Zip each lambda layer source directory ========================================================
data "archive_file" "lambda_layer_zips" {
  for_each = { for layer in local.lambda_layers : layer.name => layer }

  type        = "zip"
  source_dir  = each.value.code_path
  output_path = "${path.module}/layers/${each.value.name}.zip"
  excludes    = ["**/*.zip"]
}

# Lambda layers =================================================================================
resource "aws_lambda_layer_version" "lambdaLayers" {
  for_each = { for layer in local.lambda_layers : layer.name => layer }

  filename            = "${path.module}/layers/${each.value.name}.zip"
  layer_name          = "${each.value.name}-${var.globalConfigs.environment}-${var.globalConfigs.appName}"
  source_code_hash    = data.archive_file.lambda_layer_zips[each.key].output_base64sha256
  compatible_runtimes = ["nodejs18.x"]
}

# Lambda functions (created dynamically) ========================================================
resource "aws_lambda_function" "lambdaFunctions" {
  for_each = { for lambda in local.lambda_functions : lambda.name => lambda }

  function_name    = "${each.value.name}-${var.globalConfigs.environment}-${var.globalConfigs.appName}"
  description      = each.value.description
  handler          = each.value.handler
  runtime          = each.value.runtime
  filename         = "${path.module}/functions/${each.value.name}.zip"
  source_code_hash = data.archive_file.lambda_zips[each.key].output_base64sha256
  role             = aws_iam_role.lambda_execution_role.arn
  layers           = [for layer in each.value.layers : aws_lambda_layer_version.lambdaLayers[layer].arn]

  environment {
    variables = each.value.environment_variables
  }

  tags = {
    Name        = "${each.value.name}-${var.globalConfigs.environment}-${var.globalConfigs.appName}"
    Environment = var.globalConfigs.environment
    App         = var.globalConfigs.appName
  }
}

# IAM role shared by all lambda functions ========================================================
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role-${var.globalConfigs.environment}-${var.globalConfigs.appName}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.globalConfigs.environment
    App         = var.globalConfigs.appName
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Optional S3 read/write access for the lambda role ==============================================
resource "aws_iam_policy" "lambda_s3_access" {
  count = length(var.s3BucketArns) > 0 ? 1 : 0

  name        = "lambda-s3-access-${var.globalConfigs.environment}-${var.globalConfigs.appName}"
  description = "Allow lambda to read/write the agent-context S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = concat(var.s3BucketArns, [for arn in var.s3BucketArns : "${arn}/*"])
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_access_attach" {
  count = length(var.s3BucketArns) > 0 ? 1 : 0

  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_s3_access[0].arn
}
