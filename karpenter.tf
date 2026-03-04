module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.24"

  cluster_name          = module.eks.cluster_name
  enable_v1_permissions = true

  enable_pod_identity             = true
  create_pod_identity_association = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags

  depends_on = [module.eks]
}

# Add missing IAM permissions for Karpenter controller
resource "aws_iam_role_policy" "karpenter_list_instance_profiles" {
  name = "KarpenterListInstanceProfiles"
  role = module.karpenter.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:ListInstanceProfiles"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "helm_release" "karpenter" {
  namespace  = "kube-system"
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.7.4"
  wait       = false

  values = [
    <<-EOT
    serviceAccount:
      name: ${module.karpenter.service_account}
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - key: karpenter.sh/controller
        operator: Exists
        effect: NoSchedule
    EOT
  ]

  lifecycle {
    ignore_changes = [repository_password]
  }

  depends_on = [module.karpenter]
}

# Kata Containers NodeClass for bare metal instances
resource "kubectl_manifest" "kata_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: kata-bare-metal
    spec:
      amiFamily: AL2023
      amiSelectorTerms:
        - alias: al2023@latest
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 200Gi
            volumeType: gp3
            encrypted: true
            deleteOnTermination: true
      userData: |
        MIME-Version: 1.0
        Content-Type: multipart/mixed; boundary="BOUNDARY"

        --BOUNDARY
        Content-Type: text/x-shellscript; charset="us-ascii"

        #!/bin/bash
        set -ex

        # Install required packages
        dnf install -y mdadm lvm2 device-mapper

        # Find NVMe devices
        nvme_disks=()
        for dev in /dev/nvme*n1; do
            if [ -b "$dev" ]; then
                if ! lsblk -n -o MOUNTPOINT "$dev" | grep -q . && \
                   ! lsblk -n "$dev" | grep -q part && \
                   ! fuser "$dev" 2>/dev/null && \
                   ! mdadm --examine "$dev" 2>/dev/null | grep -q "Magic"; then
                    nvme_disks+=("$dev")
                fi
            fi
        done

        # Setup RAID0 and LVM for containerd devicemapper
        if [ $${#nvme_disks[@]} -gt 1 ]; then
            echo "Creating RAID0 with $${#nvme_disks[@]} devices: $${nvme_disks[@]}"
            mdadm --create --verbose /dev/md0 --level=0 --raid-devices=$${#nvme_disks[@]} $${nvme_disks[@]} --force --assume-clean
            sleep 5
            pvcreate /dev/md0
            vgcreate vg_raid0 /dev/md0
            lvcreate -n thinpool_data vg_raid0 -l 90%VG
        elif [ $${#nvme_disks[@]} -eq 1 ]; then
            echo "Using single NVMe device: $${nvme_disks[0]}"
            pvcreate $${nvme_disks[0]}
            vgcreate vg_raid0 $${nvme_disks[0]}
            lvcreate -n thinpool_data vg_raid0 -l 90%VG
        fi
        
        echo "RAID0 setup complete"

        --BOUNDARY
        Content-Type: application/node.eks.aws

        apiVersion: node.eks.aws/v1alpha1
        kind: NodeConfig
        spec:
          cluster:
            name: ${module.eks.cluster_name}
            apiServerEndpoint: ${module.eks.cluster_endpoint}
            certificateAuthority: ${module.eks.cluster_certificate_authority_data}
            cidr: ${module.vpc.vpc_cidr_block}

        --BOUNDARY--
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        Name: kata-bare-metal-node
        KarpenterNodeClass: kata-bare-metal
  YAML

  depends_on = [helm_release.karpenter]
}

# Kata NodePool for bare metal instances
resource "kubectl_manifest" "kata_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: kata-bare-metal
    spec:
      template:
        metadata:
          labels:
            workload-type: kata
            instance-type: bare-metal
            katacontainers.io/kata-runtime: "true"
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: kata-bare-metal
          taints:
            - key: kata
              value: "true"
              effect: NoSchedule
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: node.kubernetes.io/instance-type
              operator: In
              values: ${jsonencode(var.kata_instance_types)}
      limits:
        cpu: "1000"
        memory: 1000Gi
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 1m
  YAML

  depends_on = [kubectl_manifest.kata_node_class]
}
