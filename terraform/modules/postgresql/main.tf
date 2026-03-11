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
  repository = "oci://registry-1.docker.io/bitnamicharts" # YENİ OCI ADRESİ
  chart      = "postgresql"
  namespace  = var.namespace
  timeout    = 600

  set {
    name  = "global.postgresql.auth.existingSecret"
    value = kubernetes_secret.postgres_credentials.metadata[0].name
  }

  set {
    name  = "primary.initdb.scriptsConfigMap"
    value = kubernetes_config_map.pg_init.metadata[0].name
  }

  set {
    name  = "primary.persistence.enabled"
    value = "false"
  }
}
