resource "aws_dynamodb_table" "api" {
  name           = "${local.api_name}-api"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "PK"
  range_key      = "SK"

  ttl {
    attribute_name = "expireAt"
    enabled        = true
  }

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "LSI1PK"
    type = "S"
  }

  attribute {
    name = "LSI2PK"
    type = "S"
  }

  attribute {
    name = "LSI3PK"
    type = "S"
  }

  attribute {
    name = "LSI4PK"
    type = "S"
  }

  attribute {
    name = "LSI5PK"
    type = "S"
  }

  local_secondary_index {
    name            = "LSI1"
    projection_type = "ALL"
    range_key       = "LSI1PK"
  }

  local_secondary_index {
    name            = "LSI2"
    projection_type = "ALL"
    range_key       = "LSI2PK"
  }

  local_secondary_index {
    name            = "LSI3"
    projection_type = "ALL"
    range_key       = "LSI3PK"
  }

  local_secondary_index {
    name            = "LSI4"
    projection_type = "ALL"
    range_key       = "LSI4PK"
  }

  local_secondary_index {
    name            = "LSI5"
    projection_type = "ALL"
    range_key       = "LSI5PK"
  }

  tags = {
    Name = "${local.api_name}-api"
  }
}
