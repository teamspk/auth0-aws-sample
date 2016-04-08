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

