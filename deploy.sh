#/bin/bash

apt update && apt upgrade -y
apt install -y vim wget curl net-tools iptables git
git clone https://github.com/d3adwolf/young-yandex-devops
iptables -t filter -A OUTPUT -d 8.8.8.8/32 -j REJECT
curl -fsSL https://get.docker.com/ | sh
usermod -aG docker $USER
