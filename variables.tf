variable "name" {
  description = "Name of the VPC and EKS Cluster"
  default     = "openclaw-kata-eks"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "eks_cluster_version" {
  description = "EKS Cluster version"
  default     = "1.31"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = "10.1.0.0/16"
  type        = string
}

variable "kata_hypervisor" {
  description = "Kata Containers hypervisor (qemu, clh, fc)"
  type        = string
  default     = "qemu"
  validation {
    condition     = contains(["qemu", "clh", "fc"], var.kata_hypervisor)
    error_message = "Hypervisor must be qemu, clh, or fc"
  }
}

variable "kata_instance_types" {
  description = "Bare metal instance types for Kata workloads"
  type        = list(string)
  default     = ["m5.metal", "m5d.metal", "c5.metal", "c5d.metal"]
}

variable "access_entries" {
  description = "Map of access entries to be added to the EKS cluster"
  type        = any
  default     = {}
}

variable "kms_key_admin_roles" {
  description = "List of IAM Role ARNs for KMS key administration"
  type        = list(string)
  default     = []
}
