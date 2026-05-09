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
    image:
      reference: public.ecr.aws/t6v6o5d5/kube-prometheus
      tag: kata-deploy-3.27.0
    nodeSelector:
      workload-type: kata
    tolerations:
      - key: kata
        operator: Equal
        value: "true"
        effect: NoSchedule
    shims:
      disableAll: true
      qemu:
        enabled: true
      clh:
        enabled: true
    customRuntimes:
      enabled: true
      runtimes:
        qemu-static:
          baseConfig: "qemu"
          dropIn: |
            [runtime]
            static_sandbox_resource_mgmt = true
          containerd:
            snapshotter: ""
          crio:
            pullType: ""
          runtimeClass: |
            kind: RuntimeClass
            apiVersion: node.k8s.io/v1
            metadata:
              name: kata-qemu-static
              labels:
                app.kubernetes.io/managed-by: kata-deploy
            handler: kata-qemu-static
            overhead:
              podFixed:
                memory: "160Mi"
                cpu: "250m"
            scheduling:
              nodeSelector:
                katacontainers.io/kata-runtime: "true"
    EOT
  ]

  depends_on = [
    kubernetes_namespace_v1.kata_system,
    kubectl_manifest.kata_node_pool
  ]
}
