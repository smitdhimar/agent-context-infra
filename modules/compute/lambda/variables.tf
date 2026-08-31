# global configurations =======================================================================
variable "globalConfigs" {
  type = object({
    region           = string
    environment      = string
    appName          = string
    policiesLocation = string
  })
}

# bucket names produced by the s3 module (key -> full bucket name) ===============================
variable "s3BucketNames" {
  description = "Map of bucket key -> full bucket name created by the S3 module"
  type        = map(string)
  default     = {}
}

# bucket ARNs to grant the lambda execution role access to ========================================
variable "s3BucketArns" {
  description = "List of S3 bucket ARNs the lambda role may read/write"
  type        = list(string)
  default     = []
}
