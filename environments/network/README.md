# Central Network root

Owns the single central TGW (ASN 64512) or references one in its original owning
state, shares it only with production through RAM, and calls the single-site
[hybrid module](../../modules/network/modules/hybrid). See the complete
[network README](../../modules/network/README.md) for contracts and handoff order.

Required inputs: `network_account_id`, `network_role_arn`, `production_account_id`
and exactly one of `create_transit_gateway = true` or
`existing_transit_gateway_id`. `connection` and `hub_dns` default to null;
`collection_center_department` defaults to 41. No identifiers are guessed and no
real account is inferred from a profile name. Providers and role assumption live
here. The role must already exist and be authorized by security.

The empty S3 backend deliberately has no fabricated bucket/account/role. Supply a
Network-owned encrypted backend configuration during deployment initialization:

```sh
terraform init -backend-config=/path/to/network.backend.hcl
```

That file must supply the real `bucket`, unique central `key`, `region`,
`kms_key_id`, `encrypt = true` and `use_lockfile = true`; backend authentication is
separate from provider assume-role and must also target the approved Network
state location. Do not reuse dev/test/prod backend keys. No backend is contacted
when using `init -backend=false` for local validation and mocked tests.

The `transit_gateway_id` output is handed to production; production's attachment
output is then supplied in `connection.production_attachment_id`. A read-only
attachment lookup checks that it belongs to the declared production account and
central TGW before acceptance. Supply `connection.production_collection_center_id`
from the same production output snapshot's `network.collection_center.id`; it must
match the selected central department. This handoff does not depend on tags being
visible between accounts. The `vpn` output exposes only safe tunnel metadata.

Do not choose creation until the Network-account inventory and existing state
owners have been checked. An empty query in the dev account is not that inventory.
RAM sharing within AWS Organizations must be enabled by its existing owner.
If an existing central state already owns the production RAM share or routes,
coordinate ownership before planning this root.
