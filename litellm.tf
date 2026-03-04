resource "kubernetes_namespace_v1" "litellm" {
  metadata {
    name = "litellm"
  }
}

resource "kubernetes_service_account_v1" "litellm" {
  metadata {
    name      = "litellm"
    namespace = kubernetes_namespace_v1.litellm.metadata[0].name
  }
}

# Create IAM role for Pod Identity
resource "aws_iam_role" "litellm_pod_identity" {
  name = "${module.eks.cluster_name}-litellm-pod-identity"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "litellm_bedrock" {
  role       = aws_iam_role.litellm_pod_identity.name
  policy_arn = aws_iam_policy.openclaw_bedrock.arn
}

resource "aws_eks_pod_identity_association" "litellm" {
  cluster_name    = module.eks.cluster_name
  namespace       = kubernetes_namespace_v1.litellm.metadata[0].name
  service_account = kubernetes_service_account_v1.litellm.metadata[0].name
  role_arn        = aws_iam_role.litellm_pod_identity.arn
}

resource "helm_release" "litellm" {
  name      = "litellm"
  chart     = "oci://ghcr.io/berriai/litellm-helm"
  namespace = kubernetes_namespace_v1.litellm.metadata[0].name

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account_v1.litellm.metadata[0].name
  }

  # Use latest stable image
  set {
    name  = "image.tag"
    value = "main-latest"
  }

  # Database
  set {
    name  = "db.deployStandalone"
    value = "true"
  }

  set_sensitive {
    name  = "postgresql.auth.password"
    value = random_password.litellm_db.result
  }

  set_sensitive {
    name  = "postgresql.auth.postgres-password"
    value = random_password.litellm_db_admin.result
  }

  # Bedrock model - Claude Opus 4.6 (cross-region inference profile)
  set {
    name  = "proxy_config.model_list[0].model_name"
    value = "claude-opus-4-6"
  }

  set {
    name  = "proxy_config.model_list[0].litellm_params.model"
    value = "bedrock/us.anthropic.claude-opus-4-6-v1"
  }

  set {
    name  = "proxy_config.model_list[0].litellm_params.aws_region_name"
    value = "us-east-1"
  }

  # Enable Prometheus metrics
  set {
    name  = "proxy_config.litellm_settings.callbacks[0]"
    value = "prometheus"
  }

  # Monitoring - disable built-in ServiceMonitor, we'll create our own
  set {
    name  = "serviceMonitor.enabled"
    value = "false"
  }

  depends_on = [module.eks, helm_release.kube_prometheus_stack]
}

# Custom ServiceMonitor with correct path
resource "kubectl_manifest" "litellm_servicemonitor" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "litellm"
      namespace = kubernetes_namespace_v1.litellm.metadata[0].name
      labels = {
        release = "kube-prometheus-stack"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "litellm"
          "app.kubernetes.io/instance" = "litellm"
        }
      }
      endpoints = [{
        port           = "http"
        path           = "/metrics"
        interval       = "30s"
        scrapeTimeout  = "10s"
      }]
    }
  })

  depends_on = [
    helm_release.litellm,
    helm_release.kube_prometheus_stack,
    module.eks.cluster_addons
  ]
}

resource "random_password" "litellm_db" {
  length  = 32
  special = true
}

resource "random_password" "litellm_db_admin" {
  length  = 32
  special = true
}


output "litellm_db_password" {
  value     = random_password.litellm_db.result
  sensitive = true
}

output "litellm_db_admin_password" {
  value     = random_password.litellm_db_admin.result
  sensitive = true
}
