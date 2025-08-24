#!/bin/bash
kubectl port-forward service/${service_name} -n ${namespace} ${local_port}:${service_port}
