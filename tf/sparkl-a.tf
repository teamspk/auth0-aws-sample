# TODO:
#lambda subscription

# s3
resource "aws_s3_bucket" "s3-site" {
    bucket = "sparkl-a"
    acl = "public-read"
    website {
        index_document = "index.html"
    }
    tags {
        Name = "sparkl-a"
        Env = "production"
    }
    cors_rule {
        allowed_headers = ["Authorization"]
        allowed_methods = ["GET"]
        allowed_origins = ["*"]
        max_age_seconds = 3000
    }
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::sparkl-a/*"
        }
    ]
}
EOF
}

# dynamodb
resource "aws_dynamodb_table" "sparkl-appointments" {
    name = "sparkl-appointments"
    read_capacity = 1
    write_capacity = 1
    hash_key = "client_project"
    range_key = "created_at"
    attribute {
      name = "client_project"
      type = "S"
    }
    attribute {
      name = "created_at"
      type = "S"
    }
    stream_enabled = true
    stream_view_type = "NEW_AND_OLD_IMAGES"
}

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
            "Sid": "DynamoDBReadWrite",
            "Effect": "Allow",
            "Action": [
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:GetRecords",
                "dynamodb:GetShardIterator",
                "dynamodb:DescribeStream",
                "dynamodb:ListStreams",
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": [
                "arn:aws:dynamodb:ap-northeast-1:951720451008:table/sparkl-*"
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


# auth0 role
resource "aws_iam_saml_provider" "auth0-provider" {
    name = "auth0-provider"
    saml_metadata_document = "${file("iDC9GHTe9nM2w1L146zn2o7qxEgpoEZI")}"
}

resource "aws_iam_role" "auth0-api-role" {
    name = "auth0-api-role"
    path = "/"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::951720451008:saml-provider/auth0-provider"
      },
      "Action": "sts:AssumeRoleWithSAML",
      "Condition": {
        "StringEquals": {
          "SAML:iss": "urn:ijin.auth0.com"
        }
      }
    },
    {
      "Sid": "gateway",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "admin-policy" {
    name = "admin-policy"
    role = "${aws_iam_role.auth0-api-role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "execute-api:*"
            ],
            "Resource": [
                "arn:aws:execute-api:ap-northeast-1:951720451008:etgu4qrh4a/prod/*/appointments"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "auth0-api-social-role" {
    name = "auth0-api-social-role"
    path = "/"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::951720451008:saml-provider/auth0-provider"
      },
      "Action": "sts:AssumeRoleWithSAML",
      "Condition": {
        "StringEquals": {
          "SAML:iss": "urn:ijin.auth0.com"
        }
      }
    },
    {
      "Sid": "gateway",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "users-policy" {
    name = "users-policy"
    role = "${aws_iam_role.auth0-api-social-role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "execute-api:*"
            ],
            "Resource": [
                "arn:aws:execute-api:ap-northeast-1:951720451008:etgu4qrh4a/prod/*/appointments/confirm"
            ]
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
  authorization = "AWS_IAM"
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
  authorization = "AWS_IAM"
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

#resource "aws_api_gateway_method_response" "confirm_post_403" {
#  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
#  resource_id = "${aws_api_gateway_resource.confirm.id}"
#  http_method = "${aws_api_gateway_method.confirm_post.http_method}"
#  status_code = "200"
#  response_models = {
#    "application/json" = "Empty"
#  }
#  # Access-Control-Allow-Origin
#}

resource "aws_api_gateway_method_response" "confirm_options_200" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  resource_id = "${aws_api_gateway_resource.confirm.id}"
  http_method = "${aws_api_gateway_method.confirm_options.http_method}"
  status_code = "200"
  response_models = {
    "application/json; charset=utf-8" = "Empty"
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

#resource "aws_api_gateway_integration_response" "confirm_post_403" {
#  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
#  resource_id = "${aws_api_gateway_resource.confirm.id}"
#  http_method = "${aws_api_gateway_method.confirm_post.http_method}"
#  status_code = "${aws_api_gateway_method_response.confirm_post_403.status_code}"
#  #selection_pattern = ".*(fail|not available).*"
#  response_templates = {
#    "application/json" = ""
#  }
#  # Access-Control-Allow-Origin  = '*'
#}

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

resource "aws_api_gateway_deployment" "sparkl-a_deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.sparkl-a.id}"
  depends_on = ["aws_api_gateway_integration.appointments_get"]
  stage_name = "prod"
}

# Permissions
resource "aws_lambda_permission" "apigw_appo_get" {
  statement_id = "apigw_appo_get"
  action = "lambda:InvokeFunction"
  function_name = "SparklGetAppointments"
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:ap-northeast-1:951720451008:${aws_api_gateway_rest_api.sparkl-a.id}/*/GET/${aws_api_gateway_resource.appointments.path_part}"
}

resource "aws_lambda_permission" "apigw_appo_post" {
  statement_id = "apigw_appo_post"
  action = "lambda:InvokeFunction"
  function_name = "SparklCreateAppointment"
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:ap-northeast-1:951720451008:${aws_api_gateway_rest_api.sparkl-a.id}/*/POST/${aws_api_gateway_resource.appointments.path_part}"
}

resource "aws_lambda_permission" "apigw_appo_options" {
  statement_id = "apigw_appo_options"
  action = "lambda:InvokeFunction"
  function_name = "NoOp"
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:ap-northeast-1:951720451008:${aws_api_gateway_rest_api.sparkl-a.id}/*/OPTIONS/${aws_api_gateway_resource.appointments.path_part}"
}

resource "aws_lambda_permission" "apigw_confirm_post" {
  statement_id = "apigw_confirm_post"
  action = "lambda:InvokeFunction"
  function_name = "SparklConfirmAppointment"
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:ap-northeast-1:951720451008:${aws_api_gateway_rest_api.sparkl-a.id}/*/POST/${aws_api_gateway_resource.appointments.path_part}/${aws_api_gateway_resource.confirm.path_part}"
}

resource "aws_lambda_permission" "apigw_confirm_options" {
  statement_id = "apigw_confirm_options"
  action = "lambda:InvokeFunction"
  function_name = "NoOp"
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:ap-northeast-1:951720451008:${aws_api_gateway_rest_api.sparkl-a.id}/*/OPTIONS/${aws_api_gateway_resource.appointments.path_part}/${aws_api_gateway_resource.confirm.path_part}"
}



# TODO
# Wait for https://github.com/hashicorp/terraform/pull/5893 (something wrong with selection_pattern?)
# Enable CORS
# Are headers even implemented yet? - https://github.com/hashicorp/terraform/issues/6092
# Response headers 
# Integration Response headers 


# aws --region ap-northeast-1 --profile sparkl apigateway get-rest-apis --output table
# export rest_id=$(aws --region ap-northeast-1 --profile sparkl apigateway get-rest-apis --query 'items[?name==`sparkl-a`].id' --output text)
# aws --region ap-northeast-1 --profile sparkl apigateway get-resources --rest-api-id $rest_id --output table
# export appo_resource_id=$(aws --region ap-northeast-1 --profile sparkl apigateway get-resources --rest-api-id $rest_id --query 'items[?pathPart==`appointments`].id' --output text)
# export confirm_resource_id=$(aws --region ap-northeast-1 --profile sparkl apigateway get-resources --rest-api-id $rest_id --query 'items[?pathPart==`confirm`].id' --output text)

# Add 403
# Method Response /confirm (OPTIONS) 403
# aws --region ap-northeast-1 --profile sparkl apigateway put-method-response --rest-api-id $rest_id --resource-id $confirm_resource_id --http-method POST --status-code 403 --response-models '{"application/json": "Empty"}' --response-parameters '{"method.response.header.Access-Control-Allow-Origin":true}'
# Integration Response /confirm (OPTIONS) 403
# aws --region ap-northeast-1 --profile sparkl apigateway put-integration-response --rest-api-id $rest_id --resource-id $confirm_resource_id --http-method POST --status-code 403 --response-templates '{"application/json": ""}' --selection-pattern ".*(fail|not available).*"

# Update headers
# Method Response: /appointments
# for method in 'GET' 'POST' 'OPTIONS'; do aws --region ap-northeast-1 --profile sparkl apigateway update-method-response --rest-api-id $rest_id --resource-id $appo_resource_id --http-method $method --status-code 200 --patch-operations op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Origin" op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Methods"; done
# Integration Response: /appointments
# for method in 'GET' 'POST' 'OPTIONS'; do aws --region ap-northeast-1 --profile sparkl apigateway update-integration-response --rest-api-id $rest_id --resource-id $appo_resource_id --http-method $method --status-code 200 --patch-operations op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Origin",value="\"'*'\"" op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Methods",value="\"'POST,GET,OPTIONS'\""; done 
# CORS /appointments
# aws --region ap-northeast-1 --profile sparkl apigateway update-method-response --rest-api-id $rest_id --resource-id $appo_resource_id --http-method OPTIONS --status-code 200 --patch-operations op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Headers" 
# aws --region ap-northeast-1 --profile sparkl apigateway update-integration-response --rest-api-id $rest_id --resource-id $appo_resource_id --http-method OPTIONS --status-code 200 --patch-operations op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Headers",value="\"'Content-Type,X-Amz-Date,Authorization,X-Api-Key, Access-Control-Allow-Origin, x-amz-security-token'\""


# Method Response: /confirm (POST) 
# aws --region ap-northeast-1 --profile sparkl apigateway update-method-response --rest-api-id $rest_id --resource-id $confirm_resource_id --http-method POST --status-code 200 --patch-operations op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Origin" 
# Integration Response: /confirm (POST) 
# aws --region ap-northeast-1 --profile sparkl apigateway update-integration-response --rest-api-id $rest_id --resource-id $confirm_resource_id --http-method POST --status-code 200 --patch-operations op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Origin",value="\"'*'\""

# Method Response: /confirm (OPTIONS) 
# aws --region ap-northeast-1 --profile sparkl apigateway update-method-response --rest-api-id $rest_id --resource-id $confirm_resource_id --http-method OPTIONS --status-code 200 --patch-operations op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Origin" op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Methods" op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Headers"
# Integration Response: /confirm (OPTIONS) 
# aws --region ap-northeast-1 --profile sparkl apigateway update-integration-response --rest-api-id $rest_id --resource-id $confirm_resource_id --http-method OPTIONS --status-code 200 --patch-operations op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Origin",value="\"'*'\"" op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Methods",value="\"'POST,OPTIONS'\"" op=add,path="/responseParameters/method.response.header.Access-Control-Allow-Headers",value="\"'Content-Type,X-Amz-Date,Authorization,X-Api-Key, Access-Control-Allow-Origin, x-amz-security-token'\""


# json-pointer example
# aws --region ap-northeast-1 --profile sparkl apigateway update-method-response --rest-api-id $rest_id --resource-id $confirm_resource_id --http-method OPTIONS --status-code 200 --patch-operations op=remove,path="/responseModels/application~1json"
# aws --region ap-northeast-1 --profile sparkl apigateway update-method-response --rest-api-id $rest_id --resource-id $confirm_resource_id --http-method OPTIONS --status-code 200 --patch-operations op=add,path="/responseModels/application~1json; charset=utf-8",value="Empty"     



# TODO
# set authorization, since TF doesnt support it.
#aws --profile sparkl apigateway update-method --rest-api-id etgu4qrh4a --resource-id 5rhr33 --http-method POST --patch-operations op=replace,path="/authorizationType",value="AWS_IAM"

