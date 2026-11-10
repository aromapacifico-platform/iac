# HU #22 verification record

Executed locally on 2026-11-10 with Terraform 1.16.6 and hashicorp/aws 6.72.0.
The original branch `feat/22-network-module` and pre-existing untracked module
files were preserved. No applicable AGENTS.md was found.

## Results

| Directory | terraform validate | terraform test (AWS mocks, plan only) |
| --- | --- | --- |
| modules/network | Passed | 18 passed, 0 failed |
| modules/network/modules/hybrid | Passed | 7 passed, 0 failed |
| environments/network | Passed | 7 passed, 0 failed |
| environments/dev | Passed | 4 passed, 0 failed |
| environments/test | Passed | 4 passed, 0 failed |
| environments/prod | Passed | 4 passed, 0 failed |

Total after the final review: **44 passed, 0 failed**. The original `production_network_plan`,
`development_address_plan`, `test_address_plan`, `cauca_collection_center`,
`huila_collection_center` and `tolima_collection_center` scenarios remain intact
and pass. Assertions were preserved; mocks now provide distinct subnet/table IDs
during plan so new association assertions can compare the actual references.

`terraform fmt -recursive modules/network environments` was executed. The final
`terraform fmt -check -recursive modules/network environments` and
`git diff --check` passed. During the final review, TFLint **0.66.0** was
installed in `/tmp/aroma-tflint/bin`, with its official release SHA-256 checksum
verified before extraction. The unchanged repository `.tflint.hcl` initialized
AWS ruleset **0.50.0** in `/tmp/aroma-tflint/plugins`. The final invocation:

```sh
TFLINT_PLUGIN_DIR=/tmp/aroma-tflint/plugins /tmp/aroma-tflint/bin/tflint \
  --recursive --config="$PWD/.tflint.hcl" --format=compact
```

passed with exit code **0**, no findings, across the entire repository (including
bootstrap and all changed modules/roots). No rule was disabled and no ignore
annotation was added. Its plugins require sandbox escalation, like Terraform's
provider plugins. Tests/validate were rerun after all functional corrections;
TFLint was rerun after the endpoint policy validation changes.

The four roots and hybrid child were initialized with `-backend=false`;
`modules/network` reused its existing provider installation. No remote backend
was contacted. Provider processes cannot
start in this sandbox; validation and tests ran with sandbox escalation. The
first local-mirror attempt for the workload roots failed because their existing
h1 checksum did not cover the available Linux package. A normal Terraform
registry download verified the release as **signed by HashiCorp**. Its binary and
LICENSE SHA-256 hashes matched the already installed module package. Only then
`terraform providers lock -fs-mirror=... -platform=linux_amd64` added the matching
Linux h1 checksum, retaining every existing hash and recording the combined
provider constraints. The mirror command reports `unauthenticated` because it
cannot itself verify a release signature; provenance came from the preceding
normal registry installation. No existing hash was removed or replaced.

## Acceptance evidence

| Requirement | Evidence |
| --- | --- |
| Exact fourteen subnets, two AZs, all three environments | Original three address-plan tests and three root integration tests |
| No overlap with any of the three collection centers | Approved /16 validation, exact subnet assertions, explicit non-overlap assertion and rejected acopio /16 input |
| Change department without editing resources | Original three site output scenarios and three central VPN/ASN/routing scenarios |
| Reject invalid inputs | Department, overlapping CIDR, duplicate/missing/wrong-region AZs, endpoint JSON/services/SG, private CPE and unscoped deployment grants |
| Central TGW instead of per-environment VGW | Central ownership/create-or-reference tests, ASN 64512, explicit production RAM share, no VGW resource |
| VPN routes and associations | Internal VPC /24 routes, admin attachment pair, central VPN/production association and return route assertions |
| No routes when disabled; dev/test protected | Disabled-hybrid assertions, dev/test rejection scenarios and roots' default-disabled integration assertions |
| Gateway and hybrid S3 endpoints | All twelve internal route table associations; interface endpoint storage pair and supplied SG assertions |
| Two tunnels and safe PSK contract | IKEv2/BGP/SecretsManager configuration and safe output allowlist assertions; installed provider schema/source inspected |
| Central ownership/account isolation | Existing TGW validation, wrong-role/foreign-attachment rejection, ambiguous ownership rejection and production VPN handoff |
| DNS integration | Exact hub resolver /32 and site return /24 route assertions; external resolver/SG/VPC-route contract documented |

## Read-only AWS checks and unverified behavior

`aws sts get-caller-identity --profile aromapacifico-dev` succeeded. It establishes
the current caller's identity, not the role or existence of a Network account.
`aws ec2 describe-transit-gateways` in `us-east-1` with that profile returned an
empty list. This is limited to that caller's visible inventory in that region;
it does not establish organization-wide absence of a TGW.

No real infrastructure plan was attempted: the verified Network account/role,
central ownership decision, CPE public IP, actual scoped endpoint grants,
production attachment, encrypted VPN log group and security/DNS values were not
provided. Real AWS connectivity, secret redaction in a deployed state, BGP prefix
acceptance, MTU, tunnel failover, DNS resolution, S3 upload and firewall isolation
remain operational acceptance checks. No apply, destroy, import, credential/IAM
change, commit, push, merge or PR was performed.

The open security/function PRs still need their AWS ~>5.0 constraints reconciled
with the >=6.72.0 network contract before composing their modules. Their SG,
role/KMS and workload resources were not copied or merged. Optional hub resolver
infrastructure and hub VPC return routes remain with their existing owners; this
HU exposes and implements the documented integration contract, not a second hub.

## Final diff and contract review

The full tracked diff and every new source, test, lock and documentation file were
reviewed, including files still untracked by Git. Resource scope inventory:

| Location | Resource groups | Why they belong to #22 |
| --- | --- | --- |
| Environment network | VPC, 14 subnets, IGW, 14 route tables/associations, 2 public internet routes | Approved environment address/routing plan |
| Environment network | S3/DynamoDB gateway endpoints, optional S3 interface endpoint | In-VPC AWS access and the explicitly required hybrid S3 contract |
| Environment network | Optional administration-subnet TGW attachment and 24 operational /24 routes | One environment's association with one selected collection center |
| Central hybrid | Customer Gateway, single two-tunnel BGP VPN | Single-department encrypted hybrid pattern |
| Central hybrid | Attachment accepter, isolated TGW route table, explicit associations and operational/production routes | Cross-account acceptance, return paths and isolation |
| Central hybrid | Optional hub DNS /32 and operational return routes | Explicit DNS path for the approved existing central hub; no second hub created |
| Network root | Optional single central TGW, production-only RAM share/associations | Unique central ownership and cross-account access to that TGW |

The two read-only central data sources are scoped deliberately: production
attachment lookup only when connection is enabled; existing-TGW lookup only when
its explicit reference mode is selected. In TGW creation mode with connection
disabled, both data sources have zero instances. The hybrid child needs no TGW ID
and has no resources or data sources when disabled. The central TGW/share root
still performs its independently requested ownership/sharing work when VPN is off.

Final review fixes and regression evidence:

- Raised network/root Terraform minimum to 1.11 because the declared 1.10 baseline
  could not parse plan-time mock overrides. This lower bound was established from
  upstream source; actual local execution remains Terraform 1.16.6, not a claimed
  execution on 1.11. AWS >=6.72 is the tested baseline, not its feature-introduction
  release. The README records exact pending PR version-file blob hashes, empty
  AWS v5/v6 range intersection and why provider aliases do not solve that conflict.
- Made the hybrid TGW ID optional while connection is null and required when it
  is enabled. The disabled case supplies no TGW ID; a new negative case rejects
  an enabled VPN without it. Disabled assertions cover every hybrid resource.
- Compared explicit `connection.production_collection_center_id` handoff metadata
  against the central department in both root and child. It must come from the
  same production output snapshot as the attachment ID. The new negative case
  selects Huila against a Cauca handoff. The AWS lookup independently verifies
  account and TGW; it does not assert a department. A proposed requester-tag check
  was removed during review because cross-account tags must not be assumed
  visible before owner-side acceptance/tagging. No tag replication infrastructure
  was added; central acceptance applies its own AcopioID tag.
- Rejected question-mark wildcards in endpoint principals/actions/resources and
  rejected DynamoDB table/* through named table/index ARN validation. Added both
  regression scenarios to each workload root. No original assertion was removed.
- Kept deployment prerequisites, hub DNS/SG/bucket policy dependencies, mocked
  plan limitations and untested real connectivity separate in the README.

No remaining blocker was found for accepting the self-contained #22 code under
its documented optional integration contracts. Pending security/function AWS v5
constraints block composing those PR modules in the same root until their owners
resolve the version conflict; they do not block initializing this code alone.
Actual account/role, TGW ownership selection, CPE IP, grants, SG/log group and DNS
values remain prerequisites for the corresponding real plans/deployment. Real
routing, DNS, S3, tunnel failover and secret-state redaction remain operational
acceptance work. No real infrastructure plan or AWS mutation was run in this
final review. Branch/index and pre-existing work were preserved; no commit,
push, merge or PR was made.
