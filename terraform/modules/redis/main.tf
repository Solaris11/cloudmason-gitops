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
    "redis-password" = random_password.redis_admin.result
  }
}

resource "helm_release" "redis" {
  name       = "platform-redis"
  repository = "oci://registry-1.docker.io/bitnamicharts" # YENİ OCI ADRESİ
  chart      = "redis"
  namespace  = var.namespace
  timeout    = 600

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
    value = "standalone"
  }

  set {
    name  = "master.persistence.enabled"
    value = "false"
  }
}
