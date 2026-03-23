#---------------------------------------------------------------
# Custom IAM Policies (replacing AWS managed policies)
#---------------------------------------------------------------

# Replaces: AmazonEKSWorkerNodePolicy
resource "aws_iam_policy" "eks_worker_node" {
  name_prefix = "${local.name}-eks-worker-"
  description = "Custom policy replacing AmazonEKSWorkerNodePolicy"
  tags        = local.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeVpcs",
          "ec2:DescribeNetworkInterfaces",
          "eks:DescribeCluster",
          "eks-auth:AssumeRoleForPodIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

# Replaces: AmazonEC2ContainerRegistryReadOnly
resource "aws_iam_policy" "ecr_read_only" {
  name_prefix = "${local.name}-ecr-ro-"
  description = "Custom policy replacing AmazonEC2ContainerRegistryReadOnly"
  tags        = local.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ]
        Resource = "*"
      }
    ]
  })
}

# Replaces: AmazonEKS_CNI_Policy
resource "aws_iam_policy" "eks_cni" {
  name_prefix = "${local.name}-eks-cni-"
  description = "Custom policy replacing AmazonEKS_CNI_Policy"
  tags        = local.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AssignPrivateIpAddresses",
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeSubnets",
          "ec2:DetachNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateTags"]
        Resource = "arn:${local.partition}:ec2:*:*:network-interface/*"
      }
    ]
  })
}

# Replaces: AmazonSSMManagedInstanceCore
resource "aws_iam_policy" "ssm_core" {
  name_prefix = "${local.name}-ssm-core-"
  description = "Custom policy replacing AmazonSSMManagedInstanceCore"
  tags        = local.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      }
    ]
  })
}

# Replaces: AmazonEKSClusterPolicy
resource "aws_iam_policy" "eks_cluster" {
  name_prefix = "${local.name}-eks-cluster-"
  description = "Custom policy replacing AmazonEKSClusterPolicy"
  tags        = local.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSClusterPolicy"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateRoute",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteRoute",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteVolume",
          "ec2:DescribeInstances",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeVpcs",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAvailabilityZones",
          "ec2:DetachVolume",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyVolume",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeInstanceTopology",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
          "elasticloadbalancing:AttachLoadBalancerToSubnets",
          "elasticloadbalancing:ConfigureHealthCheck",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateLoadBalancerListeners",
          "elasticloadbalancing:CreateLoadBalancerPolicy",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancerListeners",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeLoadBalancerPolicies",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DetachLoadBalancerFromSubnets",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
          "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid      = "EKSClusterSLRCreate"
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Sid      = "EKSClusterENIDelete"
        Effect   = "Allow"
        Action   = "ec2:DeleteNetworkInterface"
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/eks:eni:owner" = "amazon-vpc-cni"
          }
        }
      }
    ]
  })
}

# Replaces: AmazonEKSVPCResourceController
resource "aws_iam_policy" "eks_vpc_resource_controller" {
  name_prefix = "${local.name}-eks-vpc-rc-"
  description = "Custom policy replacing AmazonEKSVPCResourceController"
  tags        = local.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ec2:CreateNetworkInterfacePermission"
        Resource = "*"
        Condition = {
          "ForAnyValue:StringEquals" = {
            "ec2:ResourceTag/eks:eni:owner" = "eks-vpc-resource-controller"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:UnassignPrivateIpAddresses",
          "ec2:AssignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

#---------------------------------------------------------------
# EKS Cluster IAM Role (external, no managed policies)
#---------------------------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  name_prefix = "${local.name}-cluster-"
  tags        = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EKSClusterAssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  for_each = {
    cluster        = aws_iam_policy.eks_cluster.arn
    vpc_controller = aws_iam_policy.eks_vpc_resource_controller.arn
  }

  role       = aws_iam_role.eks_cluster.name
  policy_arn = each.value
}

# Cluster encryption policy for KMS
resource "aws_iam_policy" "eks_cluster_encryption" {
  name_prefix = "${local.name}-cluster-encryption-"
  description = "EKS cluster encryption policy for KMS key"
  tags        = local.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ListGrants",
        "kms:DescribeKey"
      ]
      Resource = module.eks.kms_key_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_encryption" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = aws_iam_policy.eks_cluster_encryption.arn
}

#---------------------------------------------------------------
# EKS Managed Node Group IAM Role (external, no managed policies)
#---------------------------------------------------------------

resource "aws_iam_role" "eks_node_group" {
  name_prefix = "${local.name}-node-"
  tags        = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group" {
  for_each = {
    worker = aws_iam_policy.eks_worker_node.arn
    ecr    = aws_iam_policy.ecr_read_only.arn
    cni    = aws_iam_policy.eks_cni.arn
    ssm    = aws_iam_policy.ssm_core.arn
  }

  role       = aws_iam_role.eks_node_group.name
  policy_arn = each.value
}

#---------------------------------------------------------------
# Karpenter Node IAM Role (external, no managed policies)
#---------------------------------------------------------------

resource "aws_iam_role" "karpenter_node" {
  name = "Karpenter-${local.name}"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.${local.dns_suffix}" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node" {
  for_each = {
    worker = aws_iam_policy.eks_worker_node.arn
    ecr    = aws_iam_policy.ecr_read_only.arn
    cni    = aws_iam_policy.eks_cni.arn
    ssm    = aws_iam_policy.ssm_core.arn
  }

  role       = aws_iam_role.karpenter_node.name
  policy_arn = each.value
}
