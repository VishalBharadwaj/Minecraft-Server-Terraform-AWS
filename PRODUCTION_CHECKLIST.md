# Production Deployment Checklist

## Pre-Deployment

### AWS Account Setup
- [ ] AWS account is less than 12 months old (for free tier)
- [ ] AWS CLI installed and configured
- [ ] Appropriate IAM permissions configured
- [ ] Billing alerts set up

### Local Environment
- [ ] Terraform >= 1.0 installed
- [ ] SSH key pair generated (`ssh-keygen -t rsa -b 4096`)
- [ ] Git repository initialized (optional)

### Configuration
- [ ] `terraform.tfvars` created from example
- [ ] SSH access restricted to your IP in `allowed_ssh_cidr`
- [ ] Server name and settings configured
- [ ] Backup retention period set appropriately

## Security Configuration

### Network Security
- [ ] SSH access restricted to known IPs
- [ ] Minecraft access configured appropriately
- [ ] Security groups follow principle of least privilege
- [ ] VPC flow logs enabled (if monitoring enabled)

### Instance Security
- [ ] IMDSv2 enforced
- [ ] EBS encryption enabled
- [ ] Fail2ban configured for SSH protection
- [ ] Regular security updates enabled

### Access Control
- [ ] IAM roles follow least privilege principle
- [ ] S3 bucket access properly restricted
- [ ] CloudWatch permissions minimal

## Deployment

### Infrastructure Deployment
- [ ] `terraform init` completed successfully
- [ ] `terraform plan` reviewed and approved
- [ ] `terraform apply` completed without errors
- [ ] All outputs displayed correctly

### Server Verification
- [ ] EC2 instance running and accessible
- [ ] Minecraft service started successfully
- [ ] Server responds on port 25565
- [ ] SSH access working with key pair

## Post-Deployment

### Monitoring Setup
- [ ] CloudWatch dashboard accessible
- [ ] Log groups receiving data
- [ ] Alarms configured (CPU, status checks)
- [ ] SNS notifications set up (optional)

### Backup Verification
- [ ] S3 bucket created and accessible
- [ ] Backup script executable and working
- [ ] Daily backup cron job scheduled
- [ ] Restore procedure tested

### Performance Testing
- [ ] Server performance under load tested
- [ ] Memory usage within acceptable limits
- [ ] Network connectivity stable
- [ ] Player connection tested

## Operational Procedures

### Regular Maintenance
- [ ] Backup/restore procedures documented
- [ ] Monitoring dashboard bookmarked
- [ ] Server management commands documented
- [ ] Update procedures established

### Emergency Procedures
- [ ] Incident response plan created
- [ ] Backup restoration tested
- [ ] Contact information documented
- [ ] Escalation procedures defined

## Cost Management

### Free Tier Monitoring
- [ ] AWS billing dashboard configured
- [ ] Usage alerts set up
- [ ] Cost allocation tags applied
- [ ] Resource optimization reviewed

### Ongoing Costs
- [ ] S3 storage costs estimated
- [ ] Data transfer limits understood
- [ ] Instance stop/start procedures documented
- [ ] Cost optimization opportunities identified

## Documentation

### Technical Documentation
- [ ] Architecture diagram created
- [ ] Network topology documented
- [ ] Security configuration documented
- [ ] Operational procedures written

### User Documentation
- [ ] Connection instructions provided
- [ ] Server rules and guidelines created
- [ ] Troubleshooting guide available
- [ ] Contact information shared

## Compliance and Governance

### Security Compliance
- [ ] Security baseline documented
- [ ] Access controls reviewed
- [ ] Audit logging enabled
- [ ] Vulnerability management plan

### Change Management
- [ ] Change approval process defined
- [ ] Version control for infrastructure code
- [ ] Rollback procedures documented
- [ ] Testing procedures established

## Sign-off

### Technical Review
- [ ] Infrastructure architect approval
- [ ] Security team approval
- [ ] Operations team approval
- [ ] Cost management approval

### Business Review
- [ ] Project sponsor approval
- [ ] Budget approval
- [ ] Timeline approval
- [ ] Success criteria defined

---

**Deployment Date:** _______________

**Deployed By:** _______________

**Reviewed By:** _______________

**Production Ready:** [ ] Yes [ ] No

**Notes:**
_________________________________
_________________________________
_________________________________