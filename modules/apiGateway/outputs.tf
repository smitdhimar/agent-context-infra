output "api_id" {
  description = "API Gateway REST API id"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_name" {
  description = "API Gateway REST API name"
  value       = aws_api_gateway_rest_api.main.name
}

output "stage_name" {
  description = "Deployed API Gateway stage name"
  value       = aws_api_gateway_stage.main.stage_name
}

output "invoke_url" {
  description = "Public invoke URL for the deployed stage"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "execution_arn" {
  description = "Execution ARN of the REST API"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "api_key_id" {
  description = "API key id for the admin panel"
  value       = aws_api_gateway_api_key.main.id
}

output "api_key_value" {
  description = "API key value (sensitive) for the admin panel"
  value       = aws_api_gateway_api_key.main.value
  sensitive   = true
}

output "usage_plan_id" {
  description = "Usage plan id"
  value       = aws_api_gateway_usage_plan.main.id
}

output "routes" {
  description = "The configured routes"
  value       = local.api_routes
}
