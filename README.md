# Production Minecraft Server on AWS with Terraform

This project deploys a production-ready Minecraft Java Edition server on AWS using Terraform, now optimized for the **m7i-flex.large** instance (FREE TIER ELIGIBLE!) with enterprise-grade features.

## 🚀 **AMAZING UPDATE: m7i-flex.large is FREE TIER ELIGIBLE!**

**What this means for your Minecraft server:**
- **8GB RAM** instead of 1GB (8x more memory!)
- **2 vCPUs** instead of 1 (2x processing power!)
- **10-20 players** supported instead of 2-5
- **Full plugin/mod support** 
- **Still completely FREE** for 12 months!

## Production Features

- **Security**: Restricted security groups, fail2ban, IMDSv2, encrypted storage
- **Monitoring**: CloudWatch metrics, alarms, and centralized logging
- **Backup**: Automated S3 backups with lifecycle management
- **Performance**: Optimized JVM flags for t3.micro instances
- **Reliability**: Auto-restart, health checks, and proper service management
- **Compliance**: Security hardening, audit logging, and access controls

## Prerequisites

1. **AWS Account** (less than 12 months old for free tier benefits)
2. **AWS CLI** configured with appropriate permissions
3. **Terraform** installed (version >= 1.0)
4. **SSH Key Pair** generated

## Required AWS Permissions

Your AWS user/role needs these permissions:
- EC2: Full access for instances, security groups, VPC
- S3: Full access for backup bucket
- IAM: Create roles and policies for EC2 instance
- CloudWatch: Create log groups and alarms

## Free Tier Resources Used

- **EC2 m7i-flex.large instance** (750 hours/month free) - **2 vCPUs, 8GB RAM!** 🚀
- 30GB GP3 EBS storage (30GB free tier limit)
- S3 storage for backups (5GB free)
- CloudWatch logs and metrics (basic tier)
- VPC, Security Groups, and networking (free)

## Quick Start

1. **Clone and setup:**
   ```bash
   git clone <your-repo>
   cd minecraft-terraform-aws
   ```

2. **Generate SSH key pair (if needed):**
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

3. **Configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars - IMPORTANT: Set your IP for SSH access
   ```

4. **Deploy infrastructure:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Security Configuration (CRITICAL):**
   - Update `allowed_ssh_cidr` in terraform.tfvars to your IP
   - Consider restricting `minecraft_allowed_cidr` if needed
   - Apply changes: `terraform apply`

## Production Configuration

### Security Hardening
- SSH access restricted by IP (configure in terraform.tfvars)
- Fail2ban protection against brute force attacks
- IMDSv2 enforced on EC2 instance
- Encrypted EBS volumes
- Minimal security group rules
- Regular security updates via yum-cron

### Monitoring & Alerting
- CloudWatch metrics for CPU, memory, disk usage
- Custom alarms for high CPU and status checks
- Centralized logging to CloudWatch Logs
- Server performance monitoring

### Backup Strategy
- Automated daily backups to S3 at 2 AM
- 30-day retention policy (configurable)
- S3 lifecycle management for cost optimization
- Easy restore functionality
- Local backup cleanup (7 days)

### Performance Optimization
- Optimized JVM flags for t3.micro (1GB RAM)
- G1 garbage collector for better performance
- Proper memory allocation (896MB heap)
- Resource limits via systemd

## Server Management

### SSH Access
```bash
ssh -i ~/.ssh/id_rsa ec2-user@<server-ip>
```

### Minecraft Server Commands
```bash
# Check server status
sudo systemctl status minecraft

# View real-time logs
sudo journalctl -u minecraft -f

# Restart server
sudo systemctl restart minecraft

# Stop server gracefully
sudo systemctl stop minecraft

# Start server
sudo systemctl start minecraft
```

### Backup Management
```bash
# Manual backup
sudo -u minecraft /opt/minecraft/scripts/backup.sh

# List backups
aws s3 ls s3://<backup-bucket-name>/

# Restore from backup
sudo /opt/minecraft/scripts/restore.sh world_backup_20241223_120000.tar.gz
```

### Server Configuration
Edit `/opt/minecraft/server/server.properties` and restart:
```bash
sudo systemctl restart minecraft
```

### Log Files
- Setup logs: `/var/log/minecraft-setup.log`
- Backup logs: `/opt/minecraft/logs/backup.log`
- Server logs: `journalctl -u minecraft`

## Monitoring

### CloudWatch Metrics
- CPU utilization
- Memory usage
- Disk usage
- Network I/O
- Custom Minecraft metrics

### Alarms
- High CPU usage (>80%)
- Instance status check failures
- Add SNS topics for notifications

### Log Analysis
```bash
# View setup logs
sudo tail -f /var/log/minecraft-setup.log

# View backup logs
sudo tail -f /opt/minecraft/logs/backup.log

# View server logs
sudo journalctl -u minecraft -f --since "1 hour ago"
```

## Cost Optimization

### Free Tier Management
- Monitor AWS usage in billing dashboard
- Set up billing alerts
- Stop instance when not in use to save bandwidth
- Use S3 Intelligent Tiering for backups

### Resource Optimization
```bash
# Stop instance (saves on bandwidth, keeps EBS)
aws ec2 stop-instances --instance-ids <instance-id>

# Start instance
aws ec2 start-instances --instance-ids <instance-id>
```

## Maintenance

### Regular Tasks
- Monitor AWS free tier usage
- Review CloudWatch logs and metrics
- Test backup/restore procedures
- Update server software
- Review security group rules

### Updates
```bash
# System updates (automated via yum-cron)
sudo yum update -y

# Minecraft server updates
# Download new server.jar and restart service
```

## Troubleshooting

### Common Issues

**Server won't start:**
```bash
sudo journalctl -u minecraft --no-pager
sudo systemctl status minecraft
```

**Can't connect to server:**
- Check security group allows port 25565
- Verify server is running: `sudo systemctl status minecraft`
- Check server logs for errors

**Performance issues:**
- Monitor CloudWatch metrics
- Check memory usage: `free -h`
- Consider reducing view distance in server.properties

**Backup failures:**
```bash
sudo tail -f /opt/minecraft/logs/backup.log
aws s3 ls s3://<backup-bucket>/
```

### Emergency Procedures

**Server crash recovery:**
```bash
# Check system resources
top
df -h
free -h

# Restart server
sudo systemctl restart minecraft

# Restore from backup if needed
sudo /opt/minecraft/scripts/restore.sh <backup-name>
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Note:** This will delete everything including backups. Download important worlds first.

## Production Checklist

- [ ] SSH access restricted to your IP
- [ ] Backup bucket configured and tested
- [ ] CloudWatch monitoring enabled
- [ ] Billing alerts configured
- [ ] Server performance tested
- [ ] Backup/restore procedures tested
- [ ] Security groups reviewed
- [ ] Documentation updated for your team

## Support

For issues:
1. Check CloudWatch logs
2. Review system logs: `journalctl -u minecraft`
3. Verify AWS resource limits
4. Check network connectivity
5. Review security group configurations