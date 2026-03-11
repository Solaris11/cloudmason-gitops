output "admin_password" {
  value     = random_password.rabbitmq_admin.result
  sensitive = true
}
output "host" {
  value = "platform-rabbitmq.${var.namespace}.svc.cluster.local"
}
