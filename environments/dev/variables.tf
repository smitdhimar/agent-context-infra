# global configurations =======================================================================
variable "globalConfigs" {
  type = object({
    region           = string
    environment      = string
    appName          = string
    policiesLocation = string
  })
}

# storage related services =======================================================================

# S3 buckets (created dynamically)
variable "s3Buckets" {
  description = "Map of S3 buckets to create. The map key becomes the bucket name prefix."
  type = map(object({
    force_destroy       = optional(bool, true)
    versioning_enabled  = optional(bool, false)
    block_public_access = optional(bool, true)
    public_read         = optional(bool, false)
    tags                = optional(map(string), {})
  }))
  default = {}
}

# api gateway ====================================================================================
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

# observability ==================================================================================

# cloudwatch
variable "cloudwatchCommonConfigs" {
  type = object({
    retention_in_days = number
  })
}
