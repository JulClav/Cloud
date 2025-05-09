# Get the last octet of the IP on vxlan16
IP=$(ip addr show vxlan16 | grep -oP 'inet \K[^/]+' | head -n 1)
LAST_OCTET=$(echo "$IP" | awk -F. '{print $4}')
echo "$LAST_OCTET"

# initially arcko get the priority
PRIORITY=$((256 - LAST_OCTET))
echo "$PRIORITY"