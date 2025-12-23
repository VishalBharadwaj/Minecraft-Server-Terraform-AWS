locals {
  common_tags = {
    Project     = "minecraft-server"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "minecraft-admin"
    CostCenter  = "gaming"
  }

  # Security group rules for better organization
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidr
      description = "SSH access"
    },
    {
      from_port   = 25565
      to_port     = 25565
      protocol    = "tcp"
      cidr_blocks = var.minecraft_allowed_cidr
      description = "Minecraft server port"
    }
  ]

  egress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS outbound"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP outbound"
    },
    {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "DNS outbound"
    },
    {
      from_port   = 123
      to_port     = 123
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "NTP outbound"
    }
  ]
}