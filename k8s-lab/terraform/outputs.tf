output "network_bridge" {
  description = "The name of the bridge interface created for the lab network."
  value       = module.network.bridge
}

output "network_gateway_ipv4_address" {
  description = "Gateway IP address of the lab network."
  value       = module.network.gateway_ipv4_address
}

output "network_domain" {
  description = "DNS domain for the lab network."
  value       = module.network.domain
}

output "control_plane_lb_ipv4_address" {
  description = "IPv4 address of the control-plane-lb VM."
  value       = module.vm["control-plane-lb"].ipv4_address
}

output "control_plane_01_ipv4_address" {
  description = "IPv4 address of the control-plane-01 VM."
  value       = module.vm["control-plane-01"].ipv4_address
}

output "control_plane_02_ipv4_address" {
  description = "IPv4 address of the control-plane-02 VM."
  value       = module.vm["control-plane-02"].ipv4_address
}

output "control_plane_03_ipv4_address" {
  description = "IPv4 address of the control-plane-03 VM."
  value       = module.vm["control-plane-03"].ipv4_address
}

output "worker_01_ipv4_address" {
  description = "IPv4 address of the worker-01 VM."
  value       = module.vm["worker-01"].ipv4_address
}

output "worker_02_ipv4_address" {
  description = "IPv4 address of the worker-02 VM."
  value       = module.vm["worker-02"].ipv4_address
}

output "worker_03_ipv4_address" {
  description = "IPv4 address of the worker-03 VM."
  value       = module.vm["worker-03"].ipv4_address
}
