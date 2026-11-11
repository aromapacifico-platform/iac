#!/usr/bin/env python3
"""Partial structural/regex checks, adapted from the supplied AromaPacifico skill.

This is not an HCL parser, IAM analyzer, secret scanner or proof of all 26 rules.
It checks required files, module backends, variable metadata, suspicious literal
secrets and some workload domain boundaries. Run Terraform and security tools too.
Only reads the requested directory; caches and Git internals are excluded.
"""
import argparse
from pathlib import Path
import re

ROOT_FILES = (".gitignore", "CHANGELOG.md", "README.md", "data.tf", "locals.tf",
              "main.tf", "outputs.tf", "providers.tf", "variables.tf", "versions.tf")
SAMPLE_FILES = ("README.md", "data.tf", "locals.tf", "main.tf", "outputs.tf",
                "providers.tf", "variables.tf")
SECRETS = (
    r'(?i)(?:password|secret_key|aws_access_key_id|access_key|token)\s*=\s*["\'][^"\']{8,}["\']',
    r'AKIA[0-9A-Z]{16}',
    r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
)
FORBIDDEN_WORKLOAD = ("aws_vpc", "aws_subnet", "aws_security_group", "aws_iam_role")


def run_checks(target_dir, is_module=False, domain=None):
    """Return partial findings; success cannot establish full rule compliance."""
    target = Path(target_dir)
    if not target.is_dir():
        return [f"Target directory does not exist: {target}"], []
    errors = []
    if is_module:
        for parent, files in ((target, ROOT_FILES), (target / "sample", SAMPLE_FILES)):
            errors.extend(f"[PC-IAC-001/026] Missing required file: {parent / name}"
                          for name in files if not (parent / name).is_file())
    for path in sorted(target.rglob("*.tf")):
        parts = path.relative_to(target).parts
        if any(part in (".terraform", ".git", ".agents") for part in parts):
            continue
        text = path.read_text(encoding="utf-8")
        if is_module and "sample" not in parts and re.search(r'\bbackend\s+"[a-z0-9]+"\s*\{', text):
            errors.append(f"[PC-IAC-008] Backend in reusable module: {path}")
        if path.name == "variables.tf":
            for name, body in re.findall(r'variable\s+"([^"]+)"\s*\{(.*?)\n\}', text, re.S):
                for field in ("type", "description", "validation"):
                    if not re.search(rf'\b{field}\b', body):
                        errors.append(f"[PC-IAC-002] Variable {name} lacks {field}: {path}")
        if any(re.search(pattern, text) for pattern in SECRETS):
            errors.append(f"[PC-IAC-016] Suspicious literal secret: {path}")
        if domain == "workload":
            for resource in FORBIDDEN_WORKLOAD:
                if re.search(rf'\bresource\s+"{resource}"\s+"', text):
                    errors.append(f"[PC-IAC-022] Workload creates {resource}: {path}")
    return errors, []


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path")
    parser.add_argument("--module", action="store_true")
    parser.add_argument("--domain", choices=("networking", "security", "workload"))
    args = parser.parse_args()
    errors, _ = run_checks(args.path, args.module, args.domain)
    print("Partial structural/regex audit; does NOT verify all 26 PC-IAC rules.")
    for error in errors:
        print(f"FAIL: {error}")
    print(f"Partial checks: {len(errors)} finding(s).")
    return bool(errors)


if __name__ == "__main__":
    raise SystemExit(main())
