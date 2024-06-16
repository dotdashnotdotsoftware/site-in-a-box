module "aws_infra" {
  source = "./_modules/aws"

  domain  = var.domain
  src_dir = var.src_dir
}

module "cloudflare_infra" {
  source = "./_modules/cloudflare"

  domain = var.domain
  cloudfront_domain_name = module.aws_infra.cloudfront_domain_name
  validation_records = module.aws_infra.validations_map
}
