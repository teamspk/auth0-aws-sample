# Lambda role
resource "aws_iam_role" "lambda_exec_role" {
    name = "lambda_exec_role"
    path = "/"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
    name = "lambda_policy"
    role = "${aws_iam_role.lambda_exec_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda-invoke" {
    name = "lambdal-invoke"
    roles = ["${aws_iam_role.lambda_exec_role.name}"]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}



resource "aws_iam_role" "APIGatewayLambdaExecRole2" {
    name = "APIGatewayLambdaExecRole2"
    path = "/"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "LogAndDynamoDBAccess" {
    name = "LogAndDynamoDBAccess"
    role = "${aws_iam_role.APIGatewayLambdaExecRole2.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AccessCloudwatchLogs",
            "Action": [
                "logs:*"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Sid": "PetsDynamoDBReadWrite",
            "Effect": "Allow",
            "Action": [
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:Query"
            ],
            "Resource": [
                "arn:aws:dynamodb:ap-northeast-1:713403314913:table/Pets",
                "arn:aws:dynamodb:ap-northeast-1:713403314913:table/sparkl-*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "lambda_dynamo_streams" {
    name = "lambda_dynamo_streams"
    path = "/"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_dynamo_streams" {
    name = "lambda_dynamo_streams"
    role = "${aws_iam_role.lambda_dynamo_streams.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeStream",
        "dynamodb:ListStreams",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


# API GW

## REST API
resource "aws_api_gateway_rest_api" "sparkl-a" {
  name = "sparkl-a"
  description = "sparkl appointments"
}

## Resources
resource "aws_api_gateway_resource" "appointments" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  parent_id = "${aws_api_gateway_rest_api.sparkl-a.root_resource_id}"
  path_part = "appointments"
}

resource "aws_api_gateway_resource" "confirm" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  parent_id = "${aws_api_gateway_resource.appointments.id}"
  path_part = "confirm"
}

## Methods
resource "aws_api_gateway_method" "appointments_get" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "appointments_post" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "appointments_options" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "confirm_post" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "confirm_options" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "OPTIONS"
  authorization = "NONE"
}


## Integrations
resource "aws_api_gateway_integration" "appointments_get" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "${aws_api_gateway_method.appointments_get.http_method}"
  integration_http_method = "POST"
  type = "AWS"
  uri = "arn:aws:apigateway:ap-northeast-1:lambda:path/2015-03-31/functions/arn:aws:lambda:ap-northeast-1:951720451008:function:SparklGetAppointments/invocations"
  depends_on = ["aws_api_gateway_method.appointments_get"]
}

resource "aws_api_gateway_integration" "appointments_post" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "${aws_api_gateway_method.appointments_post.http_method}"
  integration_http_method = "POST"
  type = "AWS"
  uri = "arn:aws:apigateway:ap-northeast-1:lambda:path/2015-03-31/functions/arn:aws:lambda:ap-northeast-1:951720451008:function:SparklCreateAppointment/invocations"
  depends_on = ["aws_api_gateway_method.appointments_post"]
}

resource "aws_api_gateway_integration" "appointments_options" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "${aws_api_gateway_method.appointments_options.http_method}"
  integration_http_method = "POST"
  type = "AWS"
  uri = "arn:aws:apigateway:ap-northeast-1:lambda:path/2015-03-31/functions/arn:aws:lambda:ap-northeast-1:951720451008:function:NoOp/invocations"
  depends_on = ["aws_api_gateway_method.appointments_options"]
}

resource "aws_api_gateway_integration" "confirm_post" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "${aws_api_gateway_method.confirm_post.http_method}"
  integration_http_method = "POST"
  type = "AWS"
  uri = "arn:aws:apigateway:ap-northeast-1:lambda:path/2015-03-31/functions/arn:aws:lambda:ap-northeast-1:951720451008:function:SparklConfirmAppointment/invocations"
  depends_on = ["aws_api_gateway_method.confirm_post"]
}

resource "aws_api_gateway_integration" "confirm_options" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "${aws_api_gateway_method.confirm_options.http_method}"
  integration_http_method = "POST"
  type = "AWS"
  uri = "arn:aws:apigateway:ap-northeast-1:lambda:path/2015-03-31/functions/arn:aws:lambda:ap-northeast-1:951720451008:function:NoOp/invocations"
  depends_on = ["aws_api_gateway_method.confirm_post"]
}


## Method responses
resource "aws_api_gateway_method_response" "appointments_get_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "${aws_api_gateway_method.appointments_get.http_method}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  # Access-Control-Allow-Methods
  # Access-Control-Allow-Origin
}

resource "aws_api_gateway_method_response" "appointments_post_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "${aws_api_gateway_method.appointments_post.http_method}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  # Access-Control-Allow-Methods
  # Access-Control-Allow-Origin
}

resource "aws_api_gateway_method_response" "appointments_options_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "${aws_api_gateway_method.appointments_options.http_method}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  # Access-Control-Allow-Headers
  # Access-Control-Allow-Methods
  # Access-Control-Allow-Origin
}

resource "aws_api_gateway_method_response" "confirm_post_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "${aws_api_gateway_method.confirm_post.http_method}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  # Access-Control-Allow-Origin
}

resource "aws_api_gateway_method_response" "confirm_post_403" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "${aws_api_gateway_method.confirm_post.http_method}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  # Access-Control-Allow-Origin
}

resource "aws_api_gateway_method_response" "confirm_options_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "${aws_api_gateway_method.confirm_options.http_method}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  # Access-Control-Allow-Headers
  # Access-Control-Allow-Methods
  # Access-Control-Allow-Origin
}

## Integration responses
resource "aws_api_gateway_integration_response" "appointments_get_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "${aws_api_gateway_method.appointments_get.http_method}"
  status_code = "${aws_api_gateway_method_response.appointments_get_200.status_code}"
  response_templates = {
    "application/json" = ""
  }
  # Access-Control-Allow-Methods = 'POST, GET, OPTIONS'
  # Access-Control-Allow-Origin  = '*'
}

resource "aws_api_gateway_integration_response" "appointments_post_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "${aws_api_gateway_method.appointments_post.http_method}"
  status_code = "${aws_api_gateway_method_response.appointments_post_200.status_code}"
  response_templates = {
    "application/json" = ""
  }
  # Access-Control-Allow-Methods = 'POST, GET, OPTIONS'
  # Access-Control-Allow-Origin  = '*'
}

resource "aws_api_gateway_integration_response" "appointments_options_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.appointments.id}"
  http_method = "${aws_api_gateway_method.appointments_options.http_method}"
  status_code = "${aws_api_gateway_method_response.appointments_options_200.status_code}"
  response_templates = {
    "application/json" = ""
  }
  # Access-Control-Allow-Headers = 'Content-Type,X-Amz-Date,Authorization,X-Api-Key, Access-Control-Allow-Origin, x-amz-security-token' 
  # Access-Control-Allow-Methods = 'POST, GET, OPTIONS'
  # Access-Control-Allow-Origin  = '*'
}

resource "aws_api_gateway_integration_response" "confirm_post_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "${aws_api_gateway_method.confirm_post.http_method}"
  status_code = "${aws_api_gateway_method_response.confirm_post_200.status_code}"
  response_templates = {
    "application/json" = ""
  }
  # Access-Control-Allow-Origin  = '*'
}

resource "aws_api_gateway_integration_response" "confirm_post_403" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "${aws_api_gateway_method.confirm_post.http_method}"
  status_code = "${aws_api_gateway_method_response.confirm_post_403.status_code}"
  #selection_pattern = ".*(fail|not available).*"
  response_templates = {
    "application/json" = ""
  }
  # Access-Control-Allow-Origin  = '*'
}

resource "aws_api_gateway_integration_response" "confirm_options_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "${aws_api_gateway_method.confirm_options.http_method}"
  status_code = "${aws_api_gateway_method_response.confirm_options_200.status_code}"
  #selection_pattern = '.*(fail|not available).*'
  response_templates = {
    "application/json" = ""
  }
  # Access-Control-Allow-Headers = 'Content-Type,X-Amz-Date,Authorization,X-Api-Key, Access-Control-Allow-Origin, x-amz-security-token' 
  # Access-Control-Allow-Methods = 'POST, GET, OPTIONS'
  # Access-Control-Allow-Origin  = '*'
}

# TODO
# Wait for https://github.com/hashicorp/terraform/pull/5893 (something wrong with selection_pattern?)
# Enable CORS
# Are headers even implemented yet? - https://github.com/hashicorp/terraform/issues/6092
# Response headers 
# Integration Response headers 
