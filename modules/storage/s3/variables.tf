# global configurations =======================================================================
variable "globalConfigs" {
  type = object({
    region           = string
    environment      = string
    appName          = string
    policiesLocation = string
  })
}

# S3 buckets (created dynamically via for_each) =================================================
variable "s3Buckets" {
  description = "Map of S3 buckets to create. The map key becomes the bucket name prefix: <key>-<environment>-<appName>."
  type = map(object({
    force_destroy       = optional(bool, true)
    versioning_enabled  = optional(bool, false)
    block_public_access = optional(bool, true)
    public_read         = optional(bool, false)
    tags                = optional(map(string), {})
  }))
  default = {}
}
