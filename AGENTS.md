# AromaPacifico infrastructure instructions

Work only in this Terraform repository. Preserve the current branch and existing changes. Read issue bodies, dependency issues and current architecture before implementing a story. Never initialize a repository in the parent directory. `../IaC` is a distinct, read-only instruction package; `../planning` is a read-only architecture checkout.

Use [.agents/skills/aromapacifico-devops/SKILL.md](.agents/skills/aromapacifico-devops/SKILL.md) for project infrastructure work. Its references and templates are relative to that skill directory. The original AGENTS.md and identical GEMINI.md were reviewed; these instructions adapt them without renaming either original file. No codex.md is used.

## Scope and governance

- AWS primary region: us-east-1; us-east-2 is reserved for sack lookup recovery. Azure is prepared connectivity/identity only. Separate Security, Network, dev (10.50/16), test (10.60/16), prod (10.70/16) accounts. Collection centers: Cauca 10.41/16, Huila 10.42/16, Tolima 10.43/16. Never overlap CIDRs.
- Epic 6 executable infrastructure timebox: 100 human hours over two weeks. Classify each issue by domain and E6 box; implement its infrastructure scope without inventing business applications.
- Do not run apply, destroy, import or AWS mutations. Use fmt, validate, TFLint and provider-mocked plan tests. A real plan requires separately supplied read access and is not implied by a mock result. Do not modify credentials, commit, push, merge or open PRs unless explicitly authorized.
- Production harvest freeze: 05:00–18:00 America/Bogota, except the approved incident process. The no-mutation restriction above still applies.
- Code, comments and READMEs in English. Explain work to the user in Spanish.
- No private keys, credentials or generated secrets in Terraform, state or committed variable files. For IoT, require an externally generated CSR or public certificate; never fall back to generating keys.
- Required provider default tags: FincaID=GLOBAL, DronID=NO-APLICA, AcopioID=MULTICENTRO, ViajeID=NO-APLICA, Ambiente=desarrollo/pruebas/produccion, Propietario=devops-fnc, Proyecto=AromaPacifico. Override FincaID on the farm's taggable resources and IoT thing attributes. Add resource Name and additional_tags without allowing identity overrides.

## PC-IAC rules and repository compatibility

Read the [26-rule matrix](.agents/skills/aromapacifico-devops/references/rules-matrix.md). Preserve the existing network/security interfaces; do not refactor them just to match old examples.

1. New reference modules have the ten standard root files and a working sample plus tests; extra test/lock files are allowed.
2. Variables have explicit types, descriptions and meaningful validation; dynamic resources use map(object) and for_each. Existing interfaces are retained.
3. Use snake_case, descriptive AWS names and root-built physical names. The historical 28-character target yields to existing security resource contracts and AWS-specific limits; document exceptions instead of silently truncating IAM targets.
4. Use provider default tags plus resource Name/additional_tags.
5. New modules accept aws.project. Existing environment/network default provider stays compatible; wire aws.project explicitly to it. Do not globally rename providers.
6. Current roots use Terraform >=1.11,<2 and AWS ~>6.0; network requires AWS >=6.72,<7. Keep existing locks; never downgrade to AWS 5.x. The legacy security minimum >=1.10 remains compatible.
7. Outputs need descriptions and must expose only required values; mark sensitive material appropriately.
8. S3 backend only in environment/bootstrap roots, SSE-KMS, native lockfile and versioning. No module backend.
9. Centralize transformations/conversions in locals.tf for new code.
10. Use for_each for dynamic resources, protect critical DynamoDB/KMS/VPC/state resources from destruction.
11. External infrastructure discovery belongs in roots. Preserve security's intrinsic account/region and IAM-document data sources.
12. Keep one organized locals block in new files; flatten nested maps where needed.
13. Module calls: source, providers, governance, shared dependencies, resource inputs. Local sources have no version argument; registry uses version, Git sources use ref.
14. Use dynamic blocks for repeated configurable nested blocks; avoid unnecessary dynamic constructs for fixed blocks.
15. Local relative sources are valid in this monorepo; released Git sources need SemVer refs.
16. Use OIDC/session credentials and external secret provisioning. Sensitive flags do not remove secrets from state.
17. Consume explicit module outputs in the same root or root data sources filtered by identity/tags. No circular dependencies.
18. Preserve existing tests; run fmt, validate, TFLint, mocked tests and applicable secret/security scans. Report unavailable checks accurately.
19. Avoid terraform_remote_state; document any justified exception.
20. KMS encryption, TLS>=1.2, specific data actions/resources, private workload access, S3 public access blocking where applicable. Explain AWS-required policy wildcards; do not copy broad egress or data permissions.
21. Complex root configuration flows from tfvars through variables and locals into modules.
22. Workload consumes network/security, never creates VPCs, subnets, security groups or IAM roles. Required IAM changes stay in security.
23. Keep reference modules focused on their service domain; ingest may group the IoT/DynamoDB/SQS reception boundary requested by #24.
24. Operational configuration originates in environment tfvars or explicit caller inputs, never invented account IDs or deployment credentials.
25. Root builds final names; modules receive them. Preserve existing security naming contracts.
26. Samples flow terraform.tfvars -> variables.tf -> locals.tf -> main.tf, with provider governance and no embedded credentials.

For #24 preserve at least five calendar years of telemetry/threshold history: disable TTL until a verified archive workflow exists. Do not advertise five-year immutable archival or an alert SLA from infrastructure-only code.
