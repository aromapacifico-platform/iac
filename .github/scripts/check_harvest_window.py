#!/usr/bin/env python3
"""Coffee Harvest Window Freeze Gatekeeper.

Enforces production deployment freeze windows during harvest seasons
in coffee-producing departments (Cauca, Huila, Tolima) for the
Aroma Pacifico coffee traceability platform.

Deployment Freeze Rule:
- Restricted window: 05:00:00 to 18:00:00 (America/Bogota, UTC-5) inclusive
  during scheduled harvest weeks or months.
- Permitted windows:
  * Any time outside harvest seasons.
  * Outside 05:00:00-18:00:00 during harvest seasons (e.g., 18:00:01 to 04:59:59).
  * Emergency bypass with incident or hotfix flag/label.

Exit codes:
- 0: Deployment allowed.
- 1: Deployment blocked by harvest freeze policy.
- 2: Configuration or invocation error.
"""

from __future__ import annotations

import argparse
from datetime import datetime, time, timedelta, timezone
import json
import os
import sys
from typing import Any, Dict, List, Optional, Sequence, Tuple

try:
    from zoneinfo import ZoneInfo
    BOGOTA_TZ = ZoneInfo("America/Bogota")
except Exception:
    BOGOTA_TZ = timezone(timedelta(hours=-5), name="America/Bogota")

DEFAULT_HARVEST_MONTHS: Tuple[int, ...] = (4, 5, 6, 9, 10, 11)
BYPASS_LABELS: Tuple[str, ...] = (
    "incident",
    "emergency",
    "hotfix",
    "incident-override",
    "harvest-bypass",
    "critical-fix",
)
BYPASS_ENV_VARS: Tuple[str, ...] = (
    "EMERGENCY_OVERRIDE",
    "INCIDENT_FLAG",
    "HOTFIX",
    "DEPLOYMENT_OVERRIDE",
    "HARVEST_BYPASS",
)


def get_bogota_now() -> datetime:
    """Return current timestamp in America/Bogota timezone."""
    return datetime.now(BOGOTA_TZ)


def parse_timestamp(value: str) -> datetime:
    """Parse an ISO-8601 or date/time string into an aware America/Bogota datetime.

    Supports:
    - ISO strings with timezone offset (e.g. 2026-10-15T14:30:00-05:00)
    - ISO strings with UTC 'Z' (e.g. 2026-10-15T19:30:00Z)
    - Naive ISO strings (assumed to be America/Bogota local time)
    - YYYY-MM-DD HH:MM:SS or YYYY-MM-DD strings
    """
    cleaned = value.strip()
    if cleaned.endswith("Z") or cleaned.endswith("z"):
        dt = datetime.fromisoformat(cleaned[:-1] + "+00:00")
        return dt.astimezone(BOGOTA_TZ)

    try:
        dt = datetime.fromisoformat(cleaned)
    except ValueError:
        for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d"):
            try:
                dt = datetime.strptime(cleaned, fmt)
                break
            except ValueError:
                continue
        else:
            raise ValueError(f"Unsupported timestamp format: {value}")

    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=BOGOTA_TZ)
    else:
        dt = dt.astimezone(BOGOTA_TZ)
    return dt


def is_in_restricted_hours(dt: datetime) -> bool:
    """Check if the given datetime falls between 05:00:00 and 18:00:00 inclusive."""
    t = dt.time()
    start_time = time(5, 0, 0)
    end_time = time(18, 0, 0)
    return start_time <= t <= end_time


def is_harvest_season(
    dt: datetime,
    harvest_months: Sequence[int] = DEFAULT_HARVEST_MONTHS,
    harvest_weeks: Optional[Sequence[int]] = None,
) -> bool:
    """Check if date falls within a coffee harvest period.

    If harvest_weeks is supplied, week matching takes precedence.
    Otherwise, month matching is evaluated.
    """
    if harvest_weeks:
        iso_week = dt.isocalendar()[1]
        return iso_week in harvest_weeks
    return dt.month in harvest_months


def extract_labels_from_github_event(event_path: str) -> List[str]:
    """Extract label names from a GitHub Actions event payload JSON file."""
    labels: List[str] = []
    if not event_path or not os.path.exists(event_path):
        return labels

    try:
        with open(event_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        if isinstance(data, dict):
            pr = data.get("pull_request")
            if isinstance(pr, dict) and "labels" in pr:
                for item in pr["labels"]:
                    if isinstance(item, dict) and "name" in item:
                        labels.append(str(item["name"]))

            issue = data.get("issue")
            if isinstance(issue, dict) and "labels" in issue:
                for item in issue["labels"]:
                    if isinstance(item, dict) and "name" in item:
                        labels.append(str(item["name"]))
    except Exception as exc:
        sys.stderr.write(
            f"[WARN] Failed to parse GitHub event file {event_path}: {exc}\n"
        )

    return labels


def check_bypass(
    cli_flag: bool = False,
    cli_labels: Optional[Sequence[str]] = None,
    event_path: Optional[str] = None,
    extra_env_vars: Optional[Sequence[str]] = None,
) -> Tuple[bool, str]:
    """Determine whether emergency bypass is active.

    Returns a tuple (is_bypassed, reason).
    """
    if cli_flag:
        return True, "Emergency bypass flag provided via command-line."

    all_env_vars = list(BYPASS_ENV_VARS)
    if extra_env_vars:
        all_env_vars.extend(extra_env_vars)

    for var_name in all_env_vars:
        val = os.environ.get(var_name, "").strip().lower()
        if val in ("true", "1", "yes", "y", "enable", "enabled"):
            return True, f"Emergency bypass enabled via environment variable '{var_name}'."

    labels_to_check: List[str] = []
    if cli_labels:
        labels_to_check.extend(cli_labels)

    env_labels = os.environ.get("PR_LABELS") or os.environ.get("GITHUB_LABELS")
    if env_labels:
        labels_to_check.extend([lbl.strip() for lbl in env_labels.split(",") if lbl.strip()])

    path_to_check = event_path or os.environ.get("GITHUB_EVENT_PATH")
    if path_to_check:
        labels_to_check.extend(extract_labels_from_github_event(path_to_check))

    for label in labels_to_check:
        normalized = label.strip().lower()
        if normalized in BYPASS_LABELS or any(
            bp in normalized for bp in ("incident", "emergency", "hotfix")
        ):
            return True, f"Emergency bypass granted via label: '{label}'."

    return False, ""


def evaluate_harvest_window(
    dt: datetime,
    harvest_months: Sequence[int] = DEFAULT_HARVEST_MONTHS,
    harvest_weeks: Optional[Sequence[int]] = None,
    cli_bypass: bool = False,
    cli_labels: Optional[Sequence[str]] = None,
    event_path: Optional[str] = None,
) -> Dict[str, Any]:
    """Evaluate whether deployment is permitted at the specified datetime."""
    bypassed, bypass_reason = check_bypass(
        cli_flag=cli_bypass,
        cli_labels=cli_labels,
        event_path=event_path,
    )

    in_harvest = is_harvest_season(
        dt=dt,
        harvest_months=harvest_months,
        harvest_weeks=harvest_weeks,
    )
    in_hours = is_in_restricted_hours(dt)

    if bypassed:
        allowed = True
        reason = f"ALLOWED: {bypass_reason}"
    elif not in_harvest:
        allowed = True
        reason = (
            f"ALLOWED: Timestamp {dt.isoformat()} is outside the scheduled harvest "
            f"season (month {dt.month}, ISO week {dt.isocalendar()[1]})."
        )
    elif not in_hours:
        allowed = True
        reason = (
            f"ALLOWED: Timestamp {dt.isoformat()} is outside restricted harvest hours "
            f"(05:00-18:00 America/Bogota). Current time is {dt.strftime('%H:%M:%S')}."
        )
    else:
        allowed = False
        reason = (
            f"BLOCKED: Deployment frozen. Current time {dt.strftime('%H:%M:%S')} "
            f"is within 05:00:00 - 18:00:00 (America/Bogota, UTC-5) during harvest "
            f"season (month {dt.month}, week {dt.isocalendar()[1]}). "
            f"To bypass, tag with 'incident', 'emergency', or pass an approved override flag."
        )

    return {
        "allowed": allowed,
        "blocked": not allowed,
        "reason": reason,
        "timestamp": dt.isoformat(),
        "time_str": dt.strftime("%H:%M:%S"),
        "timezone": str(dt.tzinfo),
        "in_harvest_season": in_harvest,
        "in_restricted_hours": in_hours,
        "bypassed": bypassed,
        "bypass_reason": bypass_reason,
    }


def write_github_output(results: Dict[str, Any]) -> None:
    """Emit output variables for GitHub Actions steps if GITHUB_OUTPUT is set."""
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return

    try:
        with open(output_path, "a", encoding="utf-8") as f:
            f.write(f"allowed={'true' if results['allowed'] else 'false'}\n")
            f.write(f"blocked={'true' if results['blocked'] else 'false'}\n")
            f.write(f"in_harvest_season={'true' if results['in_harvest_season'] else 'false'}\n")
            f.write(f"in_restricted_hours={'true' if results['in_restricted_hours'] else 'false'}\n")
            f.write(f"bypassed={'true' if results['bypassed'] else 'false'}\n")
            clean_reason = results["reason"].replace("\n", " ")
            f.write(f"reason={clean_reason}\n")
    except Exception as exc:
        sys.stderr.write(f"[WARN] Failed to write to GITHUB_OUTPUT: {exc}\n")


def build_parser() -> argparse.ArgumentParser:
    """Construct CLI argument parser."""
    parser = argparse.ArgumentParser(
        description="Verify whether the current time falls inside the coffee harvest freeze window."
    )
    parser.add_argument(
        "--timestamp",
        type=str,
        default=None,
        help="ISO timestamp to evaluate (default: current system time in America/Bogota).",
    )
    parser.add_argument(
        "--harvest-months",
        type=str,
        default=None,
        help="Comma-separated harvest months (1-12). Default: 4,5,6,9,10,11 (Cauca/Huila/Tolima).",
    )
    parser.add_argument(
        "--harvest-weeks",
        type=str,
        default=None,
        help="Comma-separated ISO calendar weeks considered active harvest.",
    )
    parser.add_argument(
        "--emergency",
        "--incident",
        "--hotfix",
        "--override",
        dest="emergency",
        action="store_true",
        help="Authorize emergency bypass for production incident resolution.",
    )
    parser.add_argument(
        "--labels",
        type=str,
        default=None,
        help="Comma-separated PR or issue labels to inspect for bypass.",
    )
    parser.add_argument(
        "--github-event-path",
        type=str,
        default=None,
        help="Path to GitHub Actions event payload JSON file.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output evaluation result as formatted JSON.",
    )
    parser.add_argument(
        "--check-only",
        action="store_true",
        help="Always exit with code 0; useful for passive auditing without halting pipelines.",
    )
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    """Main CLI entrypoint."""
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.timestamp:
        try:
            target_dt = parse_timestamp(args.timestamp)
        except Exception as exc:
            sys.stderr.write(f"[ERROR] Failed to parse --timestamp: {exc}\n")
            return 2
    else:
        target_dt = get_bogota_now()

    months = DEFAULT_HARVEST_MONTHS
    if args.harvest_months:
        try:
            months = tuple(int(m.strip()) for m in args.harvest_months.split(",") if m.strip())
        except ValueError:
            sys.stderr.write("[ERROR] --harvest-months must be comma-separated integers (e.g. 4,5,6).\n")
            return 2

    weeks: Optional[List[int]] = None
    if args.harvest_weeks:
        try:
            weeks = [int(w.strip()) for w in args.harvest_weeks.split(",") if w.strip()]
        except ValueError:
            sys.stderr.write("[ERROR] --harvest-weeks must be comma-separated integers.\n")
            return 2

    cli_labels: List[str] = []
    if args.labels:
        cli_labels = [lbl.strip() for lbl in args.labels.split(",") if lbl.strip()]

    result = evaluate_harvest_window(
        dt=target_dt,
        harvest_months=months,
        harvest_weeks=weeks,
        cli_bypass=args.emergency,
        cli_labels=cli_labels,
        event_path=args.github_event_path,
    )

    write_github_output(result)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        prefix = "[INFO]" if result["allowed"] else "[BLOCK]"
        print(f"{prefix} {result['reason']}")
        print(
            f"       Timestamp: {result['timestamp']} | "
            f"Harvest Season: {result['in_harvest_season']} | "
            f"Restricted Window: {result['in_restricted_hours']} | "
            f"Bypass: {result['bypassed']}"
        )

    if args.check_only:
        return 0

    return 0 if result["allowed"] else 1


if __name__ == "__main__":
    sys.exit(main())
