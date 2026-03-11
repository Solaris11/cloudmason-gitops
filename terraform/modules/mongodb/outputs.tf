output "admin_password" {
  value     = random_password.mongo_admin.result
  sensitive = true
}
output "host" {
  value = "platform-mongodb.${var.namespace}.svc.cluster.local"
}
