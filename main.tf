terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Uncomment and configure for production state management
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "minecraft-server/terraform.tfstate"
  #   region = "us-east-1"
  #   encrypt = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "minecraft-server"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# VPC and Networking
resource "aws_vpc" "minecraft_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "minecraft-vpc"
  }
}

resource "aws_internet_gateway" "minecraft_igw" {
  vpc_id = aws_vpc.minecraft_vpc.id

  tags = {
    Name = "minecraft-igw"
  }
}

resource "aws_subnet" "minecraft_subnet" {
  vpc_id                  = aws_vpc.minecraft_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "minecraft-subnet"
  }
}

resource "aws_route_table" "minecraft_rt" {
  vpc_id = aws_vpc.minecraft_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minecraft_igw.id
  }

  tags = {
    Name = "minecraft-route-table"
  }
}

resource "aws_route_table_association" "minecraft_rta" {
  subnet_id      = aws_subnet.minecraft_subnet.id
  route_table_id = aws_route_table.minecraft_rt.id
}

# Security Group
resource "aws_security_group" "minecraft_sg" {
  name_prefix = "minecraft-sg-"
  description = "Security group for Minecraft server"
  vpc_id      = aws_vpc.minecraft_vpc.id

  # SSH access - restrict to specific IPs in production
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "SSH access"
  }

  # Minecraft server port
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = var.minecraft_allowed_cidr
    description = "Minecraft server port"
  }

  # Alternative Minecraft ports for firewall bypass
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.minecraft_allowed_cidr
    description = "Minecraft alternative port (HTTP)"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.minecraft_allowed_cidr
    description = "Minecraft alternative port (HTTPS)"
  }

  # HTTPS for updates and downloads
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  # HTTP for updates and downloads
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound"
  }

  # DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS outbound"
  }

  # NTP
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NTP outbound"
  }

  tags = {
    Name = "minecraft-security-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for EC2 instance
resource "aws_iam_role" "minecraft_role" {
  name_prefix = "minecraft-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "minecraft-iam-role"
  }
}

# IAM Policy for CloudWatch and S3 backup access
resource "aws_iam_role_policy" "minecraft_policy" {
  name_prefix = "minecraft-policy-"
  role        = aws_iam_role.minecraft_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.minecraft_backups.arn,
          "${aws_s3_bucket.minecraft_backups.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "minecraft_profile" {
  name_prefix = "minecraft-profile-"
  role        = aws_iam_role.minecraft_role.name
}

# S3 Bucket for backups
resource "aws_s3_bucket" "minecraft_backups" {
  bucket_prefix = "minecraft-backups-"
  force_destroy = false

  tags = {
    Name = "minecraft-backups"
  }
}

resource "aws_s3_bucket_versioning" "minecraft_backups_versioning" {
  bucket = aws_s3_bucket.minecraft_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "minecraft_backups_encryption" {
  bucket = aws_s3_bucket.minecraft_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "minecraft_backups_lifecycle" {
  bucket = aws_s3_bucket.minecraft_backups.id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "minecraft_backups_pab" {
  bucket = aws_s3_bucket.minecraft_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "minecraft_logs" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/aws/ec2/minecraft"
  retention_in_days = 30

  tags = {
    Name = "minecraft-logs"
  }
}

# Key Pair
resource "aws_key_pair" "minecraft_key" {
  key_name_prefix = "minecraft-key-"
  public_key      = file(var.public_key_path)

  tags = {
    Name = "minecraft-key-pair"
  }
}

# EC2 Instance
resource "aws_instance" "minecraft_server" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.minecraft_key.key_name
  vpc_security_group_ids  = [aws_security_group.minecraft_sg.id]
  subnet_id               = aws_subnet.minecraft_subnet.id
  iam_instance_profile    = aws_iam_instance_profile.minecraft_profile.name
  disable_api_termination = true  # Prevent accidental termination

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.volume_size
    encrypted             = true
    delete_on_termination = false  # Preserve data on instance termination
    
    tags = {
      Name = "minecraft-root-volume"
    }
  }

  user_data = base64encode(templatefile("user-data.sh", {
    minecraft_version     = var.minecraft_version
    server_name          = var.server_name
    max_players          = var.max_players
    difficulty           = var.difficulty
    backup_bucket        = aws_s3_bucket.minecraft_backups.bucket
    enable_monitoring    = var.enable_monitoring
    log_group_name       = var.enable_monitoring ? aws_cloudwatch_log_group.minecraft_logs[0].name : ""
    backup_retention_days = var.backup_retention_days
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"  # Require IMDSv2
    http_put_response_hop_limit = 1
  }

  monitoring = var.enable_monitoring

  tags = {
    Name = "minecraft-server"
  }

  lifecycle {
    ignore_changes = [ami]  # Prevent replacement on AMI updates
  }
}

# Elastic IP (optional but recommended)
resource "aws_eip" "minecraft_eip" {
  instance = aws_instance.minecraft_server.id
  domain   = "vpc"

  tags = {
    Name = "minecraft-eip"
  }

  depends_on = [aws_internet_gateway.minecraft_igw]
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "minecraft-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = []  # Add SNS topic ARN for notifications

  dimensions = {
    InstanceId = aws_instance.minecraft_server.id
  }

  tags = {
    Name = "minecraft-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "minecraft-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors ec2 status check"
  alarm_actions       = []  # Add SNS topic ARN for notifications

  dimensions = {
    InstanceId = aws_instance.minecraft_server.id
  }

  tags = {
    Name = "minecraft-status-alarm"
  }
}