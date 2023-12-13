#!/bin/bash

# WireGuard setup script
# written by phind

# Server configuration
SERVER_IP="10.0.0.1"
SERVER_PORT="51820"

# Function to set up the server
setup_server() {
 umask 077
 wg genkey | tee server_privatekey | wg pubkey > server_publickey
 SERVER_PRIVATE_KEY=$(cat server_privatekey)
 SERVER_PUBLIC_KEY=$(cat server_publickey)
 echo "[Interface]" > /etc/wireguard/wg0.conf
 echo "PrivateKey = $SERVER_PRIVATE_KEY" >> /etc/wireguard/wg0.conf
 echo "Address = $SERVER_IP/24" >> /etc/wireguard/wg0.conf
 echo "ListenPort = $SERVER_PORT" >> /etc/wireguard/wg0.conf
 echo "" >> /etc/wireguard/wg0.conf
 wg-quick up wg0
 ngrok tcp $SERVER_PORT &
 sleep 10
 SERVER_NGROK_IP=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
 SERVER_NGROK_IP=${SERVER_NGROK_IP#*//}
 SERVER_NGROK_IP=${SERVER_NGROK_IP%%/*}
 echo "Server ngrok IP: $SERVER_NGROK_IP"
}

# Function to add a new client
add_client() {
 umask 077
 wg genkey | tee client_privatekey | wg pubkey > client_publickey
 CLIENT_PRIVATE_KEY=$(cat client_privatekey)
 CLIENT_PUBLIC_KEY=$(cat client_publickey)
 CLIENT_IP="10.0.0.2"
 echo "[Peer]" >> /etc/wireguard/wg0.conf
 echo "PublicKey = $CLIENT_PUBLIC_KEY" >> /etc/wireguard/wg0.conf
 echo "AllowedIPs = $CLIENT_IP/32" >> /etc/wireguard/wg0.conf
 wg-quick up wg0
 echo "Client Configuration:"
 echo "[Interface]"
 echo "PrivateKey = $CLIENT_PRIVATE_KEY"
 echo "Address = $CLIENT_IP/24"
 echo "[Peer]"
 echo "PublicKey = $SERVER_PUBLIC_KEY"
 echo "Endpoint = $SERVER_NGROK_IP:$SERVER_PORT"
 echo "AllowedIPs = 0.0.0.0/0"
 echo "PersistentKeepalive = 30"
}

# Function to stop the server
stop_server() {
 wg-quick down wg0
 pkill ngrok
}

# Function to show the current connections
show_connections() {
 wg show
}

# Main script
case $1 in
 --setup)
   setup_server
   ;;
 --addnewclient)
   add_client
   ;;
 --stop)
   stop_server
   ;;
 --showcurrentconnection)
   show_connections
   ;;
 *)
   echo "Usage: $0 {--setup|--addnewclient|--stop|--showcurrentconnection}"
   exit 1
   ;;
esac
