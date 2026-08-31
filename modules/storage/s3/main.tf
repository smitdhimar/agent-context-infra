# S3 buckets (created dynamically) ==============================================================
resource "aws_s3_bucket" "buckets" {
  for_each = var.s3Buckets

  bucket        = "${each.key}-${var.globalConfigs.environment}-${var.globalConfigs.appName}"
  force_destroy = try(each.value.force_destroy, true)

  tags = merge({
    Name        = "${each.key}-${var.globalConfigs.environment}-${var.globalConfigs.appName}"
    Environment = var.globalConfigs.environment
    App         = var.globalConfigs.appName
  }, try(each.value.tags, {}))
}

# Optional versioning (only created when enabled) ==============================================
resource "aws_s3_bucket_versioning" "buckets" {
  for_each = { for k, v in var.s3Buckets : k => v if try(v.versioning_enabled, false) }

  bucket = aws_s3_bucket.buckets[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Public access block (defaults to blocking all public access) ==================================
resource "aws_s3_bucket_public_access_block" "buckets" {
  for_each = var.s3Buckets

  bucket = aws_s3_bucket.buckets[each.key].id

  block_public_acls       = try(each.value.block_public_access, true)
  block_public_policy     = try(each.value.block_public_access, true)
  restrict_public_buckets = try(each.value.block_public_access, true)
  ignore_public_acls      = try(each.value.block_public_access, true)
}

# Optional public read policy (e.g. for static assets / policy documents) =======================
resource "aws_s3_bucket_policy" "public_read" {
  for_each = { for k, v in var.s3Buckets : k => v if try(v.public_read, false) }

  bucket = aws_s3_bucket.buckets[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.buckets[each.key].arn}/*"
    }]
  })
}
