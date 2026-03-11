variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "The name of the K3s/Kubernetes cluster"
  type        = string
  default     = "cloudmason-dev"
}
