#!/usr/bin/env python3
"""Detects changed Terraform modules and environments in a Git Pull Request or commit range.

Enables selective execution in CI/CD to prevent redundant pipeline runs
across already validated modules.
Strict zero-emoji compliance.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from typing import Dict, List, Set


def get_git_diff_files(base_ref: str, head_ref: str = "HEAD") -> List[str]:
    """Return list of modified file paths between base_ref and head_ref."""
    try:
        cmd = ["git", "diff", "--name-only", f"{base_ref}...{head_ref}"]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        files = [line.strip() for line in result.stdout.splitlines() if line.strip()]
        return files
    except Exception as exc:
        sys.stderr.write(f"[WARN] Failed to get diff against {base_ref}: {exc}\n")
        # Fallback: inspect HEAD commit
        try:
            cmd = ["git", "diff", "--name-only", "HEAD~1", "HEAD"]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return [line.strip() for line in result.stdout.splitlines() if line.strip()]
        except Exception:
            return []


def discover_all_modules(modules_dir: str = "modules") -> List[str]:
    """Discover all module directory paths under modules_dir."""
    modules: List[str] = []
    if not os.path.isdir(modules_dir):
        return modules

    for entry in sorted(os.listdir(modules_dir)):
        full_path = os.path.join(modules_dir, entry)
        if os.path.isdir(full_path) and not entry.startswith((".", "_")):
            # Must contain at least one .tf file
            has_tf = any(f.endswith(".tf") for f in os.listdir(full_path))
            if has_tf:
                modules.append(full_path.replace("\\", "/"))
    return modules


def discover_all_environments(env_dir: str = "environments") -> List[str]:
    """Discover all environment directories."""
    envs: List[str] = []
    if not os.path.isdir(env_dir):
        return envs

    for entry in sorted(os.listdir(env_dir)):
        full_path = os.path.join(env_dir, entry)
        if os.path.isdir(full_path) and not entry.startswith((".", "_")):
            envs.append(entry)
    return envs


def analyze_changes(
    changed_files: List[str],
    all_modules: List[str],
    all_envs: List[str],
    force_all: bool = False,
) -> Dict[str, Any]:
    """Analyze changed files and categorize into target modules and environments."""
    if force_all or not changed_files:
        return {
            "modules": all_modules,
            "has_modules": len(all_modules) > 0,
            "environments": all_envs,
            "has_environments": len(all_envs) > 0,
            "all_triggered": True,
        }

    # Global files that trigger full validation across all modules
    global_triggers = {
        ".tflint.hcl",
        ".pre-commit-config.yaml",
        "infracost.yml",
        ".github/infracost.yml",
        "pytest.ini",
    }

    has_global_change = any(
        f in global_triggers or f.startswith(".github/workflows/")
        for f in changed_files
    )

    if has_global_change:
        return {
            "modules": all_modules,
            "has_modules": len(all_modules) > 0,
            "environments": all_envs,
            "has_environments": len(all_envs) > 0,
            "all_triggered": True,
        }

    changed_modules: Set[str] = set()
    changed_envs: Set[str] = set()

    for file_path in changed_files:
        norm = file_path.replace("\\", "/")
        parts = norm.split("/")

        if len(parts) >= 2 and parts[0] == "modules":
            mod_path = f"modules/{parts[1]}"
            if mod_path in all_modules:
                changed_modules.add(mod_path)

        if len(parts) >= 2 and parts[0] == "environments":
            env_name = parts[1]
            if env_name in all_envs:
                changed_envs.add(env_name)

        if parts[0] == "bootstrap":
            changed_envs.add("bootstrap")

    mod_list = sorted(list(changed_modules))
    env_list = sorted(list(changed_envs))

    return {
        "modules": mod_list,
        "has_modules": len(mod_list) > 0,
        "environments": env_list,
        "has_environments": len(env_list) > 0,
        "all_triggered": False,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Detect changed Terraform targets.")
    parser.add_argument("--base-ref", default="origin/main", help="Base Git ref to compare against.")
    parser.add_argument("--head-ref", default="HEAD", help="Head Git ref.")
    parser.add_argument("--force-all", action="store_true", help="Force selection of all targets.")
    args = parser.parse_args()

    all_modules = discover_all_modules("modules")
    all_envs = discover_all_environments("environments")
    changed_files = get_git_diff_files(args.base_ref, args.head_ref)

    results = analyze_changes(
        changed_files=changed_files,
        all_modules=all_modules,
        all_envs=all_envs,
        force_all=args.force_all,
    )

    modules_json = json.dumps(results["modules"])
    envs_json = json.dumps(results["environments"])

    print(f"[INFO] Changed modules detected: {results['modules']}")
    print(f"[INFO] Changed environments detected: {results['environments']}")
    print(f"[INFO] Full validation triggered: {results['all_triggered']}")

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as f:
            f.write(f"modules={modules_json}\n")
            f.write(f"has_modules={'true' if results['has_modules'] else 'false'}\n")
            f.write(f"environments={envs_json}\n")
            f.write(f"has_environments={'true' if results['has_environments'] else 'false'}\n")
            f.write(f"all_triggered={'true' if results['all_triggered'] else 'false'}\n")


if __name__ == "__main__":
    main()

