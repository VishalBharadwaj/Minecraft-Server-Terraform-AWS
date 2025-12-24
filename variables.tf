variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type (m7i-flex.large is free tier eligible with excellent performance!)"
  type        = string
  default     = "m7i-flex.large"
  
  validation {
    condition = contains([
      "t2.micro", "t3.micro",           # Traditional free tier
      "m7i-flex.large", "m7i-flex.xlarge", # New free tier eligible (better performance!)
      "t3.small", "t3.medium",          # Burstable performance
      "m6i.large", "m6i.xlarge",        # Previous generation
      "c6i.large", "c6i.xlarge"         # Compute optimized
    ], var.instance_type)
    error_message = "Instance type must be a supported EC2 instance type."
  }
}

variable "volume_size" {
  description = "Root volume size in GB (free tier allows up to 30GB, can increase for better performance)"
  type        = number
  default     = 30
  
  validation {
    condition     = var.volume_size >= 20 && var.volume_size <= 100
    error_message = "Volume size must be between 20 and 100 GB."
  }
}

variable "public_key_path" {
  description = "Path to your public SSH key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "minecraft_version" {
  description = "Minecraft server version to download"
  type        = string
  default     = "1.20.4"
}

variable "server_name" {
  description = "Name for your Minecraft server"
  type        = string
  default     = "My Minecraft Server"
}

variable "max_players" {
  description = "Maximum number of players"
  type        = number
  default     = 10
}

variable "difficulty" {
  description = "Game difficulty (peaceful, easy, normal, hard)"
  type        = string
  default     = "normal"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access (restrict to your IP for security)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this to your IP for production
}

variable "minecraft_allowed_cidr" {
  description = "CIDR blocks allowed for Minecraft access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and logging"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}