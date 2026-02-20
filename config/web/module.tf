module "hello-world" {
  source = "./endpoints/hello-world"

  lambda_config = local.lambda_config
  api_name            = local.api_name
  env                 = var.env
  dynamodb_table_name = aws_dynamodb_table.api.name
  domain_name         = aws_apigatewayv2_domain_name.api.domain_name
}
