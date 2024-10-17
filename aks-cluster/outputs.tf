output "t2s_services_cluster_endpoint" {
  description = "Endpoint for t2s-services AKS control plane"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
  sensitive   = true
}

output "t2s_services_cluster_security_group_id" {
  description = "Network security group IDs attached to the t2s-services AKS cluster control plane"
  value       = azurerm_network_security_group.aks_nsg.id
  sensitive   = true
}

output "t2s_services_region" {
  description = "Azure region for t2s-services"
  value       = var.location
}

output "t2s_services_cluster_name" {
  description = "Kubernetes Cluster Name for t2s-services"
  value       = azurerm_kubernetes_cluster.aks_cluster.name
}
