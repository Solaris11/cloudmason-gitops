# Architecture Note:
# 1. The local dev K3d cluster is created externally by the bootstrap.sh script.
# 2. Terraform assumes the cluster exists, validates the context, and deploys
#    the foundational datastores (PostgreSQL, MongoDB, Redis, RabbitMQ) into it.
# 3. Future Production Direction: This will evolve so Terraform directly provisions
#    the managed Kubernetes clusters (EKS/GKE) and their node groups.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-${var.cluster_name}"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "k3d-${var.cluster_name}"
  }
}

module "k8s_cluster" {
  source       = "../../modules/k8s_cluster"
  cluster_name = var.cluster_name
}

module "rabbitmq" {
  source    = "../../modules/rabbitmq"
  namespace = "messaging"
  depends_on = [module.k8s_cluster]
}

module "postgresql" {
  source    = "../../modules/postgresql"
  namespace = "databases"
  db_names  = [
    "identity_db",
    "security_db",
    "pricing_db",
    "offer_db",
    "audit_workflow_db"
  ]

  depends_on = [module.k8s_cluster, module.rabbitmq]
}

module "mongodb" {
  source    = "../../modules/mongodb"
  namespace = "databases"
  db_names  = [
    "core_ai_metadata",
    "system_design_repo",
    "architecture_outputs",
    "contact_db",
    "notifications_log"
  ]

  depends_on = [module.k8s_cluster, module.postgresql]
}

module "redis" {
  source    = "../../modules/redis"
  namespace = "databases"

  depends_on = [module.k8s_cluster, module.mongodb]
}
