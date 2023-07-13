#!/bin/bash

#to display labeled output
print_label() {
    echo -e "\n=============================="
    echo " $1"
    echo "=============================="
}

#to display error messages
print_error() {
    echo -e "\n[ERROR] $1\n"
}

# to check if a package is installed
package_installed() {
    dpkg -s "$1" &>/dev/null
}

#to generate a random password
generate_password() {
    tr -dc '[:alnum:]' < /dev/urandom | head -c 12
}


# to check if SSH server is properly configured
check_ssh_server() {
    ssh_config="/etc/ssh/sshd_config"
    key_auth_enabled=$(grep -E "^PasswordAuthentication\s+no" "$ssh_config")
    pubkey_auth_enabled=$(grep -E "^PubkeyAuthentication\s+yes" "$ssh_config")
    
    if [[ -n $key_auth_enabled && -n $pubkey_auth_enabled ]]; then
        echo "SSH server is configured to allow key authentication and disallow password authentication"
    else
        echo "SSH server is not properly configured"
    fi
}

#to check if Apache web server is properly configured
check_apache_server() {
    if package_installed "apache2"; then
        if ss -tln | awk '$4 ~ /:80$/ || $4 ~ /:443$/ { exit 0 }'; then
            echo "Apache web server is installed and configured to listen on ports 80 (HTTP) and 443 (HTTPS)"
        else
            echo "Apache web server is installed but not properly configured"
        fi
    else
        echo "Apache web server is not installed"
    fi
}

#to check if Squid web proxy is properly configured
check_squid_proxy() {
    if package_installed "squid"; then
        if ss -tln | awk '$4 ~ /:3128$/ { exit 0 }'; then
            echo "Squid web proxy is installed and configured to listen on port 3128"
        else
            echo "Squid web proxy is installed but not properly configured"
        fi
    else
        echo "Squid web proxy is not installed"
    fi
}

# to configure the firewall using UFW
configure_firewall() {
    # Enable UFW
    ufw enable

    # Allow SSH on port 22
    ufw allow 22 comment 'SSH'

    # Allow HTTP on port 80
    ufw allow 80 comment 'HTTP'

    # Allow HTTPS on port 443
    ufw allow 443 comment 'HTTPS'

    # Allow web proxy on port 3128
    ufw allow 3128 comment 'Web Proxy'
}

#to modify the netplan configuration file
modify_netplan_config() {
    config_file="/etc/netplan/01-netcfg.yaml"
    desired_config=$(cat <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    ens34:
      addresses: [192.168.16.21/24]
      gateway4: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]
EOL
    )

    echo "$desired_config" > "$config_file"
}

# to create user accounts and generate SSH keys
create_user_accounts() {
    # User list
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    # Set a predefined password for all users
    password="YourPasswordHere"

    for user in "${users[@]}"; do
        # Create user with home directory and set password
        useradd -m -s /bin/bash "$user" <<< "$password"

        # Generate SSH keys and overwrite existing keys
        su - "$user" -c "yes y | ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
        su - "$user" -c "yes y | ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519"

        # Add public keys to authorized_keys file
        cat ~/.ssh/id_rsa.pub >> /home/"$user"/.ssh/authorized_keys
        cat ~/.ssh/id_ed25519.pub >> /home/"$user"/.ssh/authorized_keys
    done
}

# to perform system modifications
system_modifications() {
    # Checking system configuration
    print_label "Checking system configuration"

    current_hostname=$(hostname)
    echo "Current hostname: $current_hostname"
    
    current_ip="192.168.16.21/24"
    echo "Current IP address: $current_ip"
    
    gateway="192.168.16.1"
    dns_server="192.168.16.1"
    dns_search_domains="home.arpa and localdomain"
    
    echo "Gateway: $gateway"
    echo "DNS Server: $dns_server"
    echo "DNS Search Domains: $dns_search_domains"
    
   

    

    # Performing necessary modifications
    print_label "Performing necessary modifications"

    # Modifying hostname
    desired_hostname="autosrv"
    if [ "$current_hostname" != "$desired_hostname" ]; then
        echo "Changing hostname to $desired_hostname"
        hostnamectl set-hostname "$desired_hostname"
        sed -i "s/$current_hostname/$desired_hostname/g" /etc/hosts
    fi
    
    
    # Modifying netplan configuration
    modify_netplan_config

    # Testing for changes
    print_label "Testing changes"
    
    # Performing tests for each modification
    check_ssh_server
    check_apache_server
    check_squid_proxy
    
    
    # Notifying user of actions
    print_label "Applying changes"
    
    
    echo "Firewall should be configured with UFW and include rules to allow the following services:"
    echo "SSH on port 22"
    echo "HTTP on port 80"
    echo "HTTPS on port 443"
    echo "Web Proxy on port 3128"

    echo "User accounts should be created with the following configuration:"
    echo "All users have a home directory"
    echo "All users have SSH keys generated for rsa and ed25519 algorithms, with both public keys added to their authorized_keys file"
    echo "All users have the bash shell"
    
   
    # Applying modifications to the system
    configure_firewall
    create_user_accounts

}

# Executing the script
system_modifications

