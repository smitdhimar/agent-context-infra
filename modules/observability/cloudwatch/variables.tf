# global configurations =======================================================================
variable "globalConfigs" {
  type = object({
    region           = string
    environment      = string
    appName          = string
    policiesLocation = string
  })
}

variable "cloudwatchCommonConfigs" {
  type = object({
    retention_in_days = number
  })
}

variable "all_lambda_names" {
  type        = list(string)
  description = "The list of lambda (short names) whose cloudwatch log groups should be created."
}
