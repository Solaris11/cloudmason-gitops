resource "random_password" "postgres_admin" {
  length  = 24
  special = false
}

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-admin-credentials"
    namespace = var.namespace
  }
  data = {
    # Bitnami chart expects this specific key
    "postgres-password" = random_password.postgres_admin.result
  }
}

resource "kubernetes_config_map" "pg_init" {
  metadata {
    name      = "postgres-init-scripts"
    namespace = var.namespace
  }
  data = {
    "init.sql" = join("\n", [for db in var.db_names : "CREATE DATABASE ${db};"])
  }
}

resource "helm_release" "postgresql" {
  name       = "platform-postgres"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  namespace  = var.namespace
  version    = "12.12.x"

  set {
    name  = "global.postgresql.auth.existingSecret"
    value = kubernetes_secret.postgres_credentials.metadata[0].name
  }

  set {
    name  = "primary.initdb.scriptsConfigMap"
    value = kubernetes_config_map.pg_init.metadata[0].name
  }
}
