# 🎮 Production Minecraft Server on AWS with Terraform

A complete Infrastructure as Code solution for deploying a production-ready Minecraft Java Edition server on AWS, now optimized for the **m7i-flex.large** instance (FREE TIER ELIGIBLE!) with enterprise-grade features.

## 🚀 **GAME CHANGER: m7i-flex.large FREE TIER!**

**Incredible upgrade at NO COST:**
- **8GB RAM** (vs 1GB on t3.micro) - 8x more memory!
- **2 vCPUs** (vs 1 vCPU) - 2x processing power!
- **10-20 players** supported (vs 2-5 players)
- **Full mod/plugin support**
- **Still FREE** for 12 months!

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/VishalBharadwaj/Minecraft-Server-Terraform-AWS.git
cd Minecraft-Server-Terraform-AWS

# Configure your settings
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferences

# Deploy infrastructure
terraform init
terraform plan
terraform apply
```

## ✨ Features

### 🏗️ Infrastructure
- **EC2 m7i-flex.large** instance (FREE TIER! 2 vCPUs, 8GB RAM)
- **Custom VPC** with public subnet and security groups
- **Elastic IP** for consistent server address
- **Encrypted EBS storage** (30GB free tier limit)

### 🔒 Security
- **Restricted SSH access** (configurable IP whitelist)
- **Fail2ban protection** against brute force attacks
- **IMDSv2 enforcement** on EC2 instances
- **Network ACLs** for additional security layer
- **Encrypted storage** and secure IAM roles

### 📊 Monitoring & Observability
- **CloudWatch dashboards** with custom metrics
- **Automated alerting** for CPU and status checks
- **Centralized logging** to CloudWatch Logs
- **VPC Flow Logs** for network monitoring
- **Performance metrics** and resource utilization tracking

### 💾 Backup & Recovery
- **Automated daily backups** to S3 at 2 AM
- **30-day retention policy** with lifecycle management
- **Easy restore functionality** with dedicated scripts
- **S3 versioning** and intelligent tiering

### ⚡ Performance
- **Optimized JVM flags** for t3.micro (1GB RAM)
- **G1 garbage collector** for better performance
- **Resource limits** via systemd
- **Automatic server restart** on failure

## 📋 Requirements

- AWS Account (less than 12 months old for free tier)
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- SSH key pair

## 🛠️ Management

### Server Commands
```bash
# Check server status
sudo systemctl status minecraft

# View real-time logs
sudo journalctl -u minecraft -f

# Restart server
sudo systemctl restart minecraft
```

### Backup Management
```bash
# Manual backup
sudo -u minecraft /opt/minecraft/scripts/backup.sh

# Restore from backup
sudo /opt/minecraft/scripts/restore.sh <backup_name>
```

## 💰 Cost Optimization

- **Free Tier Optimized**: Stays within AWS free tier limits
- **750 hours/month** EC2 usage (covers 24/7 operation)
- **30GB EBS storage** limit respected
- **Automated cost monitoring** recommendations

## 📚 Documentation

- [Production Checklist](PRODUCTION_CHECKLIST.md) - Complete deployment guide
- [README](README.md) - Detailed setup and management instructions
- Inline code documentation and comments

## 🏷️ Tags

`minecraft` `aws` `terraform` `infrastructure-as-code` `gaming` `free-tier` `production-ready` `devops` `cloud` `automation`

## 📄 License

MIT License - Feel free to use and modify for your projects!

## 🤝 Contributing

Contributions welcome! Please read the contributing guidelines and submit pull requests for any improvements.

---

**⭐ Star this repository if it helped you deploy your Minecraft server!**