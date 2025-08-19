#!/bin/bash
set -ex

echo "127.0.1.1 $(hostname)" >> /etc/hosts

echo "nameserver 169.254.169.253" > /etc/resolv.conf

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 jool-dkms jool-tools iptables-persistent

modprobe jool

echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

jool instance add "default" --pool6 64:ff9b::/96
systemctl enable jool

PRIMARY_INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

iptables -t nat -A POSTROUTING -o $PRIMARY_INTERFACE -j MASQUERADE

iptables-save > /etc/iptables/rules.v4

cat <<EOF > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders { 2001:4860:4860::8888; 2001:4860:4860::8844; };
    forward only;
    dns64 64:ff9b::/96 {
        clients { any; };
    };
    listen-on { any; };
    listen-on-v6 { any; };
    allow-query { any; };
    recursion yes;
};
EOF

systemctl restart bind9

if grep -q "^AllowTcpForwarding" /etc/ssh/sshd_config; then
  sed -i 's/^AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
else
  echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
fi

if ! grep -q "^GatewayPorts" /etc/ssh/sshd_config; then
  echo "GatewayPorts yes" >> /etc/ssh/sshd_config
fi

systemctl restart sshd

echo "--> Bastion/NAT64 setup on Ubuntu is complete."