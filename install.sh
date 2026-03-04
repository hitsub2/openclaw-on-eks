#!/bin/bash

set -e

# Default values
REGION="${AWS_REGION:-us-west-2}"
CLUSTER_NAME="${CLUSTER_NAME:-openclaw-kata-eks}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --region)
      REGION="$2"
      shift 2
      ;;
    --cluster-name)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --region REGION          AWS region (default: us-west-2)"
      echo "  --cluster-name NAME      EKS cluster name (default: openclaw-kata-eks)"
      echo "  --help                   Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0 --region ap-southeast-1"
      echo "  $0 --region us-east-1 --cluster-name my-openclaw"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run '$0 --help' for usage information"
      exit 1
      ;;
  esac
done

echo "Installing OpenClaw on EKS with Kata Containers and LiteLLM..."
echo "Region: $REGION"
echo "Cluster Name: $CLUSTER_NAME"
echo ""

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo "aws cli is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "terraform is required but not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm is required but not installed. Aborting." >&2; exit 1; }

echo "✓ Prerequisites check passed"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan
echo "Planning infrastructure..."
terraform plan -var="region=$REGION" -var="name=$CLUSTER_NAME"

# Apply
echo "Deploying infrastructure..."
read -p "Do you want to proceed with deployment? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

terraform apply -auto-approve -var="region=$REGION" -var="name=$CLUSTER_NAME"

# Configure kubectl
echo "Configuring kubectl..."
aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo ""
echo "=========================================="
echo "Deployment completed successfully!"
echo "=========================================="
echo ""
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo ""
echo "Next steps:"
echo "1. Generate LiteLLM API key:"
echo "   MASTER_KEY=\$(kubectl get secret litellm-masterkey -n litellm -o jsonpath='{.data.masterkey}' | base64 -d)"
echo "   kubectl run -n litellm gen-key --rm -i --restart=Never --image=curlimages/curl -- \\"
echo "     curl -s -X POST http://litellm:4000/key/generate \\"
echo "     -H \"Authorization: Bearer \$MASTER_KEY\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"models\": [\"claude-opus-4-6\"], \"duration\": \"30d\"}'"
echo ""
echo "2. Deploy OpenClaw sandbox:"
echo "   cd examples"
echo "   kubectl apply -f openclaw-slack-sandbox.yaml"
echo ""
echo "3. Check status:"
echo "   kubectl get sandbox -A"
echo "   kubectl get pods -A"
echo ""
