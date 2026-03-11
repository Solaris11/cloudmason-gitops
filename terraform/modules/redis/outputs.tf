output "redis_password" {
  value     = random_password.redis_admin.result
  sensitive = true
}
output "host" {
  value = "platform-redis-master.${var.namespace}.svc.cluster.local"
}
