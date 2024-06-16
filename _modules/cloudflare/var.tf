variable "domain" {
  type = string
}

variable "cloudfront_domain_name" {
  type = string
}

variable "validation_records" {
  type = map(object({
    resource_record_name  = string
    resource_record_value = string
    resource_record_type  = string
  }))
}

locals {
  naked = var.domain
  full  = "www.${local.naked}"
}