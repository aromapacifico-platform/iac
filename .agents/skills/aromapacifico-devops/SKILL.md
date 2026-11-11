---
name: aromapacifico-devops
description: Implement and review AromaPacifico Terraform stories, including project governance, domain boundaries, module interfaces and local validation.
---

# AromaPacifico DevOps

Read the repository [AGENTS.md](../../../AGENTS.md) first (from this directory, repository root is `../../..`). Follow the user's scope over historical examples. This adaptation targets Codex and preserves the supplied skill resources.

1. Read the full story and dependency issues. Classify domain and E6 box using [project context](references/project-context.md). Current repository code and approved architecture take precedence over examples.
2. Review the [26-rule matrix](references/rules-matrix.md) and [execution playbook](references/hu-execution-playbook.md). Apply the compatibility decisions in AGENTS.md, especially AWS 6.x, existing provider aliases, root naming and no AWS mutation.
3. Verify actual security/network inputs and outputs before wiring workloads. Security exports `kms_key_data_arn` and `role_ingest_arn`; it does not export `data_kms_key_arn`. Never create roles in a workload module.
4. Use the [scaffold](templates/module_scaffold/) and [examples](references/hu-examples.md) as starting points, adapting the actual interface. Local sources must not specify version. Samples need non-sensitive tfvars and validated external dependencies.
5. Inspect [validate_iac_rules.py](scripts/validate_iac_rules.py) before running it. It is a partial regex/structure check, not an HCL parser and not proof of all 26 rules. Run `python3 .agents/skills/aromapacifico-devops/scripts/validate_iac_rules.py modules/NAME --module --domain workload` from the repository root; run Terraform fmt/validate, TFLint and mocked tests separately.
6. Report adaptation changes separately from story implementation, actual check results and remaining integration limits. Code/comments/READMEs are English; user-facing explanations are Spanish.

## Portable architecture context

Paths here are relative to this skill directory, never to an Antigravity runtime:

- `../../../../planning/docs/`: optional sibling read-only planning checkout. It may be stale; compare the requested GitHub issue and current source.
- [context/carga-a-ingesta-telemetria.md](references/context/carga-a-ingesta-telemetria.md): supplied #12 design snapshot, including Basic Ingest, trusted topic identity and archive-before-TTL. Diagram links in that source snapshot refer to the original planning repository.
- [context/briefing-inicial-juniors.md](references/context/briefing-inicial-juniors.md): supplied base decisions snapshot.
- `references/rules/pc-iac-NNN.md`: all 26 supplied detailed rules. Historical text is read with AGENTS.md compatibility overrides, including the changed documentation language and provider versions.

No sibling directory is required for discovering the skill or its bundled context. If newer architecture is unavailable, state which snapshot was used. Never modify the sibling planning checkout or original instruction package.
