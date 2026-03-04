# Deploy Kata Containers using Helm
resource "helm_release" "kata_deploy" {
  namespace        = local.kata_namespace
  name             = "kata-deploy"
  repository       = "oci://ghcr.io/kata-containers/kata-deploy-charts"
  chart            = "kata-deploy"
  version          = "3.27.0"
  create_namespace = false
  wait             = false

  values = [
    <<-EOT
    nodeSelector:
      workload-type: kata
    tolerations:
      - key: kata
        operator: Equal
        value: "true"
        effect: NoSchedule
    EOT
  ]

  depends_on = [
    kubernetes_namespace_v1.kata_system,
    kubectl_manifest.kata_node_pool
  ]
}
