# Central hybrid connection

This child module is the Network-account part of planning #22. Read the
[parent README](../../README.md) for complete inputs, outputs, ownership,
security/DNS contracts and deployment order. Configure providers only in the
calling root (`environments/network`), never here.

| Input | Default | Purpose |
| --- | --- | --- |
| name_prefix | Required | Central connection naming prefix |
| transit_gateway_id | null | Required only with connection enabled; central TGW ASN 64512 |
| collection_center_department | 41 | Select one site: 41, 42, 43 |
| connection | null | Public CPE IPv4, production attachment ID and collection center ID, encrypted log group ARN |
| hub_dns | null | Existing hub attachment/table IDs and two resolver IPv4 addresses |

With connection disabled, this module requires no TGW ID, creates nothing and
performs no external data lookups. Enabling it creates one
Customer Gateway, a BGP Site-to-Site VPN with two tunnels and generated PSKs stored
in Secrets Manager, accepts production's attachment, and creates an isolated TGW
route table with explicit associations and operational routes. Optional hub DNS
routes use exact resolver /32s and authorized site return /24s. VPN propagation
is disabled. The parent environment module owns the production VPC attachment and
VPC return routes.

The sole output `vpn` is null when disabled. Otherwise it contains `id`,
`customer_gateway_id`, `route_table_id`, `preshared_key_arn` and `tunnels` (both
sets of public/inside peer addresses and AWS ASN). PSK values and full XML
configuration are never outputs. Mock tests verify the storage/output contract;
actual AWS secret redaction requires separate operational acceptance.
