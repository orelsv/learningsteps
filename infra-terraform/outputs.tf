output "aks_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "db_host" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}
