#!/bin/bash
set -ex


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