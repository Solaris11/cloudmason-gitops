resource "random_password" "rabbitmq_admin" {
  length  = 24
  special = false
}

resource "kubernetes_secret" "rabbitmq_credentials" {
  metadata {
    name      = "rabbitmq-admin-credentials"
    namespace = var.namespace
  }

  data = {
    "rabbitmq-password" = random_password.rabbitmq_admin.result
  }
}

resource "helm_release" "rabbitmq" {
  name       = "platform-rabbitmq"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "rabbitmq"
  namespace  = var.namespace
  timeout    = 600
  version    = "12.8.0"

  set {
    name  = "auth.username"
    value = "admin"
  }

  set {
    name  = "auth.existingPasswordSecret"
    value = kubernetes_secret.rabbitmq_credentials.metadata[0].name
  }

  set {
    name  = "persistence.enabled"
    value = "false"
  }
}
