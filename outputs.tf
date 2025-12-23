output "minecraft_server_ip" {
  description = "Public IP address of the Minecraft server"
  value       = aws_eip.minecraft_eip.public_ip
}

output "minecraft_server_dns" {
  description = "Public DNS name of the Minecraft server"
  value       = aws_instance.minecraft_server.public_dns
}

output "ssh_connection_command" {
  description = "SSH command to connect to the server"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_eip.minecraft_eip.public_ip}"
}

output "minecraft_connection_info" {
  description = "Information for connecting to the Minecraft server"
  value = {
    server_address = aws_eip.minecraft_eip.public_ip
    port          = "25565"
    connection    = "${aws_eip.minecraft_eip.public_ip}:25565"
  }
}

output "backup_bucket_name" {
  description = "S3 bucket name for backups"
  value       = aws_s3_bucket.minecraft_backups.bucket
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.minecraft_server.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.minecraft_sg.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = var.enable_monitoring ? aws_cloudwatch_log_group.minecraft_logs[0].name : "Monitoring disabled"
}

output "management_commands" {
  description = "Useful management commands"
  value = {
    check_status    = "systemctl status minecraft"
    view_logs      = "journalctl -u minecraft -f"
    restart_server = "sudo systemctl restart minecraft"
    backup_now     = "sudo -u minecraft /opt/minecraft/scripts/backup.sh"
    restore_backup = "sudo /opt/minecraft/scripts/restore.sh <backup_name>"
  }
}