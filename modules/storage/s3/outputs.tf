output "bucket_names" {
  description = "Map of bucket key -> full bucket name"
  value       = { for k, b in aws_s3_bucket.buckets : k => b.bucket }
}

output "bucket_ids" {
  description = "Map of bucket key -> bucket id"
  value       = { for k, b in aws_s3_bucket.buckets : k => b.id }
}

output "bucket_arns" {
  description = "List of all bucket ARNs"
  value       = [for b in aws_s3_bucket.buckets : b.arn]
}

output "bucket_arns_map" {
  description = "Map of bucket key -> bucket ARN"
  value       = { for k, b in aws_s3_bucket.buckets : k => b.arn }
}
