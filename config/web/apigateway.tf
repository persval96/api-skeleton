resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = local.full_domain

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.api.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}