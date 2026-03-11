output "host" {
  description = "RabbitMQ internal cluster hostname"
  # Servis adı ve namespace'i birleştirerek tam DNS adını oluşturuyoruz
  value       = "${kubernetes_service.rabbitmq.metadata[0].name}.${var.namespace}.svc.cluster.local"
}

output "admin_password" {
  description = "RabbitMQ auto-generated admin password"
  value       = random_password.rabbitmq_admin.result
  sensitive   = true
}
