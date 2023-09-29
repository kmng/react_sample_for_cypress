provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "VPC-${var.stack_name}"
    Terraform = "true"
  }
}



resource "aws_vpc_dhcp_options" "main_dhcp_options" {
  domain_name_servers = ["AmazonProvidedDNS"]
  domain_name         = "example.com"
}

# Associate DHCP option set with VPC
resource "aws_vpc_dhcp_options_association" "main_dhcp_association" {
  vpc_id          = aws_vpc.main_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.main_dhcp_options.id
}


resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name      = "Internet-Gateway-${var.stack_name}"
    Terraform = "true"
  }
}


resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = {
    Name      = "EIP-${var.stack_name}"
    Terraform = "true"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.internet_gateway]
  tags = {
    Name      = "Nat-Gateway-${var.stack_name}"
    Terraform = "true"
  }
}





resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"

  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "public-${var.stack_name}"
    Terraform = "true"
  }
}


resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name      = "private-${var.stack_name}"
    Terraform = "true"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name      = "public-route-table-${var.stack_name}"
    Terraform = "true"
  }
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name      = "private-route-table-${var.stack_name}"
    Terraform = "true"
  }
}



resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}



resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}



resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  policy       = <<POLICY
{
  "Statement": [
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*",
      "Principal": "*"
    }
  ]
}
POLICY
}

resource "aws_vpc_endpoint_route_table_association" "s3_endpoint_association" {
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
}


data "aws_region" "current" {}


# Create a security group for the CodeBuild project
resource "aws_security_group" "codebuild_sg" {
  name        = "codebuild_sg"
  description = "Security group for CodeBuild"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from the VPC CIDR range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "sg-${var.stack_name}"
    Terraform = "true"
  }
}

resource "aws_codebuild_project" "codebuild_project" {
  name         = "codebuild-${var.stack_name}"
  description  = "CodeBuild project for complie react to push to s3"
  service_role = aws_iam_role.codebuild_role.arn
  vpc_config {
    vpc_id             = aws_vpc.main_vpc.id
    subnets            = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.codebuild_sg.id]
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec.yml"
    git_clone_depth = 1
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = "/aws/codebuild/codebuild-${var.stack_name}"
      stream_name = "{codebuild-spring-boot}-{build-id}"

    }
  }

}

resource "aws_codebuild_project" "codebuild_project_test" {
  name         = "codebuild-${var.stack_name}-test"
  description  = "CodeBuild project for cypress"
  service_role = aws_iam_role.codebuild_role.arn
  vpc_config {
    vpc_id             = aws_vpc.main_vpc.id
    subnets            = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.codebuild_sg.id]
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec_cypress.yml"
    git_clone_depth = 1
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = "/aws/codebuild/codebuild-${var.stack_name}-test"
      stream_name = "{codebuild-spring-boot}-{build-id}-1"

    }
  }

}


# Create the CodeBuild IAM service role
resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}



resource "aws_iam_policy" "codebuild_vpc_policy" {
  name        = "codebuild-vpc-policy"
  description = "Allows CodeBuild to access resources in a VPC"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:CreateNetworkInterfacePermission"
        ]
        Effect   = "Allow"
        Resource = "*"
        }, {
        "Action" : [
          "logs:GetLogEvents",
          "logs:CreateLogGroup",
          "logs:GetLogEvents",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
        }, {
        "Action" : [
          "s3:Get*",
          "s3:List*"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_vpc_policy_attachment" {
  policy_arn = aws_iam_policy.codebuild_vpc_policy.arn
  role       = aws_iam_role.codebuild_role.name
}


resource "aws_iam_role_policy_attachment" "codebuild_vpc_2_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  role       = aws_iam_role.codebuild_role.name
}

resource "aws_iam_role_policy_attachment" "codebuild_admin_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.codebuild_role.name
}


# Attach the necessary policies to the CodeBuild IAM role
resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}


# Create the CodeStar Connection for GitHub
resource "aws_codestarconnections_connection" "github_connection" {
  provider_type = "GitHub"
  name          = "Github-${var.stack_name}"

}


resource "aws_codepipeline" "pipeline" {
  name = "codebuild-${var.stack_name}"


  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = module.s3_bucket.s3_bucket_id
    type     = "S3"
  }


  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github_connection.arn
        FullRepositoryId = "kmng/react_sample_for_cypress"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_project.name
      }
    }
  }

  stage {
    name = "Test"

    action {
      name            = "Test"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_project_test.name
      }
    }
  }


}

# Create the CodePipeline IAM service role
resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the necessary policies to the CodePipeline IAM role
resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}



resource "aws_iam_role_policy" "codepipelinerole_policy" {
  name = "CodepipelineRole-Policy"
  role = aws_iam_role.codepipeline_role.name

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "codestar-connections:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketVersioning"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"

            ],
            "Resource": [
                "arn:aws:s3:::*",
                "arn:aws:s3:::*/*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*",
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate",
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }

    ],
    "Version": "2012-10-17"
}
EOF
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "s3-bucket-${var.stack_name}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  versioning = {
    enabled = true
  }
  force_destroy = true

  # Add any other S3 bucket configuration options here
}

resource "aws_sns_topic" "pipeline_notifications" {
  name = "PipelineNotifications"
}

resource "aws_sns_topic_subscription" "admin_subscriptions" {
  count     = length(var.admin_email_addresses)
  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = var.admin_email_addresses[count.index]
}


data "archive_file" "lambda_code" {
  type        = "zip"
  source_file  = "notification.js"
  output_path = "notification.zip"
}


resource "aws_iam_role" "pipeline_notification_function" {
  name = "PipelineNotificationFunctionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "sns_publish_policy" {
  name        = "SNSPublishPolicy"
  description = "Policy for publishing to SNS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["sns:Publish"],
        Effect   = "Allow",
        Resource = aws_sns_topic.pipeline_notifications.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sns_publish_policy_attachment" {
  policy_arn = aws_iam_policy.sns_publish_policy.arn
  role       = aws_iam_role.pipeline_notification_function.name
}

resource "aws_lambda_function" "pipeline_notification_function" {
  filename      = "notification.zip"
  function_name = "PipelineNotificationFunction"
  role          = aws_iam_role.pipeline_notification_function.arn
  handler       = "notification.handler"
  runtime       = "nodejs14.x"
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.pipeline_notifications.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "lambda_trigger_rule" {
  name        = "lambda-trigger-rule"
  description = "Trigger Lambda function on event"
  event_pattern = <<EOF
  {
    "source": ["aws.codepipeline"],
    "detail-type": ["CodePipeline Stage Execution State Change"],
    "resources": ["arn:aws:codepipeline:*"],
    "detail": {
      "state": ["SUCCEEDED"]
    }
  }
  EOF
}


resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_trigger_rule.name
  target_id = "target-lambda-function"

  role_arn  = aws_iam_role.cloudwatch_events_role.arn

  arn = aws_lambda_function.pipeline_notification_function.arn
}


resource "aws_iam_role" "cloudwatch_events_role" {
  name = "cloudwatch-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name        = "lambda-execution-policy"
  description = "Policy for Lambda execution from CloudWatch Events"
  policy      = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "lambda:InvokeFunction"
        ],
        "Resource": [
          "${aws_lambda_function.pipeline_notification_function.arn}"
        ]
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
  role       = aws_iam_role.cloudwatch_events_role.name
}