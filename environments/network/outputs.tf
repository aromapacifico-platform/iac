output "transit_gateway_id" {
  description = "Share this ID with production only; the central state owns its lifecycle."
  value       = local.transit_gateway_id
}
output "vpn" {
  description = "Safe metadata for both VPN tunnels; no PSK values."
  value       = module.hybrid.vpn
}
