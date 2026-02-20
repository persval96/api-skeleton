locals {
  full_domain = "${local.prefix_domain[var.env]}.${local.base_domain[var.env]}"

  api_name = "api-skeleton"

  prefix_domain = {
    dev  = "api-skeleton"
    sbx  = "api-skeleton"
    prod = "api"
  }

  lambda_config = {
    layer_arn     = "arn:aws:lambda:eu-west-3:873528684822:layer:arm-php-85:12"
    architecture  = "arm64"
    handler       = "Bref\\LaravelBridge\\Http\\OctaneHandler"
    bref_loop_max = "250"
    memory_size = 1024
  }

  base_domain = {
    dev  = "dev.appkweb.com"
    sbx  = "sandbox.appkweb.com"
    prod = "client-domain.com"
  }
}