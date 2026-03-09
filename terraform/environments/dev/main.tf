terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.0"
    }
  }
}

# 1. Aşama: K3s Cluster'ını k3d ile Yaratma (Null Resource ile CLI tetikleme)
resource "null_resource" "k3d_cluster" {
  # Cluster'ı yarat
  provisioner "local-exec" {
    command = "k3d cluster create cloudmason-dev --port '8080:80@loadbalancer' --port '8443:443@loadbalancer' --wait"
  }

  # Terraform destroy edildiğinde cluster'ı temizle
  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete cloudmason-dev"
  }
}

# 2. Aşama: Kubernetes ve Helm Provider'larını Yapılandırma
# Not: ~/.kube/config dosyası k3d tarafından otomatik güncellenir
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# 3. Aşama: Argo CD için Namespace Oluştur (Cluster ayağa kalktıktan sonra)
resource "kubernetes_namespace" "argocd" {
  depends_on = [null_resource.k3d_cluster]

  metadata {
    name = "argocd"
  }
}

# 4. Aşama: Argo CD'yi Helm ile K3s'e Kur
resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "6.2.4"

  # Lokal ortamda arayüze kolay erişmek için NodePort kullanıyoruz
  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  # Güvenlik uyarısını (TLS) lokal testler için atlıyoruz
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }
}
