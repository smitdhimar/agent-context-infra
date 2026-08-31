# storage ========================================================================================
output "s3_bucket_names" {
  description = "Map of bucket key -> full bucket name"
  value       = module.s3_buckets.bucket_names
}

output "s3_bucket_arns" {
  description = "List of all bucket ARNs"
  value       = module.s3_buckets.bucket_arns
}

# compute ========================================================================================
output "lambda_function_names" {
  description = "Map of lambda short name -> full function name"
  value       = module.lambda.lambda_function_names
}

output "lambda_arns" {
  description = "Map of lambda short name -> lambda ARN"
  value       = module.lambda.lambda_arns
}

# api gateway ====================================================================================
output "api_invoke_url" {
  description = "Public invoke URL for the API Gateway stage"
  value       = module.api_gateway.invoke_url
}

output "api_key_id" {
  description = "API key id for the admin panel"
  value       = module.api_gateway.api_key_id
}

output "api_key_value" {
  description = "API key value for the admin panel (sensitive)"
  value       = module.api_gateway.api_key_value
  sensitive   = true
}

output "api_routes" {
  description = "Configured API Gateway routes"
  value       = module.api_gateway.routes
}
