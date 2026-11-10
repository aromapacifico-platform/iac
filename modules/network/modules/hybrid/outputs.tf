output "vpn" {
  description = "Safe VPN handoff: IDs and both tunnel addresses; never XML configuration or PSK values."
  value = var.connection == null ? null : {
    id                  = aws_vpn_connection.this[0].id
    customer_gateway_id = aws_customer_gateway.this[0].id
    route_table_id      = aws_ec2_transit_gateway_route_table.this[0].id
    preshared_key_arn   = aws_vpn_connection.this[0].preshared_key_arn
    tunnels = [
      { outside_ip = aws_vpn_connection.this[0].tunnel1_address, aws_inside_ip = aws_vpn_connection.this[0].tunnel1_vgw_inside_address, customer_inside_ip = aws_vpn_connection.this[0].tunnel1_cgw_inside_address, aws_bgp_asn = aws_vpn_connection.this[0].tunnel1_bgp_asn },
      { outside_ip = aws_vpn_connection.this[0].tunnel2_address, aws_inside_ip = aws_vpn_connection.this[0].tunnel2_vgw_inside_address, customer_inside_ip = aws_vpn_connection.this[0].tunnel2_cgw_inside_address, aws_bgp_asn = aws_vpn_connection.this[0].tunnel2_bgp_asn }
    ]
  }
}
