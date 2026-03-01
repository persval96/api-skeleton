resource "aws_lambda_function" "api" {
  function_name    = "${var.api_name}-${local.endpoint_name}-${var.env}"
  role             = aws_iam_role.api.arn
  handler          = "public/index.php"
  runtime          = "provided.al2023"
  source_code_hash = data.archive_file.api.output_base64sha256
  filename         = data.archive_file.api.output_path
  timeout          = 30
  memory_size      = var.lambda_config.memory_size
  layers           = [var.lambda_config.layer_arn]
  architectures    = [var.lambda_config.architecture]

  environment {
    variables = {
      #######################
      #     APP CONFIG      #
      #######################
      APP_ENV     = var.env
      APP_DEBUG   = var.env == "prod" ? "false" : "true"
      APP_STORAGE = "/tmp"
      LOG_CHANNEL = "stderr"
      LOG_LEVEL   = var.env == "prod" ? "warning" : "debug"

      #######################
      #     BREF CONFIG     #
      #######################
      BREF_LOOP_MAX = var.lambda_config.bref_loop_max
      BREF_HANDLER  = var.lambda_config.handler
      BREF_RUNTIME  = "fpm"
    }
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${var.api_name}-${local.endpoint_name}-${var.env}"
  retention_in_days = 7
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.api.id}/*/*"
}