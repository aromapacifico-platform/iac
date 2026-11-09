# Modules

Reusable modules called from `environments/<env>/main.tf`. Each one is built by its
planning issue and keeps the same layout: `main.tf`, `variables.tf`, `outputs.tf`,
`versions.tf` and a short `README.md`.

| Module | Issue | Implements |
| --- | --- | --- |
| `network` | [#22](https://github.com/aromapacifico-platform/planning/issues/22) | Environment VPC, subnets, gateway endpoints and the association with one collection center |
| `security` | [#23](https://github.com/aromapacifico-platform/planning/issues/23) | Platform identities, KMS keys and the permanent firewall rules from `rule_catalog` |
| `ingest` | [#24](https://github.com/aromapacifico-platform/planning/issues/24) | IoT Core rules, queues and the telemetry table |
| `farm` | [#24](https://github.com/aromapacifico-platform/planning/issues/24) | One pattern farm: things, certificates and policy bindings |
| `focus_function` | [#25](https://github.com/aromapacifico-platform/planning/issues/25) | S3 → Lambda → inference function that confirms a focus |

Rules for every module:

- No provider blocks inside modules. The environment configures the provider.
- No secrets as variables or outputs. Certificates and keys are created outside Terraform state.
- Resources that belong to a farm, drone, collection center or trip set the matching tag
  (`FincaID`, `DronID`, `AcopioID`, `ViajeID`); the rest inherit the environment defaults.
