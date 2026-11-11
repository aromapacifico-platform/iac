#!/usr/bin/env bash
# Local-only checks: validate configured roots and run provider-mocked plan tests.
set -uo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
status=0
run_check() {
  if "$@"; then
    printf 'PASS: %s\n' "$*"
  else
    result=$?
    printf 'FAIL (%s): %s\n' "$result" "$*" >&2
    status=1
    return "$result"
  fi
}

# Child modules with configuration_aliases need their callers for validate.
# The samples supply aws.project = aws.principal; dev supplies aws.project = aws.
# Network and hybrid are validated through their existing environment callers.
# Mocks supply aliases during test runs, not during a standalone validate.
validation_roots=(
  modules/ingest/sample
  modules/farm/sample
  modules/security/sample
  environments/dev
  environments/test
  environments/prod
  environments/network
)
mocked_test_targets=(
  modules/ingest
  modules/farm
  modules/security
  modules/network
  modules/network/modules/hybrid
  environments/dev
  environments/test
  environments/prod
  environments/network
)
initialization_targets=(
  modules/ingest modules/farm modules/security
  modules/network modules/network/modules/hybrid
  "${validation_roots[@]}"
)

run_check terraform fmt -check -recursive
run_check terraform fmt -check -recursive .agents/skills/aromapacifico-devops/templates/module_scaffold
for module in ingest farm; do
  run_check python3 .agents/skills/aromapacifico-devops/scripts/validate_iac_rules.py "modules/$module" --module --domain workload
done
run_check python3 scripts/check-hu24-expressions.py

for target in "${initialization_targets[@]}"; do
  lock_args=()
  if test -f "$target/.terraform.lock.hcl"; then
    lock_args=(-lockfile=readonly)
  fi
  run_check terraform -chdir="$target" init -backend=false -input=false "${lock_args[@]}"
done
for target in "${validation_roots[@]}"; do
  run_check terraform -chdir="$target" validate
done
for target in "${mocked_test_targets[@]}"; do
  run_check terraform -chdir="$target" test
done
# TFLint and the configured AWS ruleset must already be installed.
run_check tflint --recursive
exit "$status"
