#!/bin/bash

# Variables
PIHOLE_CONFIG_DIR="/opt/pihole/etc-pihole"
DNSMASQ_CONFIG_DIR="/opt/pihole/etc-dnsmasq.d"
DATA_DIR="/opt/pihole/data" # Directory for additional data storage
QUADLET_DIR="/etc/containers/systemd"
SYSTEMD_OUTPUT_DIR="/etc/systemd/system/"
TIMEZONE="America/Tampa"  # Replace with your timezone
WEBPASSWORD="YourSecurePassword"  # Replace with your desired password

# Function to handle errors
error_exit() {
    echo "Error: $1"
    exit 1
}

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root. Use sudo or run as root."
fi

# Create persistent storage directories
echo "Creating persistent storage directories..."
mkdir -p "$PIHOLE_CONFIG_DIR" || error_exit "Failed to create $PIHOLE_CONFIG_DIR"
mkdir -p "$DNSMASQ_CONFIG_DIR" || error_exit "Failed to create $DNSMASQ_CONFIG_DIR"
mkdir -p "$DATA_DIR" || error_exit "Failed to create $DATA_DIR"

# Create Quadlet directory
echo "Creating Quadlet directory..."
mkdir -p "$QUADLET_DIR" || error_exit "Failed to create $QUADLET_DIR"

# Write Quadlet configuration
echo "Writing Quadlet configuration file..."
cat << EOF > "$QUADLET_DIR/pihole.container"
[Container]
Image=docker.io/pihole/pihole:latest
Environment=TZ=$TIMEZONE
Environment=WEBPASSWORD=$WEBPASSWORD
Volume=$PIHOLE_CONFIG_DIR:/etc/pihole:Z
Volume=$DNSMASQ_CONFIG_DIR:/etc/dnsmasq.d:Z
Volume=$DATA_DIR:/data:Z

PublishPort=53:53/tcp
PublishPort=53:53/udp
PublishPort=80:80/tcp
AddCapability=NET_ADMIN
EOF

# Configure firewall rules
echo "Configuring firewall rules..."
firewall-cmd --permanent --add-port=53/tcp || error_exit "Failed to open TCP port 53."
firewall-cmd --permanent --add-port=53/udp || error_exit "Failed to open UDP port 53."
firewall-cmd --permanent --add-port=80/tcp || error_exit "Failed to open TCP port 80."
firewall-cmd --reload || error_exit "Failed to reload firewall rules."

# Generate systemd service file from Quadlet configuration
echo "Generating systemd service file from Quadlet configuration..."
/usr/lib/podman/quadlet -dryrun -v > "$SYSTEMD_OUTPUT_DIR/container-pihole.service" || error_exit "Failed to generate systemd service file."

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload || error_exit "Failed to reload systemd daemon"

# Enable and start the Pi-hole service
echo "Enabling and starting Pi-hole service..."
systemctl enable container-pihole.service || error_exit "Failed to enable Pi-hole service"
systemctl start container-pihole.service || error_exit "Failed to start Pi-hole service"

# Check status of the service
echo "Checking Pi-hole service status..."
systemctl status container-pihole.service --no-pager

echo "Pi-hole installation completed successfully."
