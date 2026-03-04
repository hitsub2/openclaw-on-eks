data "aws_iam_policy_document" "openclaw_bedrock" {
  statement {
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "openclaw_bedrock" {
  name_prefix = "${local.name}-openclaw-bedrock-"
  policy      = data.aws_iam_policy_document.openclaw_bedrock.json
  tags        = local.tags
}

module "openclaw_bedrock_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "${local.name}-openclaw-bedrock-"

  role_policy_arns = {
    bedrock = aws_iam_policy.openclaw_bedrock.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["default:openclaw-sandbox"]
    }
  }

  tags = local.tags
}

resource "kubernetes_service_account_v1" "openclaw_sandbox" {
  metadata {
    name      = "openclaw-sandbox"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.openclaw_bedrock_irsa.iam_role_arn
    }
  }

  depends_on = [module.eks]
}
