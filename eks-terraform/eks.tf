locals {
  cluster_name = "eks-terraform-example"
}

module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "19.12.0"
  cluster_name                   = local.cluster_name
  cluster_version                = "1.25"
  cluster_endpoint_public_access = true
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  manage_aws_auth_configmap      = true
  cluster_addons = {
    aws-ebs-csi-driver = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.aws_ebs_irsa.iam_role_arn
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  eks_managed_node_group_defaults = {
    disk_size      = 25
    instance_types = ["m5.large"]
  }
  eks_managed_node_groups = {
    spot = {
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      instance_types = ["m5.large"]
      capacity_type  = "SPOT"
    }
    on_demand = {
      min_size       = 1
      max_size       = 7
      desired_size   = 2
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"
    }
  }
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_all_port = {
      description                   = "allow all from cluster-sg"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
  aws_auth_roles = [
    {
      rolearn = "arn:aws:iam::${var.accountnum}:role/EKSAdministrator"
      groups  = ["system:masters"]
    },
    {
      rolearn = "arn:aws:iam::${var.accountnum}:role/EKSDeveloper"
      groups  = ["internal:dev"]
    }
  ]
}

module "aws_ebs_irsa" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version               = "5.18.0"
  role_name             = "${local.cluster_name}-aws-ebs-csi-driver"
  attach_ebs_csi_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "aws_alb_irsa" {
  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version                                = "5.18.0"
  role_name                              = "${local.cluster_name}-aws-alb-irsa"
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

module "aws_cluster_autoscaler_irsa" {
  source                           = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version                          = "5.18.0"
  role_name                        = "${local.cluster_name}-aws-cluster-autoscaler-irsa"
  attach_cluster_autoscaler_policy = true
  role_policy_arns = {
    additional = aws_iam_policy.additional_cluster_autoscaler_policy.arn
  }
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

resource "aws_iam_policy" "additional_cluster_autoscaler_policy" {
  name   = "${local.cluster_name}-cluster-autoscaler-policy-additional"
  path   = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/k8s.io/cluster-autoscaler/${local.cluster_name}": "owned"
        }
      }
    }
  ]
}
EOF
}
