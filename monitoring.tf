# Prometheus and Grafana for monitoring

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Prometheus using kube-prometheus-stack
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "oci://public.ecr.aws/t6v6o5d5/helm"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "65.0.0"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          image = {
            registry = "public.ecr.aws"
            repository = "bitnami/prometheus"
            tag = "2.54.1"
          }
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
      global = {
        imageRegistry = "public.ecr.aws"
      }
      prometheusOperator = {
        image = {
          registry = "public.ecr.aws"
          repository = "bitnami/prometheus-operator"
          tag = "0.77.1"
        }
        prometheusConfigReloader = {
          image = {
            registry = "public.ecr.aws"
            repository = "kubecost/prometheus-config-reloader"
            tag = "v0.77.1"
          }
        }
        admissionWebhooks = {
          patch = {
            image = {
              registry = "public.ecr.aws"
              repository = "t6v6o5d5/kube-prometheus"
              tag = "kube-webhook-certgen-v20221220"
            }
          }
        }
      }
      kube-state-metrics = {
        image = {
          registry = "public.ecr.aws"
          repository = "bitnami/kube-state-metrics"
          tag = "2.13.0"
        }
      }
      prometheus-node-exporter = {
        image = {
          registry = "public.ecr.aws"
          repository = "bitnami/node-exporter"
          tag = "1.8.2"
        }
      }
      grafana = {
        enabled = false
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

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "oci://public.ecr.aws/t6v6o5d5/helm"
  chart      = "grafana"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  values = [
    yamlencode({
      image = {
        registry = "public.ecr.aws"
        repository = "t6v6o5d5/kube-prometheus"
        tag = "grafana-11.2.1"
      }
      initChownData = {
        enabled = false
      }
      sidecar = {
        image = {
          registry = "public.ecr.aws"
          repository = "t6v6o5d5/kube-prometheus"
          tag = "k8s-sidecar-1.27.4"
        }
        dashboards = {
          enabled = true
        }
        datasources = {
          enabled = true
        }
      }
      adminPassword = random_password.grafana_admin.result
      persistence = {
        enabled          = true
        storageClassName = "ebs-sc"
        size             = "10Gi"
      }
      service = {
        type = "ClusterIP"
      }
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [{
            name      = "Prometheus"
            type      = "prometheus"
            url       = "http://kube-prometheus-stack-prometheus.monitoring:9090"
            isDefault = true
          }]
        }
      }
    })
  ]

  depends_on = [
    helm_release.kube_prometheus_stack,
    kubernetes_storage_class_v1.ebs_csi_default
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
