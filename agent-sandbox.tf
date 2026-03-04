#---------------------------------------------------------------
# Agent Sandbox Installation
#---------------------------------------------------------------

# Apply core manifest
resource "null_resource" "agent_sandbox_core" {
  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name}
      kubectl apply -f ${path.module}/agent-sandbox/manifest.yaml
    EOT
  }

  depends_on = [
    module.eks,
    module.eks.cluster_addons
  ]
}

# Apply extensions manifest
resource "null_resource" "agent_sandbox_extensions" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/agent-sandbox/extensions.yaml"
  }

  depends_on = [null_resource.agent_sandbox_core]
}
