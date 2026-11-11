#!/usr/bin/env python3
"""Supplementary Terraform expression tests without AWS resources/providers.

This executes selected existing test assertions against copies of the actual
module locals and variables. It does not validate AWS schemas, resource wiring,
certificate lifecycle, encryption settings or mocked provider behavior.
"""
from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CASES = {
    "ingest": {
        "farm_isolation", "reject_mqtt_wildcard_in_farm",
        "reject_wildcard_client", "reject_unscoped_role",
    },
    "farm": {
        "reject_empty_csr", "reject_private_key_as_csr", "reject_null_csr",
        "reject_invalid_farm_id",
    },
}


def main():
    env = dict(os.environ, CHECKPOINT_DISABLE="1")
    for module, selected in CASES.items():
        original = (ROOT / f"modules/{module}/tests/{module}.tftest.hcl").read_text()
        runs = list(re.finditer(r'^run "([^"]+)"', original, re.M))
        if not selected.issubset({match.group(1) for match in runs}):
            raise RuntimeError(f"Required expression cases missing in {module}")
        # These files have one shared variables block before all run blocks.
        start = original.index("\nvariables {") + 1
        variables = original[start:runs[0].start()]
        blocks = []
        for index, match in enumerate(runs):
            if match.group(1) not in selected:
                continue
            end = runs[index + 1].start() if index + 1 < len(runs) else len(original)
            block = original[match.start():end]
            blocks.append(block.replace("aws_iot_policy.this.policy", "local.device_policy")
                          .replace("aws_iot_topic_rule.this.sql", "local.rule_sql"))
        if module == "farm":
            # Negative CSR tests must be paired with an accepted public input.
            blocks.append('''
run "valid_public_csr_inputs" {
  command = plan
  assert {
    condition = local.attributes.FincaID == var.farm_id
    error_message = "Valid public CSR inputs must preserve the farm identity."
  }
}
''')
        with tempfile.TemporaryDirectory(prefix=f"aroma-{module}-expressions-") as directory:
            scratch = Path(directory)
            for name in ("variables.tf", "locals.tf"):
                shutil.copyfile(ROOT / f"modules/{module}/{name}", scratch / name)
            (scratch / "expressions.tftest.hcl").write_text(variables + "\n" + "".join(blocks))
            print(f"{module}: expression-only checks; no AWS schema/resource validation", flush=True)
            for args in (("init", "-backend=false", "-input=false", "-no-color"), ("test", "-no-color")):
                subprocess.run(["terraform", f"-chdir={scratch}", *args], env=env, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
