#!/bin/bash
GROUP=16
VXLAN="vxlan$GROUP"
FLOATING_IP="172.16.${GROUP}.110/24"
ROUTER_ID="51"
AUTH_MDP="EfGhVACWu/ZBKy88uVM7WIp/KJlnVCkCyLrURcwVDbo="
CONFIG_PATH="/etc/keepalived/keepalived.conf"
SUBNET="172.16.${GROUP}.0/24"

# Get the last octet of the IP on vxlan16
IP=$(ip addr show vxlan16 | grep -oP 'inet \K[^/]+' | head -n 1)
LAST_OCTET=$(echo "$IP" | awk -F. '{print $4}')

if [ -z "$LAST_OCTET" ]; then
  echo "Error ? couldn't get the last byte of the vxlan16 ip address"
  exit 1
fi

# initially arcko get the priority, since it's l lowest ip we put higher priority on lower ip adresses
PRIORITY=$((256 - LAST_OCTET))

# install keepalive and iproute 2 and iptables to filter vrrp traffic
sudo apt update && sudo apt install -y keepalived iproute2 iptables

# set up the keepalived config file
sudo tee "$CONFIG_PATH" > /dev/null <<EOF
vrrp_instance VI_1 {
    state BACKUP
    interface $VXLAN
    virtual_router_id $ROUTER_ID
    priority $PRIORITY
    advert_int 1
    authentication {
        auth_type AH
        auth_pass $AUTH_MDP
    }
    virtual_ipaddress {
        $FLOATING_IP
    }
}
EOF

# allow vrrp traffic from within the subnet
sudo iptables -A INPUT -i "$VXLAN" -s "$SUBNET" -d 224.0.0.18 -p vrrp -j ACCEPT
# drop vrrrp traffic from anything outside the subnet
sudo iptables -A INPUT -d 224.0.0.18 -p vrrp -j DROP

# save the above rules so they are restored on reboot 
sudo DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent
sudo netfilter-persistent save

# start keepalived
sudo systemctl enable keepalived
sudo systemctl restart keepalived

#clean the vm by removing the file
rm "$0"

# uncomment these lines to check if the keepalived work after the script
sleep 3
sudo systemctl status keepalived --no-pager
ip addr show vxlan16 | grep 172.16.16.110 # this one only work if the vm is the MASTER
# sudo journalctl -u keepalived -f

echo "keepalived setup finished"
exit 0