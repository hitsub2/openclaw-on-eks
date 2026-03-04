#!/bin/bash

set -e

echo "Cleaning up OpenClaw Kata EKS cluster..."

# Delete Kata test workloads
kubectl delete -f examples/ --ignore-not-found=true || true

# Wait for pods to terminate
echo "Waiting for pods to terminate..."
sleep 30

# Destroy Terraform resources
terraform destroy -auto-approve

echo "Cleanup complete!"
