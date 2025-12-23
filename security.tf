# Additional security configurations

# Security group for ALB (if needed for future web interface)
resource "aws_security_group" "minecraft_web_sg" {
  count       = 0  # Disabled by default, enable if adding web interface
  name_prefix = "minecraft-web-sg-"
  description = "Security group for Minecraft web interface"
  vpc_id      = aws_vpc.minecraft_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "minecraft-web-security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# VPC Flow Logs for network monitoring
resource "aws_flow_log" "minecraft_vpc_flow_log" {
  count           = var.enable_monitoring ? 1 : 0
  iam_role_arn    = aws_iam_role.flow_log_role[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.minecraft_vpc.id

  tags = merge(local.common_tags, {
    Name = "minecraft-vpc-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_iam_role" "flow_log_role" {
  count = var.enable_monitoring ? 1 : 0
  name  = "minecraft-flow-log-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_log_policy" {
  count = var.enable_monitoring ? 1 : 0
  name  = "minecraft-flow-log-policy"
  role  = aws_iam_role.flow_log_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Network ACL for additional security layer
resource "aws_network_acl" "minecraft_nacl" {
  vpc_id     = aws_vpc.minecraft_vpc.id
  subnet_ids = [aws_subnet.minecraft_subnet.id]

  # Allow SSH
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Allow Minecraft
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 25565
    to_port    = 25565
  }

  # Allow HTTP/HTTPS for updates
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, {
    Name = "minecraft-network-acl"
  })
}