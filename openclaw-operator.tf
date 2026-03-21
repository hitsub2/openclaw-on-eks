# OpenClaw Operator
resource "helm_release" "openclaw_operator" {
  name             = "openclaw-operator"
  repository       = "oci://ghcr.io/openclaw-rocks/charts"
  chart            = "openclaw-operator"
  version          = "0.22.2"
  namespace        = "openclaw-operator-system"
  create_namespace = true

  set {
    name  = "image.repository"
    value = "public.ecr.aws/t6v6o5d5/kube-prometheus"
  }

  set {
    name  = "image.tag"
    value = "openclaw-operator-v0.22.2"
  }

  depends_on = [module.eks]
}
