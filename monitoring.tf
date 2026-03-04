# Prometheus and Grafana for monitoring

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Prometheus using kube-prometheus-stack
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "65.0.0"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "ebs-sc"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
          retention = "15d"
          resources = {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }
          }
        }
      }
      grafana = {
        enabled = true
        adminPassword = random_password.grafana_admin.result
        persistence = {
          enabled          = true
          storageClassName = "ebs-sc"
          size             = "10Gi"
        }
        service = {
          type = "ClusterIP"
        }
      }
      alertmanager = {
        enabled = false
      }
    })
  ]

  depends_on = [
    kubernetes_storage_class_v1.ebs_csi_default,
    module.eks
  ]
}

resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

output "grafana_admin_password" {
  value     = random_password.grafana_admin.result
  sensitive = true
}

output "grafana_access" {
  value       = "Access via port-forward: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
  description = "Grafana access command (username: admin)"
}

output "grafana_service_name" {
  value = "kube-prometheus-stack-grafana"
  description = "Grafana service name in monitoring namespace"
}
