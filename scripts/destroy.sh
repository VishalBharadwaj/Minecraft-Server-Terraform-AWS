#!/bin/bash

# Safe destruction script for Minecraft server
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${RED}🗑️  Minecraft Server Destruction${NC}"
echo "=================================="
echo -e "${YELLOW}This will destroy ALL resources including backups!${NC}"
echo ""

# Get current resources
cd "$TERRAFORM_DIR"

if [[ ! -f terraform.tfstate ]] && [[ ! -f .terraform/terraform.tfstate ]]; then
    echo -e "${YELLOW}No Terraform state found. Nothing to destroy.${NC}"
    exit 0
fi

# Show what will be destroyed
echo -e "${YELLOW}Resources that will be destroyed:${NC}"
terraform plan -destroy

echo ""
echo -e "${RED}⚠️  WARNING: This action cannot be undone!${NC}"
echo -e "${RED}⚠️  All server data and backups will be permanently deleted!${NC}"
echo ""

# Backup confirmation
read -p "Have you backed up any important worlds? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Please backup your worlds first, then run this script again.${NC}"
    echo ""
    echo "To backup manually:"
    echo "1. SSH to server: ssh -i ~/.ssh/id_rsa ec2-user@\$(terraform output -raw minecraft_server_ip)"
    echo "2. Run backup: sudo -u minecraft /opt/minecraft/scripts/backup.sh"
    echo "3. Download from S3: aws s3 sync s3://\$(terraform output -raw backup_bucket_name) ./backups/"
    exit 1
fi

# Final confirmation
echo -e "${RED}Type 'destroy' to confirm destruction:${NC}"
read -r confirmation

if [[ "$confirmation" != "destroy" ]]; then
    echo -e "${YELLOW}Destruction cancelled.${NC}"
    exit 0
fi

# Perform destruction
echo -e "${RED}Destroying infrastructure...${NC}"
terraform destroy -auto-approve

echo -e "${GREEN}✅ Infrastructure destroyed successfully${NC}"
echo -e "${YELLOW}Don't forget to clean up any manual backups you may have downloaded${NC}"