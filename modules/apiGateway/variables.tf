# global configurations =======================================================================
variable "globalConfigs" {
  type = object({
    region           = string
    environment      = string
    appName          = string
    policiesLocation = string
  })
}

# lambda functions (short name -> ARN) to wire into the API ======================================
variable "lambda_arns" {
  description = "Map of lambda short name -> lambda ARN"
  type        = map(string)
}

# API configuration (routes are created dynamically via for_each) =================================
variable "apiConfig" {
  description = "API Gateway configuration"
  type = object({
    name = string
    routes = list(object({
      path             = string
      http_method      = string
      lambda           = string
      api_key_required = optional(bool, false)
    }))
  })
}
