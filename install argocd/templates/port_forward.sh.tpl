#!/bin/bash
kubectl --kubeconfig="${kubeconfig_path}" port-forward service/${service_name} -n ${namespace} ${local_port}:${service_port}
