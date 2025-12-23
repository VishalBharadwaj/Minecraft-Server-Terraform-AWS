#!/bin/bash

# Production-level Minecraft server setup script
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Logging setup
exec > >(tee /var/log/minecraft-setup.log)
exec 2>&1

echo "Starting Minecraft server setup at $(date)"

# Update system and install security updates
yum update -y
yum install -y yum-cron
systemctl enable yum-cron
systemctl start yum-cron

# Install required packages
yum install -y \
    java-17-amazon-corretto-headless \
    htop \
    iotop \
    awscli \
    amazon-cloudwatch-agent \
    fail2ban \
    logrotate

# Configure fail2ban for SSH protection
systemctl enable fail2ban
systemctl start fail2ban

# Create minecraft user with restricted permissions
useradd -m -s /bin/bash -U minecraft
usermod -L minecraft  # Lock password login

# Create minecraft directory structure
mkdir -p /opt/minecraft/{server,backups,logs,scripts}
chown -R minecraft:minecraft /opt/minecraft

# Set up proper permissions
chmod 750 /opt/minecraft
chmod 755 /opt/minecraft/server
chmod 700 /opt/minecraft/backups

# Download Minecraft server with verification
cd /opt/minecraft/server
MINECRAFT_VERSION="${minecraft_version}"
SERVER_JAR_URL="https://piston-data.mojang.com/v1/objects/8dd1a28015f51b1803213892b50b7b4fc76e594d/server.jar"

# Download with retry logic
for i in {1..3}; do
    if wget -O server.jar "$SERVER_JAR_URL"; then
        break
    else
        echo "Download attempt $i failed, retrying..."
        sleep 5
    fi
done

# Verify download
if [[ ! -f server.jar ]] || [[ ! -s server.jar ]]; then
    echo "ERROR: Failed to download Minecraft server jar"
    exit 1
fi

# Create production server.properties
cat > server.properties << EOF
#Minecraft server properties - Production Configuration
enable-jmx-monitoring=true
rcon.port=25575
level-seed=
gamemode=survival
enable-command-block=false
enable-query=true
generator-settings={}
enforce-secure-profile=true
level-name=world
motd=${server_name}
query.port=25565
pvp=true
generate-structures=true
max-chained-neighbor-updates=1000000
difficulty=${difficulty}
network-compression-threshold=256
max-tick-time=60000
require-resource-pack=false
use-native-transport=true
max-players=${max_players}
online-mode=true
enable-status=true
allow-flight=false
initial-disabled-packs=
broadcast-rcon-to-ops=true
view-distance=8
server-ip=
resource-pack-prompt=
allow-nether=true
server-port=25565
enable-rcon=true
sync-chunk-writes=true
op-permission-level=4
prevent-proxy-connections=true
hide-online-players=false
resource-pack=
entity-broadcast-range-percentage=100
simulation-distance=8
rcon.password=$(openssl rand -base64 32)
player-idle-timeout=30
debug=false
force-gamemode=false
rate-limit=0
hardcore=false
white-list=false
broadcast-console-to-ops=true
spawn-npcs=true
spawn-animals=true
function-permission-level=2
initial-enabled-packs=vanilla
level-type=minecraft\:normal
text-filtering-config=
spawn-monsters=true
enforce-whitelist=false
spawn-protection=16
resource-pack-sha1=
max-world-size=29999984
EOF

# Accept EULA
echo "eula=true" > eula.txt

# Create JVM optimization script for t3.micro
cat > /opt/minecraft/scripts/start-server.sh << 'EOF'
#!/bin/bash
cd /opt/minecraft/server

# Optimized JVM flags for t3.micro (1GB RAM)
exec java \
    -Xms512M \
    -Xmx896M \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
    -Dusing.aikars.flags=https://mcflags.emc.gs \
    -Daikars.new.flags=true \
    -jar server.jar nogui
EOF

chmod +x /opt/minecraft/scripts/start-server.sh

# Set ownership
chown -R minecraft:minecraft /opt/minecraft

# Create systemd service with proper configuration
cat > /etc/systemd/system/minecraft.service << EOF
[Unit]
Description=Minecraft Server
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=minecraft
Group=minecraft
WorkingDirectory=/opt/minecraft/server
ExecStart=/opt/minecraft/scripts/start-server.sh
ExecStop=/bin/kill -TERM \$MAINPID
TimeoutStopSec=30
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=minecraft

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/minecraft
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Resource limits
LimitNOFILE=4096
MemoryMax=950M

[Install]
WantedBy=multi-user.target
EOF

# Create advanced backup script with S3 integration
cat > /opt/minecraft/scripts/backup.sh << 'EOF'
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/minecraft/backups"
WORLD_DIR="/opt/minecraft/server/world"
S3_BUCKET="${backup_bucket}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="world_backup_$DATE"
RETENTION_DAYS=${backup_retention_days}

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if world exists
if [[ ! -d "$WORLD_DIR" ]]; then
    echo "World directory not found: $WORLD_DIR"
    exit 1
fi

# Create compressed backup
echo "Creating backup: $BACKUP_NAME"
tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C /opt/minecraft/server world

# Upload to S3 if bucket is configured
if [[ -n "$S3_BUCKET" ]]; then
    echo "Uploading backup to S3: s3://$S3_BUCKET/$BACKUP_NAME.tar.gz"
    aws s3 cp "$BACKUP_DIR/$BACKUP_NAME.tar.gz" "s3://$S3_BUCKET/$BACKUP_NAME.tar.gz" \
        --storage-class STANDARD_IA
fi

# Clean up local backups older than 7 days
find "$BACKUP_DIR" -name "world_backup_*.tar.gz" -mtime +7 -delete

# Log backup completion
echo "Backup completed successfully: $BACKUP_NAME"
logger "Minecraft backup completed: $BACKUP_NAME"
EOF

chmod +x /opt/minecraft/scripts/backup.sh
chown minecraft:minecraft /opt/minecraft/scripts/backup.sh

# Create restore script
cat > /opt/minecraft/scripts/restore.sh << 'EOF'
#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <backup_file_or_s3_key>"
    exit 1
fi

BACKUP_SOURCE="$1"
WORLD_DIR="/opt/minecraft/server/world"
TEMP_DIR="/tmp/minecraft_restore_$$"

# Stop minecraft service
systemctl stop minecraft

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Download from S3 if it's an S3 key
if [[ "$BACKUP_SOURCE" =~ ^world_backup_.*\.tar\.gz$ ]]; then
    echo "Downloading backup from S3..."
    aws s3 cp "s3://${backup_bucket}/$BACKUP_SOURCE" "$TEMP_DIR/$BACKUP_SOURCE"
    BACKUP_FILE="$TEMP_DIR/$BACKUP_SOURCE"
else
    BACKUP_FILE="$BACKUP_SOURCE"
fi

# Verify backup file exists
if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Backup current world
if [[ -d "$WORLD_DIR" ]]; then
    echo "Backing up current world..."
    mv "$WORLD_DIR" "$WORLD_DIR.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Extract backup
echo "Restoring world from backup..."
tar -xzf "$BACKUP_FILE" -C /opt/minecraft/server/

# Set permissions
chown -R minecraft:minecraft /opt/minecraft/server/world

# Start minecraft service
systemctl start minecraft

# Cleanup
rm -rf "$TEMP_DIR"

echo "World restored successfully from: $BACKUP_SOURCE"
logger "Minecraft world restored from: $BACKUP_SOURCE"
EOF

chmod +x /opt/minecraft/scripts/restore.sh

# Set up cron jobs for minecraft user
cat > /tmp/minecraft_crontab << EOF
# Minecraft server maintenance tasks
0 2 * * * /opt/minecraft/scripts/backup.sh >> /opt/minecraft/logs/backup.log 2>&1
0 4 * * 0 /usr/bin/find /opt/minecraft/logs -name "*.log" -mtime +30 -delete
*/5 * * * * /usr/bin/systemctl is-active --quiet minecraft || /usr/bin/systemctl start minecraft
EOF

crontab -u minecraft /tmp/minecraft_crontab
rm /tmp/minecraft_crontab

# Configure CloudWatch agent if monitoring is enabled
%{ if enable_monitoring }
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/minecraft-setup.log",
                        "log_group_name": "${log_group_name}",
                        "log_stream_name": "{instance_id}/setup"
                    },
                    {
                        "file_path": "/opt/minecraft/logs/backup.log",
                        "log_group_name": "${log_group_name}",
                        "log_stream_name": "{instance_id}/backup"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "Minecraft/Server",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent
%{ endif }

# Configure log rotation
cat > /etc/logrotate.d/minecraft << EOF
/opt/minecraft/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 minecraft minecraft
    postrotate
        systemctl reload minecraft || true
    endscript
}
EOF

# Create log directory
mkdir -p /opt/minecraft/logs
chown minecraft:minecraft /opt/minecraft/logs

# Enable and start services
systemctl daemon-reload
systemctl enable minecraft
systemctl start minecraft

# Configure automatic security updates
cat > /etc/yum/yum-cron.conf << EOF
[commands]
update_cmd = security
update_messages = yes
download_updates = yes
apply_updates = yes

[emitters]
system_name = minecraft-server
emit_via = stdio

[email]
email_from = root@localhost
email_to = root
email_host = localhost

[groups]
group_list = None
group_package_types = mandatory, default

[base]
debuglevel = -2
mdpolicy = group:main
EOF

# Final security hardening
# Disable unused services
systemctl disable postfix || true
systemctl stop postfix || true

# Set up basic firewall rules (iptables)
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 25565 -j ACCEPT
iptables -A INPUT -j DROP
iptables-save > /etc/sysconfig/iptables

# Enable iptables service
systemctl enable iptables
systemctl start iptables

echo "Minecraft server setup completed successfully at $(date)"
echo "Server will be available at port 25565 once fully started"
echo "Check status with: systemctl status minecraft"
echo "View logs with: journalctl -u minecraft -f"