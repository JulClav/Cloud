# Check if the IP was successfully obtained
ip_address="172.16.16.101"

if [ -z "$ip_address" ]; then
    echo "Error: ip address obtention failed. Verify the interface exists or an ip is set for this interface."
    exit 1
fi

# IP of all VM vxlan
servers=("172.16.16.100" "172.16.16.101" "172.16.16.102")

formatted_servers=""
separator=""

for ip in "${servers[@]}"; do
  # Check if the current IP is NOT the local IP address
  if [[ "$ip" != "$ip_address" ]]; then
    # If it's not the local IP, add it to the formatted string
    formatted_servers+="$separator\"$ip\""
    # Set the separator for the next IP
    separator=","
  fi
done

echo "$formatted_servers"


servers=("172.16.16.100" "172.16.16.101" "172.16.16.102")
nb_serv=${#servers[@]}

echo "$nb_serv"

