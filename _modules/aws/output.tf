output "validations_map" {
  value = {for x in aws_acm_certificate.cert.domain_validation_options: x.resource_record_name => x}
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}