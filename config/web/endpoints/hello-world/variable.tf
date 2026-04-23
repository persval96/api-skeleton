variable "lambda_config" {
  type = object({
    layer_arn : string
    architecture : string
    handler : string
    bref_loop_max : string
    memory_size : number
  })
}

variable "api_name" {
  type        = string
  description = "The API name"
}

variable "domain_name" {
  type        = string
  description = "The apigateway domain name"
}

variable "env" {
  type        = string
  description = "The environment variable. example : dev,sbx,prod"
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name"
}