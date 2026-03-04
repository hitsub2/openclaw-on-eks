# Kata system namespace
resource "kubernetes_namespace_v1" "kata_system" {
  metadata {
    name = local.kata_namespace
    labels = {
      name = local.kata_namespace
    }
  }

  depends_on = [module.eks]
}

# OpenClaw namespace
resource "kubernetes_namespace_v1" "openclaw" {
  metadata {
    name = local.openclaw_namespace
    labels = {
      name = local.openclaw_namespace
    }
  }

  depends_on = [module.eks]
}
