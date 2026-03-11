resource "random_password" "redis_admin" {
  length  = 24
  special = false
}

resource "kubernetes_secret" "redis_credentials" {
  metadata {
    name      = "redis-admin-credentials"
    namespace = var.namespace
  }
  data = {
    # Bitnami chart expects this specific key
    "redis-password" = random_password.redis_admin.result
  }
}

resource "helm_release" "redis" {
  name       = "platform-redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = var.namespace
  version    = "18.0.x"

  set {
    name  = "auth.existingSecret"
    value = kubernetes_secret.redis_credentials.metadata[0].name
  }
  set {
    name  = "auth.existingSecretPasswordKey"
    value = "redis-password"
  }
  set {
    name  = "architecture"
    value = "standalone" # MVP configuration
  }
}
