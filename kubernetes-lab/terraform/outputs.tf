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

output "jumpbox_ipv4_address" {
  description = "IPv4 address of the jumpbox VM."
  value       = module.vm["jumpbox"].ipv4_address
}

output "server_ipv4_address" {
  description = "IPv4 address of the server VM."
  value       = module.vm["server"].ipv4_address
}

output "node_0_ipv4_address" {
  description = "IPv4 address of node-0."
  value       = module.vm["node-0"].ipv4_address
}

output "node_1_ipv4_address" {
  description = "IPv4 address of node-1."
  value       = module.vm["node-1"].ipv4_address
}
