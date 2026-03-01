resource "aws_apigatewayv2_api" "api" {
  name          = "${var.api_name}-${local.endpoint_name}-${var.env}"
  protocol_type = "HTTP"
  description   = "${var.api_name} apigateway deployed in '${var.env}' environment"
}


resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = var.domain_name
  stage       = aws_apigatewayv2_stage.api.name
}

resource "aws_apigatewayv2_stage" "api" {
  api_id = aws_apigatewayv2_api.api.id
  name   = var.env
  default_route_settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
  }
  auto_deploy = true
}

resource "aws_apigatewayv2_deployment" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  description = "deployment for ${local.endpoint_name} endpoints"

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_route.list),
      jsonencode(aws_apigatewayv2_route.show),
      jsonencode(aws_apigatewayv2_route.create),
      jsonencode(aws_apigatewayv2_route.update),
      jsonencode(aws_apigatewayv2_route.delete),
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "list" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /${local.endpoint_name}"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "create" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /${local.endpoint_name}"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "update" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "PUT /${local.endpoint_name}"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "delete" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "DELETE /${local.endpoint_name}"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "show" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /${local.endpoint_name}/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_route" "cors" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "OPTIONS /${local.endpoint_name}"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}