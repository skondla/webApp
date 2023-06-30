terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

data "aws_region" "current" {}

resource "aws_s3_object_copy" "lambda_promtail_zipfile" {
  bucket = var.s3_bucket
  key    = var.s3_key
  source = "grafanalabs-cf-templates/lambda-promtail/lambda-promtail.zip"
}

resource "aws_iam_role" "lambda_promtail_role" {
  name = "GrafanaLabsCloudWatchLogsIntegration"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_promtail_policy_logs" {
  name = "lambda-logs"
  role = aws_iam_role.lambda_promtail_role.name
  policy = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:logs:*:*:*",
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda_promtail_log_group" {
  name              = "/aws/lambda/GrafanaCloudLambdaPromtail"
  retention_in_days = 14
}

resource "aws_lambda_function" "lambda_promtail" {
  function_name = "GrafanaCloudLambdaPromtail"
  role          = aws_iam_role.lambda_promtail_role.arn

  timeout     = 60
  memory_size = 128

  handler   = "main"
  runtime   = "go1.x"
  s3_bucket = var.s3_bucket
  s3_key    = var.s3_key

  environment {
    variables = {
      WRITE_ADDRESS = var.write_address
      USERNAME      = var.username
      PASSWORD      = var.password
      KEEP_STREAM   = var.keep_stream
      BATCH_SIZE    = var.batch_size
      EXTRA_LABELS  = var.extra_labels
    }
  }

  depends_on = [
    aws_s3_object_copy.lambda_promtail_zipfile,
    aws_iam_role_policy.lambda_promtail_policy_logs,
    aws_cloudwatch_log_group.lambda_promtail_log_group,
  ]
}

resource "aws_lambda_function_event_invoke_config" "lambda_promtail_invoke_config" {
  function_name          = aws_lambda_function.lambda_promtail.function_name
  maximum_retry_attempts = 2
}

resource "aws_lambda_permission" "lambda_promtail_allow_cloudwatch" {
  statement_id  = "lambda-promtail-allow-cloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_promtail.function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
}

# This block allows for easily subscribing to multiple log groups via the `log_group_names` var.
# However, if you need to provide an actual filter_pattern for a specific log group you should
# copy this block and modify it accordingly.
resource "aws_cloudwatch_log_subscription_filter" "lambda_promtail_logfilter" {
  for_each        = toset(var.log_group_names)
  name            = "lambda_promtail_logfilter_${each.value}"
  log_group_name  = each.value
  destination_arn = aws_lambda_function.lambda_promtail.arn
  # required but can be empty string
  filter_pattern = ""
  depends_on     = [aws_iam_role_policy.lambda_promtail_policy_logs]
}

output "role_arn" {
  value       = aws_lambda_function.lambda_promtail.arn
  description = "The ARN of the Lambda function that runs lambda-promtail."
}

