# EFS File System for OpenClaw Sandboxes
resource "aws_efs_file_system" "openclaw" {
  creation_token = "${local.name}-openclaw"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.tags, {
    Name = "${local.name}-openclaw"
  })
}

# EFS Mount Targets in each private subnet
resource "aws_efs_mount_target" "openclaw" {
  count = length(module.vpc.private_subnets)

  file_system_id  = aws_efs_file_system.openclaw.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Security Group for EFS
resource "aws_security_group" "efs" {
  name_prefix = "${local.name}-efs-"
  description = "Security group for EFS mount targets"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "NFS from EKS nodes"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-efs"
  })
}

# IAM Policy for EFS CSI Driver
resource "aws_iam_policy" "efs_csi_policy" {
  name        = "${local.name}-efs-csi-policy"
  description = "Policy for EFS CSI Driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:CreateAccessPoint",
          "elasticfilesystem:DeleteAccessPoint"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:TagResource"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      }
    ]
  })
}

# IAM Role for EFS CSI Driver Pod Identity
resource "aws_iam_role" "efs_csi_pod_identity" {
  name = "${local.name}-efs-csi-pod-identity"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_csi_policy_attach" {
  role       = aws_iam_role.efs_csi_pod_identity.name
  policy_arn = aws_iam_policy.efs_csi_policy.arn
}

# Service Account for EFS CSI Driver
resource "kubernetes_service_account_v1" "efs_csi_controller" {
  metadata {
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"
  }

  depends_on = [module.eks]
}

# Pod Identity Association for EFS CSI Driver
resource "aws_eks_pod_identity_association" "efs_csi_driver" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = kubernetes_service_account_v1.efs_csi_controller.metadata[0].name
  role_arn        = aws_iam_role.efs_csi_pod_identity.arn

  depends_on = [kubernetes_service_account_v1.efs_csi_controller]
}

# Install EFS CSI Driver
resource "helm_release" "aws_efs_csi_driver" {
  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  namespace  = "kube-system"
  version    = "3.0.8"

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = kubernetes_service_account_v1.efs_csi_controller.metadata[0].name
  }

  depends_on = [aws_eks_pod_identity_association.efs_csi_driver]
}

# StorageClass for EFS with dynamic access point provisioning
resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.openclaw.id
    directoryPerms   = "700"
    gidRangeStart    = "1000"
    gidRangeEnd      = "2000"
    basePath         = "/openclaw"
  }

  depends_on = [helm_release.aws_efs_csi_driver]
}

# Output EFS ID
output "efs_file_system_id" {
  description = "EFS file system ID for OpenClaw sandboxes"
  value       = aws_efs_file_system.openclaw.id
}
