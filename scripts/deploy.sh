#!/bin/bash

# Production deployment script for Minecraft server
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TFVARS_FILE="terraform.tfvars"

echo -e "${GREEN}🎮 Minecraft Server Production Deployment${NC}"
echo "=================================================="

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform is not installed${NC}"
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed${NC}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured${NC}"
        exit 1
    fi
    
    # Check if SSH key exists
    if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
        echo -e "${YELLOW}⚠️  SSH key not found. Generating new key...${NC}"
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Validate terraform configuration
validate_config() {
    echo -e "${YELLOW}Validating Terraform configuration...${NC}"
    
    cd "$TERRAFORM_DIR"
    
    if [[ ! -f "$TFVARS_FILE" ]]; then
        echo -e "${YELLOW}⚠️  terraform.tfvars not found. Creating from example...${NC}"
        cp terraform.tfvars.example terraform.tfvars
        echo -e "${RED}❌ Please edit terraform.tfvars with your configuration${NC}"
        exit 1
    fi
    
    terraform fmt -check=true -diff=true
    terraform validate
    
    echo -e "${GREEN}✅ Configuration validation passed${NC}"
}

# Security check
security_check() {
    echo -e "${YELLOW}Performing security checks...${NC}"
    
    # Check if SSH access is restricted
    if grep -q "allowed_ssh_cidr.*0.0.0.0/0" "$TFVARS_FILE"; then
        echo -e "${RED}⚠️  WARNING: SSH access is open to the world (0.0.0.0/0)${NC}"
        echo -e "${YELLOW}Consider restricting SSH access to your IP address${NC}"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✅ Security check completed${NC}"
}

# Deploy infrastructure
deploy() {
    echo -e "${YELLOW}Deploying infrastructure...${NC}"
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    terraform init
    
    # Create execution plan
    terraform plan -out=tfplan
    
    # Show plan summary
    echo -e "${YELLOW}Deployment plan created. Review the changes above.${NC}"
    read -p "Apply these changes? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Apply changes
        terraform apply tfplan
        
        # Clean up plan file
        rm -f tfplan
        
        echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
        
        # Show connection information
        show_connection_info
    else
        echo -e "${YELLOW}Deployment cancelled${NC}"
        rm -f tfplan
        exit 0
    fi
}

# Show connection information
show_connection_info() {
    echo -e "${GREEN}🎮 Minecraft Server Information${NC}"
    echo "=================================="
    
    SERVER_IP=$(terraform output -raw minecraft_server_ip)
    
    echo -e "Server IP: ${GREEN}$SERVER_IP${NC}"
    echo -e "Minecraft Port: ${GREEN}25565${NC}"
    echo -e "Connection: ${GREEN}$SERVER_IP:25565${NC}"
    echo ""
    echo -e "SSH Access: ${YELLOW}$(terraform output -raw ssh_connection_command)${NC}"
    echo ""
    echo -e "${YELLOW}Server is starting up... This may take 5-10 minutes.${NC}"
    echo -e "${YELLOW}Check server status with: ssh -i ~/.ssh/id_rsa ec2-user@$SERVER_IP 'sudo systemctl status minecraft'${NC}"
}

# Main execution
main() {
    check_prerequisites
    validate_config
    security_check
    deploy
}

# Run main function
main "$@"