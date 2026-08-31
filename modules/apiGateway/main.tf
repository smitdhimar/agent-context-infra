# Compute every unique path fragment (including intermediate parents) so nested routes like
# "context/{id}" also get their parent resource ("context") created.
locals {
  api_routes = var.apiConfig.routes

  all_path_fragments = distinct(flatten([
    for route in local.api_routes : [
      for i in range(1, length(split("/", trim(route.path, "/"))) + 1) :
      join("/", slice(split("/", trim(route.path, "/")), 0, i))
    ]
  ]))

  parent_path = {
    for p in local.all_path_fragments : p => (
      length(split("/", p)) == 1 ? null : join("/", slice(split("/", p), 0, length(split("/", p)) - 1))
    )
  }
}

# REST API ======================================================================================
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.globalConfigs.appName}-${var.globalConfigs.environment}-${var.apiConfig.name}"
  description = "REST API for ${var.globalConfigs.appName} (${var.globalConfigs.environment})"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Environment = var.globalConfigs.environment
    App         = var.globalConfigs.appName
  }
}

# Resources created dynamically for every path fragment ==========================================
resource "aws_api_gateway_resource" "paths" {
  for_each = toset(local.all_path_fragments)

  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = local.parent_path[each.value] == null ? aws_api_gateway_rest_api.main.root_resource_id : aws_api_gateway_resource.paths[local.parent_path[each.value]].id
  path_part   = element(split("/", each.value), length(split("/", each.value)) - 1)
}

# Methods created dynamically per route ==========================================================
resource "aws_api_gateway_method" "routes" {
  for_each = { for r in local.api_routes : "${r.http_method}-${r.path}" => r }

  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.paths[each.value.path].id
  http_method      = each.value.http_method
  authorization    = "NONE"
  api_key_required = try(each.value.api_key_required, false)
}

# Lambda integrations created dynamically per route ==============================================
resource "aws_api_gateway_integration" "routes" {
  for_each = { for r in local.api_routes : "${r.http_method}-${r.path}" => r }

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.paths[each.value.path].id
  http_method             = each.value.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_arns[each.value.lambda]
}

# Allow API Gateway to invoke each backing lambda ================================================
resource "aws_lambda_permission" "apigw" {
  for_each = toset(distinct([for r in local.api_routes : r.lambda]))

  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arns[each.value]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# Deployment + stage ==============================================================================
resource "aws_api_gateway_deployment" "main" {
  depends_on = [aws_api_gateway_integration.routes]

  rest_api_id = aws_api_gateway_rest_api.main.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  stage_name    = var.globalConfigs.environment
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id

  tags = {
    Environment = var.globalConfigs.environment
    App         = var.globalConfigs.appName
  }
}

# Usage plan + API key for the admin panel =======================================================
resource "aws_api_gateway_usage_plan" "main" {
  name = "${var.globalConfigs.appName}-${var.globalConfigs.environment}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }

  quota_settings {
    limit  = 10000
    period = "MONTH"
  }
}

resource "aws_api_gateway_api_key" "main" {
  name = "${var.globalConfigs.appName}-${var.globalConfigs.environment}-api-key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}
