variable "domain" {
  type = string
}

variable "src_dir" {
  type = string
}

locals {
  naked = var.domain
  full  = "www.${local.naked}"
}