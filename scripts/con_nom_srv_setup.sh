#!/bin/bash
ip_address=$(ip addr show vxlan16 | grep -oP 'inet \K[^/]+' | head -n 1)
if [ -z "$ip_address" ]; then
    echo "Error: ip adress obtention faile verify the interface exist or an ip is set fo this interface"
    exit 1
fi

# IP of all VM vxlan if more SERVERS just add thei ip to this list
# IF YOU WANT MORE VM TO HAVE CONSUL/NOMAD SERVERS ONLY ADD THEIR VXLAN IP THERE
SERVERS=("172.16.16.100" "172.16.16.101" "172.16.16.102")
NBSERV=${#SERVERS[@]}

# get the name of the VM host (only the part before the first string or - (used for test on personal))
HOST="${HOSTNAME%%.*}"

# create a list of the other VMs IP
join_list=""
separator=""
for ip in "${SERVERS[@]}"; do
  # ignore the ip of the current VM
  if [[ "$ip" != "$ip_address" ]]; then
    join_list+="$separator\"$ip\""
    separator=","
  fi
done

file_name="consul.hcl"
# Create the consul config file
cat <<EOF > "$file_name"
# Group name
datacenter = "epee"

# Save the persistent data to /opt/consul. This directory is owned by the "consul" user.
data_dir = "/opt/consul"
node_name = "$HOST"

# Allow clients to connect from any interface
client_addr = "0.0.0.0"

# Advertise the address of the VXLAN interface
advertise_addr = "$ip_address"

# Enable the web interface
ui_config {
  enabled = true
}

# Whether it is running in server mode or not
server = true

# This server expects to be part of $NBSERV servers
# Comment this line if this is not a server.
bootstrap_expect = $NBSERV


addresses {
  # Bind the DNS service to the VXLAN interface
  # We can't bind on 0.0.0.0, because systemd-resolved already listens on 127.0.0.53
  dns = "$ip_address"
}

ports {
  # Make the DNS service listen on port 53, instead of the default 8600
  dns = 53
}

# List of upstream DNS servers to forward queries to
recursors = ["1.1.1.1", "1.0.0.1"]

retry_join = [$join_list] # other servers
EOF

# Check if the consul config was created successfully uncomment cat if you want to debug
if [ -f "$file_name" ]; then
  echo "File '$file_name' created successfully"
  # uncomment nesxt line if you want to see the generated nomad config in terminal
  # cat "$file_name"
else
  echo "Error: Failed to create file '$file_name'."
  exit 1
fi

sudo mv -f ./$file_name /etc/consul.d/$file_name

# enable 
sudo systemctl enable consul
sudo systemctl restart consul


file_name="nomad.hcl"

cat <<EOF > "$file_name"
# Group name
datacenter = "epee"

# Node name
name = "$HOST"

# Save the persistent data to /opt/nomad
data_dir = "/opt/nomad"

# Allow clients to connect from any interface
bind_addr = "0.0.0.0"

advertise {
  # We explicitely advertise the IP on the vxlan interface
  http = "$ip_address"
  rpc = "$ip_address"
  serf = "$ip_address"
}

# This node is a server, and expects to be part of $NBSERV SERVERS 
server {
  enabled = true
  bootstrap_expect = $NBSERV
  server_join {
    retry_join = [$join_list]
  }
}

# This node is not running jobs
client {
  enabled = false
}

# Connect to the local Consul agent
consul {
  address = "127.0.0.1:8500"
}

# Show the UI and link to the Consul UI
ui {
  enabled = true

  consul {
    ui_url = "https://epee.consul.100do.se/ui"
  }
}
EOF

# Check if the nomad config was created successfully uncomment cat if you want to debug
if [ -f "$file_name" ]; then
  echo "File '$file_name' created successfully"
  # uncomment nesxt line if you want to see the generated nomad config in terminal
  # cat "$file_name"
else
  echo "Error: Failed to create file '$file_name'."
  exit 1
fi

sudo mv -f ./$file_name /etc/nomad.d/$file_name

sudo systemctl enable nomad
sudo systemctl restart nomad


# if you want to see if it worked uncomment this

# sleep 1
# echo "consul members"
# consul members
# echo "nomad node status"
# nomad node status | cat
# echo "nomad server members"
# nomad server members
# echo "nomad raft peers"
# nomad operator raft list-peers
# echo "status consul"
# sudo systemctl status consul --no-pager
# echo "status nomad"
# sudo systemctl status nomad --no-pager

# clean the vm by removing the now useless script
rm "$0"

exit 0