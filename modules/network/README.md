# Environment network and single collection center pattern

Implements [planning #22](https://github.com/aromapacifico-platform/planning/issues/22),
using the approved [address plan](https://github.com/aromapacifico-platform/planning/blob/main/docs/architecture/red-direccionamiento-nube.md),
[collection center design](https://github.com/aromapacifico-platform/planning/blob/main/docs/architecture/carga-d-centro-acopio.md),
[firewall contract](https://github.com/aromapacifico-platform/planning/blob/main/docs/architecture/red-firewall.md)
and [landing zone](https://github.com/aromapacifico-platform/planning/blob/main/docs/architecture/gobierno-landing-zone.md).
Dependencies #7 and #21 are closed. Code readiness and local tests do not establish
that a VPN, DNS service or application is deployed or reachable.

## Version contract

Terraform **>= 1.11.0, < 2.0.0** is required by the network modules and their
calling roots. The tests use plan-time `override_during`, present in the
[Terraform 1.11 parser](https://github.com/hashicorp/terraform/blob/v1.11.0/internal/configs/mock_provider.go)
and absent from 1.10. This does not claim that tests were executed on every
allowed Terraform version; the locally tested CLI is recorded in VALIDATION.md.
AWS **>= 6.72.0, < 7.0.0** is the verified provider baseline for this deliverable,
not a claim that SecretsManager support was first introduced in 6.72.0.

The workload roots' `~> 6.0` permits >=6.0.0 and <7.0.0; combined with this
module the effective range is >=6.72.0 and <7.0.0. All current locks select 6.72.0.
The reviewed pending PR versions are pinned by source blob:

| PR / head module | AWS constraint | Reviewed versions.tf blob |
| --- | --- | --- |
| Security #2 (planning #23) | ~> 5.0, or >=5.0.0 and <6.0.0 | 432dd2b7516ad0a1a2169ef9defc5ca1381d69d6 |
| Function #3 (planning #25) | ~> 5.0, or >=5.0.0 and <6.0.0 | fe7c34f7d91a7f4d17d723552e6f756269926a37 |

Those AWS ranges have **no intersection** with this module's range. Terraform
selects one version of a provider source for the entire root configuration;
`aws.project` aliases cannot run v5 and v6 side by side. The PR owners must review
their modules for AWS v6 and adjust constraints/tests before same-root composition,
or retain separate roots/states and exchange explicit non-secret IDs. Both PRs'
Terraform >=1.10 constraints permit 1.11 and are not themselves incompatible;
function's separate `hashicorp/archive ~> 2.4` does not conflict with AWS either.
Neither pending branch was modified, merged or copied by this change.

## Scope and state boundaries

`modules/network` creates one environment VPC, fourteen /24 subnets, fourteen route
tables and associations, an Internet Gateway, two internet default routes (public
query only), and S3/DynamoDB gateway endpoints on all twelve internal route tables.
Automatic public address assignment is disabled everywhere. No NAT is created.
The VPC has `prevent_destroy` protection.

When explicitly supplied a central TGW ID, the module creates one VPC attachment in
the two administration subnets and twenty-four routes: two authorized collection
center prefixes on each internal route table. Only the production address block
may enable this feature. Neither dev nor test can attach to a real collection
center. Selection of a department alone creates no hybrid resources or routes.

`modules/network/modules/hybrid` is the central-account portion of the same story.
It creates one Customer Gateway, one Site-to-Site VPN (both tunnels, BGP), an isolated
TGW route table, explicit associations, two operational routes toward the VPN and
one production return route. It accepts the cross-account production attachment.
Requester-side association
flags cannot enforce owner-side settings on a RAM-shared TGW; the central root
checks/sets those TGW defaults, and the central accepter manages the associations.
It does not create a VGW, a VPC, IAM policies, security groups, NACLs or KMS keys.

`environments/network` runs this portion with an explicitly supplied role and
`allowed_account_ids` in **AromaPacifico-Network**. Its S3 backend must use a separate
Network-account bucket/key/KMS configuration. It is never initialized against a
workload backend. No account ownership is inferred from the `aromapacifico-dev`
profile name.

## Addressing

| Environment | VPC | Hybrid connection default |
| --- | --- | --- |
| dev | `10.50.0.0/16` | Disabled; enabling is rejected |
| test | `10.60.0.0/16` | Disabled; enabling is rejected |
| prod | `10.70.0.0/16` | Disabled until a central TGW ID is supplied |

| Category / output key prefix | Zone A subnet number | Zone B subnet number |
| --- | --- | --- |
| ingest_telemetry | 1 | 101 |
| ingest_drone | 2 | 102 |
| app | 10 | 110 |
| data | 20 | 120 |
| storage | 30 | 130 |
| admin | 40 | 140 |
| public_query | 50 | 150 |

Keys are `<category>_az_a` and `<category>_az_b`. For example, production storage is
`10.70.30.0/24` and `10.70.130.0/24`. The exact three approved /16 inputs prevent
both inter-environment overlap and overlap with all three collection centers.

| Department | Input | Collection center | CIDR | Customer ASN | Operational prefixes |
| --- | --- | --- | --- | --- | --- |
| Cauca | 41 (default) | ACOPIO-CAUCA | 10.41.0.0/16 | 65041 | 10.41.3.0/24, 10.41.10.0/24 |
| Huila | 42 | ACOPIO-HUILA | 10.42.0.0/16 | 65042 | 10.42.3.0/24, 10.42.10.0/24 |
| Tolima | 43 | ACOPIO-TOLIMA | 10.43.0.0/16 | 65043 | 10.43.3.0/24, 10.43.10.0/24 |

Select the same department in the production and Network roots:

```hcl
collection_center_department = 41 # Cauca
# collection_center_department = 42 # Huila, instead of Cauca
# collection_center_department = 43 # Tolima, instead of Cauca
```

These are alternatives for **one** pattern, not a loop over three sites. Changing
the department of an already deployed connection changes its ASN and routes and
can replace resources; schedule and review that change with the network operator.
Visitors (`10.X.5.0/24`) are neither routed nor advertised by this code. The edge
operator must filter BGP exports to the two operational /24s and imports to
production and the exact authorized hub DNS /32s. The `.20.1` and `.20.2` edge
addresses are private LAN addresses, never Customer Gateway public addresses.

With `connection = null`, the hybrid child requires no TGW ID, public CPE IP,
production attachment or log group, declares no resources and performs no data
lookups. An enabled connection requires a valid TGW ID. The central root's
explicit TGW ownership/share operations are independent of VPN activation: in
creation mode there is no existing-TGW lookup; in existing mode its lookup is
necessary to validate ownership before sharing it. The production attachment
lookup is absent while the connection is disabled. Workload roots never query
hybrid infrastructure when their TGW input is null.

## Environment module inputs

| Input | Required / default | Meaning |
| --- | --- | --- |
| name_prefix | Required | Root-owned resource naming prefix |
| vpc_cidr | Required | One of the three approved /16 blocks |
| availability_zones | Required | Two distinct zones in the provider region |
| aws_region | Required | Region matching the root provider |
| gateway_endpoint_policies | Required | Exactly `s3` and `dynamodb`, valid JSON policies |
| collection_center_department | 41 | 41, 42 or 43 |
| transit_gateway_id | null | Existing, centrally shared TGW; enables production attachment/routes |
| s3_interface | null | Object with security-owned `security_group_id` and scoped JSON `policy` |

No module configures a provider or consumes credentials. The workload roots inherit
the caller's authenticated session. `aws_account_id` adds a provider account guard
and is mandatory when enabling their TGW attachment.

The three workload roots now call the module. Their required `endpoint_access` map
has exactly `s3` and `dynamodb`, each with `principal_arns`, `actions`, and
`resource_arns` sets. These roots build Allow policies with explicit IAM role
principals and actions. Wildcard principals/actions/resources are rejected; a
trailing object `/*` is allowed only on a named S3 bucket or prefix. DynamoDB
requires a named table or index ARN in the root region; `table/*` and both `*`/`?`
wildcards in its resource names are rejected. Actual bucket/table
ARNs and execution role ARNs must come from security/workload contracts. No
permissive fallback or deployment DenyAll fixture is installed.

CI supplies this map through `TF_VAR_endpoint_access` from repository Actions
variables `ENDPOINT_ACCESS_DEV`, `ENDPOINT_ACCESS_TEST`, and `ENDPOINT_ACCESS_PROD`.
Each variable is a complete JSON object for that environment, with exactly the
`s3` and `dynamodb` grant entries. See [the exact CI input contract and central
workflow handoff](../../docs/iac/ci-plan-inputs.md). The existing root validations
and explicit grants remain unchanged; test fixtures are not deployment defaults.

`collection_center_cidrs` and `network_inputs` remain as deprecated compatibility
metadata from #21. Even the existing production map listing three sites does not
create a route or VPN. Use the single department input for this implementation.

## Outputs and integration without dependency cycles

Existing outputs remain: `vpc_id`, `subnet_ids`, `subnet_cidrs`, `route_table_ids`,
`gateway_endpoint_ids`, `gateway_endpoint_prefix_list_ids`, and `collection_center`.
New outputs are:

| Output | Consumer |
| --- | --- |
| private_subnet_ids | Security's private NACL associations |
| public_subnet_ids | Security's public NACL associations |
| function_subnet_ids | Focus function's private drone-ingestion subnet pair |
| transit_gateway_attachment_id | Central Network attachment acceptance and routing |
| s3_interface_endpoint | Endpoint ID and DNS entries for hybrid S3 clients |

Each workload root exports these under `network`.

Contracts reviewed against open [security PR #2](https://github.com/aromapacifico-platform/iac/pull/2)
(planning #23) and [function PR #3](https://github.com/aromapacifico-platform/iac/pull/3)
(planning #25):

- Network supplies security's `vpc_id`, `private_subnet_ids`, `public_subnet_ids`
  and prefix list IDs as integration contracts. The reviewed security PR currently
  has no dedicated prefix-list input; its owner must wire these outputs or retain
  a region-specific service prefix-list lookup for C06-C09/C20. Security supplies `security_group_ids["vpce_s3"]` for
  `s3_interface.security_group_id` (or root `s3_interface_security_group_id`).
- Function receives `function_subnet_ids` as its `subnet_ids` and security's
  `security_group_ids["function"]`. IAM/KMS remain with their respective owners.
- SG C05 must allow only approved drone/backup clients on TCP 443. Resolver
  C18/C19 must use exact DNS origins (initially `10.X.10.1/32`), not the whole site.
- Those PRs currently declare AWS `~> 5.0` with `aws.project`; this implementation
  uses AWS `>= 6.72.0, < 7.0.0` as its verified VPN baseline. Their constraints
  must be reconciled by their owners before composing those modules. They were
  neither merged nor copied here. Their broad sample CIDR defaults are not adopted.

Use resource-specific outputs, without `depends_on = [module.network]` on security
or workloads. VPC/subnet outputs depend only on their resources, not on interface
SG inputs. If endpoint policies depend on a workload that itself needs endpoints,
use security-owned stable role/resource contracts or separate security/workload
states; do not add whole-module dependency edges. There is no automatic remote
state reader granting access to all security state data.

## TGW ownership and deployment ordering

The Network team owns ASN **64512**, RAM sharing and TGW routing. Choose exactly
one ownership mode in `environments/network` after auditing the Network account:

- `create_transit_gateway = true`: create one protected TGW in this central state.
- `existing_transit_gateway_id = <actual ID>` with creation false: validate the
  existing TGW's owner, ASN and disabled default association/propagation/automatic
  acceptance. Its lifecycle stays in its original central state. No import is needed.

Both modes require actual `network_account_id`, `network_role_arn` and
`production_account_id`. Never deploy this root with guessed IDs. Creation is not
selected by default. The RAM share is scoped to production and disallows external
principals. Organization RAM sharing must already be enabled by its owner; this
story does not change Organizations or IAM.

Deployment handoff (not executed as part of local validation):

1. Review the central ownership mode and provision/share the TGW with `connection = null`.
2. Pass its ID to the production root. Create the production VPC attachment, with
   default association/propagation disabled. Pass its output ID back to Network.
3. Set Network `connection` to an object containing the real
   `customer_gateway_public_ip`, `production_attachment_id`,
   `production_collection_center_id` and security-owned `tunnel_log_group_arn`.
   Network compares the production collection center metadata with its selected
   department, verifies the attachment's account/TGW through AWS, accepts
   it, creates the single VPN and associates both attachments to its isolated table.
4. Configure both CPE tunnels, BGP filters, S3 endpoint client settings, security
   policies and DNS. Test real forwarding and failover before claiming connectivity.

Take `connection.production_attachment_id` from production's
`network.transit_gateway_attachment_id` and
`connection.production_collection_center_id` from the same snapshot's
`network.collection_center.id`. The latter is an explicit handoff, not an AWS
assertion about department ownership. The attachment lookup checks the real
account and TGW. It deliberately does not depend on requester-side tags being
visible in the owner account; cross-account attachment tags need owner-side
management ([AWS guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/tag-transit-gateway-attachments-automatically-using-aws-organizations.html)).
Both the root and hybrid child validate this metadata, and disabled connection
requires neither field.

There is no cross-state cycle: central TGW creation does not require production
outputs, and the production attachment does not require VPN outputs. No independent
TGW is created by a workload root. If another central state already owns a RAM
share or the same routes, coordinate ownership before planning to avoid duplicate
management.

The Network role needs scoped EC2 TGW/VPN/Customer Gateway describe/create/modify/
delete/tag and attachment acceptance/association/route permissions; RAM resource
share/association permissions; and permissions required by the VPN service to
store generated PSKs in Secrets Manager and publish tunnel logs. The workload
role needs VPC/subnet/route/endpoint operations and TGW attachment creation for the
shared TGW. Security owns those roles, role trust, any service-linked role setup,
log delivery resource policies, encrypted log groups and KMS permissions. This
code creates or broadens no IAM permissions. The operator needs a separately
controlled secret-retrieval path to configure the CPE; Terraform does not need
`secretsmanager:GetSecretValue`.

## VPN routing and secrets

Both tunnels use BGP, IKEv2, AES256, SHA2-256, DH14 and DPD restart, with logs sent
to the supplied security-owned encrypted log group. AWS allocates the link-local
inside /30s and public tunnel addresses. ECMP is disabled on a newly managed TGW;
configure the CPE to prefer one tunnel and retain the other as backup. An existing
TGW's ECMP policy remains with its owner.

Only the two operational /24s are installed as TGW routes toward the VPN. VPN
route propagation is intentionally absent: TGW cannot filter propagated BGP
prefixes. BGP still controls the VPN's tunnel reachability. Static TGW allowlist
routes do not replace edge advertisement filters or provide a complete firewall.
No default route or other workload environment is installed in the hybrid table.
IPsec selectors cover the site /16 and AWS `10.0.0.0/8` so hub DNS can traverse
the same connection; actual access is limited by routes, SG/NACL and edge policy.

The installed AWS provider schema was inspected at **6.72.0**. The connection sets
`preshared_key_storage = "SecretsManager"` and leaves both PSK arguments unset,
allowing AWS to generate and store them. AWS redacts PSKs in the Describe response
in this mode. The provider reads that response; it does not call GetSecretValue.
It still has computed PSK/XML state attributes, which must contain redacted
metadata, not key material. `sensitive = true` alone would not solve this problem.
See the [provider contract](https://registry.terraform.io/providers/hashicorp/aws/6.72.0/docs/resources/vpn_connection)
and [provider read implementation](https://github.com/hashicorp/terraform-provider-aws/blob/v6.72.0/internal/service/ec2/vpnsite_connection.go).

No PSK/private-key input, tfvars value, secret data source, or full VPN/XML output
is defined. The safe `vpn` output contains IDs, a Secrets Manager ARN and the two
sets of outside/inside addresses and AWS ASN values. It never returns PSK values.
Do not migrate a Standard-storage connection through this configuration without a
separate audit: historical state versions could contain secrets. Mock tests check
the selected storage mode and output allowlist; they do **not** prove redaction in
an actual deployed state. Review actual redacted state through a secure process
before operational acceptance, without printing secret values or enabling TF_LOG.

## Hybrid S3 and DNS contract

Gateway endpoints serve VPC clients only; they cannot be reached through VPN/TGW.
The optional S3 Interface endpoint uses exactly the two storage subnets and the
security-supplied SG/policy. Private DNS interception is disabled intentionally:
VPC clients retain normal regional S3 names and use the free gateway endpoint;
on-premises clients use the exported endpoint-specific regional DNS name with
bucket addressing (configure the SDK/CLI endpoint URL and the expected TLS host).
AWS endpoint-specific DNS names resolve to private ENI addresses. Avoid pinning
those IPs in clients. See [S3 PrivateLink DNS behavior](https://docs.aws.amazon.com/AmazonS3/latest/userguide/privatelink-interface-endpoints.html).

The approved central hub Resolver remains an explicit integration dependency.
Network's optional `hub_dns` object takes its actual `attachment_id`, isolated
`route_table_id` and two `resolver_ips` in `10.80.0.0/16`. It installs resolver /32
routes in the VPN table and the two site return routes in the hub table. The hub
owner must provide matching VPC subnet routes toward those operational /24s,
existing hub attachment/table association, inbound resolver listeners, approved
forwarding zones and SG C18/C19. The site forwards only authorized zones to those
two IPs; endpoint-specific S3 names must be resolved by that resolver. Network does
not create a second hub VPC or substitute an environment-local resolver for it.

`hub_dns = null` leaves DNS routing unconfigured; `s3_interface = null` leaves
hybrid S3 unconfigured. VPN routing may be reviewed independently, but **hybrid S3
is not operationally complete** until the endpoint, SG/bucket/IAM policies, hub
resolver/return routes and client DNS settings are all in place. Ordinary regional
S3 names are not transparently mapped to this interface endpoint by this module.
If transparent regional-name behavior is required, the hub DNS owner must provide
a reviewed split-DNS design; enabling private DNS indiscriminately changes VPC
routing/cost and is not an equivalent shortcut. API, inference, KMS, Logs and SSM
interface endpoints are separate contracts owned by the corresponding stories;
this module does not claim to implement every firewall catalog destination.

## Validation and remaining external inputs

Run from the repository root (no AWS credentials needed for mocked test plans):

```sh
terraform fmt -recursive modules/network environments
terraform -chdir=modules/network init -backend=false
terraform -chdir=modules/network validate
terraform -chdir=modules/network test -filter=tests/network.tftest.hcl
terraform -chdir=modules/network/modules/hybrid init -backend=false
terraform -chdir=modules/network/modules/hybrid validate
terraform -chdir=modules/network/modules/hybrid test
for root in environments/dev environments/test environments/prod environments/network; do
  terraform -chdir="$root" init -backend=false
  terraform -chdir="$root" validate
  terraform -chdir="$root" test
done
# TFLint must use the repository configuration, including the pinned AWS ruleset.
tflint --init --config="$PWD/.tflint.hcl"
tflint --recursive --config="$PWD/.tflint.hcl"
```

All test runs use `command = plan` and AWS mocks, including the original six
scenarios and the added routing, endpoint, negative-input, account and secret
contract checks. Documentation-only addresses and account IDs in tests are
fixtures, never deployment configuration. Local tests do not access the remote
state, create AWS resources, verify tunnel uptime or prove failover.

Before a **real plan**, supply actual scoped endpoint grants, account identities,
Network role/trust, TGW ownership choice, RAM sharing readiness and backend values.
When enabling VPN, also supply the public CPE address, production attachment and
encrypted tunnel log group. For hybrid S3 supply security's SG, bucket/role policy
contracts, hub DNS IDs/addresses/return routes and client endpoint configuration.
Missing values are not replaced by fabricated IDs, public IPs or broad permissions.
After deployment, measure BGP routes, tunnel failover, TLS/DNS/S3 access and visitor/
dev/test isolation separately. This change performs no apply, destroy or import.

See [VALIDATION.md](VALIDATION.md) for the checks actually executed and their limits.

No `rules-iac-modules` package or applicable AGENTS.md was found in the local
repository, installed skill/package locations or adjacent project tree during
this work. Existing repository conventions take precedence: root-only providers,
root default tags, environment directories and mandatory AcopioID overrides on
site-specific resources are preserved. No generic sample layout or unrelated
module was adopted.
