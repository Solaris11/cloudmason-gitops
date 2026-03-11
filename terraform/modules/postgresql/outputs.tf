output "admin_password" {
  value     = random_password.postgres_admin.result
  sensitive = true
}
output "host" {
  value = "platform-postgres-postgresql.${var.namespace}.svc.cluster.local"
}
