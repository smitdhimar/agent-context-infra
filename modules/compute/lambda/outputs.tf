output "lambda_arns" {
  description = "Map of lambda short name -> lambda ARN"
  value       = { for lambda in local.lambda_functions : lambda.name => aws_lambda_function.lambdaFunctions[lambda.name].arn }
}

output "lambda_function_names" {
  description = "Map of lambda short name -> full function name"
  value       = { for lambda in local.lambda_functions : lambda.name => aws_lambda_function.lambdaFunctions[lambda.name].function_name }
}

output "all_lambda_names" {
  description = "Short names of all lambdas that should have cloudwatch log groups"
  value       = [for val in local.lambda_functions : val.name if val.enable_cloudwatch_logs == true]
}
