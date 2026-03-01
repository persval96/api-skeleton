data "aws_acm_certificate" "api" {
  domain = "*.${local.base_domain[var.env]}"
}

data "aws_route53_zone" "api" {
  name         = local.base_domain[var.env]
  private_zone = false
}