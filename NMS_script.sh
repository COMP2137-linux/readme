#!/bin/bash
# NMS_script.sh - Network Management Script

# Check for sudo access
echo "Checking for sudo"
[ "$(id -u)" -eq 0 ] && echo "Please do not run this script using sudo. It will use sudo when necessary." && exit 1

# Install required packages
echo "Updating package lists"
sudo apt-get update

echo "Installing necessary packages: lxd, rsyslog, apache2, ufw"
sudo apt-get install -y lxd rsyslog apache2 ufw

# Initialize LXD if not already initialized
echo "Initializing LXD"
if ! lxd init --auto &> /dev/null; then
    sudo lxd init --auto
fi

# Create the LAN and MGMT network profiles if they don't exist
echo "Creating LXD network profiles 'lan' and 'mgmt' if they don't exist"
if ! lxc network show lan &> /dev/null; then
    sudo lxc network create lan ipv4.address=192.168.1.1/24 ipv4.nat=true
fi

if ! lxc network show mgmt &> /dev/null; then
    sudo lxc network create mgmt ipv4.address=172.16.1.1/24 ipv4.nat=true
fi

# Function to create containers
function create_container {
    name="$1"
    profile="$2"
    ip="$3"

    echo "Creating container '$name' with profile '$profile' and IP '$ip'"
    sudo lxc launch images:ubuntu/22/amd64 "$name" --profile default --profile "$profile"
    sudo lxc exec "$name" -- sh -c "ip addr add $ip dev eth0"
    sudo lxc exec "$name" -- sh -c "ip route add default via $(echo "$ip" | cut -d'/' -f1) dev eth0"
}

# Create the required containers
create_container "loghost" "lan" "192.168.1.2/24"
create_container "webhost" "lan" "192.168.1.3/24"

# Install and configure rsyslog on loghost
echo "Installing and configuring rsyslog on loghost"
sudo lxc exec loghost -- sh -c "apt-get update"
sudo lxc exec loghost -- sh -c "apt-get install -y rsyslog"
sudo lxc exec loghost -- sh -c "sed -i 's/#module(load=\"imudp\")/module(load=\"imudp\")/' /etc/rsyslog.conf"
sudo lxc exec loghost -- sh -c "sed -i 's/#input(type=\"imudp\"/input(type=\"imudp\"/' /etc/rsyslog.conf"
sudo lxc exec loghost -- sh -c "sed -i 's/#udpserv' /udpserv/' /etc/rsyslog.conf"
sudo lxc exec loghost -- sh -c "echo '*.* @@172.16.1.2' >> /etc/rsyslog.conf"
sudo lxc exec loghost -- sh -c "service rsyslog restart"

# Install and configure Apache web server on webhost
echo "Installing and configuring Apache web server on webhost"
sudo lxc exec webhost -- sh -c "apt-get update"
sudo lxc exec webhost -- sh -c "apt-get install -y apache2"
sudo lxc exec webhost -- sh -c "ufw allow 80/tcp"
sudo lxc exec webhost -- sh -c "echo '<html><body><h1>Welcome to the Webhost!</h1></body></html>' > /var/www/html/index.html"
sudo lxc exec webhost -- sh -c "service apache2 restart"

# Display container information
echo "Container information:"
lxc list

echo "Setup completed successfully."
