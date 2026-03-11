locals {
  # Namespaces aligning with the 14 core services + 1 worker model
  app_namespaces = [
    "gateway",
    "auth",
    "ai",
    "commerce",
    "communication",
    "workflow",
    "workers",
    "user-ops"
  ]

  postgres_namespaces = ["auth", "commerce", "workflow", "workers", "user-ops"]
  mongo_namespaces    = ["ai", "communication"]

  global_env_vars = {
    ENVIRONMENT   = var.environment
    LOG_LEVEL     = "INFO"
    RABBITMQ_HOST = module.rabbitmq.host
    RABBITMQ_PORT = "5672"
    REDIS_HOST    = module.redis.host
    REDIS_PORT    = "6379"
  }
}

resource "kubernetes_config_map" "shared_config" {
  for_each = toset(local.app_namespaces)

  metadata {
    name      = "cloudmason-shared-config"
    namespace = each.key
  }

  data = local.global_env_vars
}

resource "kubernetes_secret" "shared_db_secrets_pg" {
  for_each = toset(local.postgres_namespaces)

  metadata {
    name      = "cloudmason-pg-secrets"
    namespace = each.key
  }

  data = {
    DB_PASSWORD = module.postgresql.admin_password
    DB_HOST     = module.postgresql.host
    DB_USER     = "postgres"
  }
}

resource "kubernetes_secret" "shared_db_secrets_mongo" {
  for_each = toset(local.mongo_namespaces)

  metadata {
    name      = "cloudmason-mongo-secrets"
    namespace = each.key
  }

  data = {
    MONGO_PASSWORD = module.mongodb.admin_password
    MONGO_HOST     = module.mongodb.host
    MONGO_USER     = "root"
  }
}

resource "kubernetes_secret" "shared_cache_secrets" {
  for_each = toset(local.app_namespaces)

  metadata {
    name      = "cloudmason-cache-secrets"
    namespace = each.key
  }

  data = {
    REDIS_PASSWORD    = module.redis.redis_password
    RABBITMQ_PASSWORD = module.rabbitmq.admin_password
  }
}
