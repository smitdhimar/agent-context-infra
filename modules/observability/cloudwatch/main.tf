# CloudWatch log groups created dynamically, one per lambda ======================================
resource "aws_cloudwatch_log_group" "lambda_cloudwatch_logs" {
  for_each          = toset(var.all_lambda_names)
  name              = "/aws/lambda/${each.value}-${var.globalConfigs.environment}-${var.globalConfigs.appName}"
  retention_in_days = var.cloudwatchCommonConfigs.retention_in_days

  tags = {
    Environment = var.globalConfigs.environment
    App         = var.globalConfigs.appName
  }
}
