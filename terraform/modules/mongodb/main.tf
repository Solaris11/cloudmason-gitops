resource "random_password" "mongo_admin" {
  length  = 24
  special = false
}

resource "kubernetes_secret" "mongo_credentials" {
  metadata {
    name      = "mongo-admin-credentials"
    namespace = var.namespace
  }
  data = {
    "mongodb-passwords"     = random_password.mongo_admin.result
    "mongodb-root-password" = random_password.mongo_admin.result
  }
}

resource "kubernetes_config_map" "mongo_init" {
  metadata {
    name      = "mongo-init-scripts"
    namespace = var.namespace
  }
  data = {
    "init.js" = join("\n", [for db in var.db_names : "db = db.getSiblingDB('${db}'); db.createCollection('init_collection');"])
  }
}

resource "helm_release" "mongodb" {
  name       = "platform-mongodb"
  repository = "oci://registry-1.docker.io/bitnamicharts" # YENİ OCI ADRESİ
  chart      = "mongodb"
  namespace  = var.namespace
  timeout    = 600

  set {
    name  = "auth.existingSecret"
    value = kubernetes_secret.mongo_credentials.metadata[0].name
  }

  set {
    name  = "initdbScriptsConfigMap"
    value = kubernetes_config_map.mongo_init.metadata[0].name
  }

  set {
    name  = "persistence.enabled"
    value = "false"
  }
}
