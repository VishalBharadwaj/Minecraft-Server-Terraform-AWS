variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type (use t2.micro or t3.micro for free tier)"
  type        = string
  default     = "t3.micro"
}

variable "volume_size" {
  description = "Root volume size in GB (free tier allows up to 30GB)"
  type        = number
  default     = 20
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