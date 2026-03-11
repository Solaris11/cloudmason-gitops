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

# Bitnami Helm Chart'ı yerine doğrudan Resmi RabbitMQ Deployment'ı kuruyoruz
resource "kubernetes_deployment" "rabbitmq" {
  metadata {
    name      = "platform-rabbitmq"
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "platform-rabbitmq"
      }
    }
    template {
      metadata {
        labels = {
          app = "platform-rabbitmq"
        }
      }
      spec {
        container {
          name  = "rabbitmq"
          image = "rabbitmq:3-management" # Resmi, stabil ve her zaman var olan imaj!

          port {
            container_port = 5672
            name           = "amqp"
          }
          port {
            container_port = 15672
            name           = "management"
          }

          env {
            name  = "RABBITMQ_DEFAULT_USER"
            value = "admin"
          }
          env {
            name = "RABBITMQ_DEFAULT_PASS"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.rabbitmq_credentials.metadata[0].name
                key  = "rabbitmq-password"
              }
            }
          }
        }
      }
    }
  }
}

# Diğer servislerin RabbitMQ'ya bağlanabilmesi için Service tanımı
resource "kubernetes_service" "rabbitmq" {
  metadata {
    name      = "platform-rabbitmq"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = "platform-rabbitmq"
    }
    port {
      name        = "amqp"
      port        = 5672
      target_port = 5672
    }
    port {
      name        = "management"
      port        = 15672
      target_port = 15672
    }
  }
}
