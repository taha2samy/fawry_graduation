#!/bin/bash
echo "Starting SSH tunnel to cluster: ${cluster_name}"
echo "Press Ctrl+C to stop."

ssh -N -L 8443:api.internal.${cluster_name}:443 -i ${private_key_file} ec2-user@${bastion_public_dns}