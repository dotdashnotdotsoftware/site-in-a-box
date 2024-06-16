terraform {
  required_version = ">= 1.5.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

data "cloudflare_zone" "zone_info" {
  name = local.naked
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.zone_info.id
  name    = "www"
  value   = var.cloudfront_domain_name
  type    = "CNAME"
  proxied = true
}


resource "cloudflare_record" "naked" {
  zone_id = data.cloudflare_zone.zone_info.id
  name    = local.naked
  value   = var.cloudfront_domain_name
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cert_records" {
  for_each = var.validation_records

  zone_id = data.cloudflare_zone.zone_info.id
  name    = each.value.resource_record_name
  value   = each.value.resource_record_value
  type    = each.value.resource_record_type
  proxied = false
}
