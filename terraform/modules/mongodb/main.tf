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
    # Bitnami chart expects these specific keys
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
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  namespace  = var.namespace
  version    = "13.18.x"

  set {
    name  = "auth.existingSecret"
    value = kubernetes_secret.mongo_credentials.metadata[0].name
  }

  set {
    name  = "initdbScriptsConfigMap"
    value = kubernetes_config_map.mongo_init.metadata[0].name
  }
}
