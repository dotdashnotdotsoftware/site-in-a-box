# site-in-a-box
Terraform module that supports hosting of a basic static site using cloud services:
- S3 - hosts files
- Cloudfront - Provides Internet to S3 connectivity
- Cloudflare - Provides DNS records & other default features (such as bot prevention)

## Prerequisites
- You own a domain name
- This domain name has been configured in Cloudflare
    - The nameservers of your registrar have been configured to use Cloudflare's
    - The domain is saved with no DNS records inside
    - The domain is configured to use Full (Strict) SSL/TLS connectivity between the Cloudfront proxy service & the downstream (will be Cloudfront)
- You have an AWS cloud account

## Usage

Reference this module in your terraform like so:
```
module "main" {
  source = "git@github.com:dotdashnotdotsoftware/site-in-a-box.git"

  environment = "prod"
  domain      = "example.com"
  src_dir     = "${path.root}/../../src/"
}
```
And first run this command:
```
terraform plan/apply -target <prefix_path>.site-in-a-box.module.aws_infra
# Example
terraform plan/apply -target module.site-in-a-box.module.aws_infra
```
to set up everything in AWS. At this point, you should have created:
- A new S3 bucket
- All of your files in S3
- A cloudfront distribution in front
- SSL certificates ready for cloudflare
and the ability to directly access the site via the cloudfront link. Finally, run a full apply to finish configuring Cloudflare:
```
terraform apply
```
Once this is done, your domain should now work on http/https on both www.<your-domain> and simply <your-domain>.

## Per-file overrides

For every file in the provided src_dir, if there is a matching file ending with ".tfmeta", it will allow you to override the S3 upload behaviours for that file. E.g. for index.html, if there is an index.html.tfmeta file with JSON contents such as:
```json
{
    "content_type": "text/css",
    "cache_control": "max-age=31536000"
}
```
It will let you override the default of `text/html` & tell S3 to return cache control headers for this uploaded file.