#!/usr/bin/env python3
"""Unit tests for the Coffee Harvest Window Freeze Gatekeeper.

Tests all operational scenarios, edge cases, timezone conversions,
calendar configurations, and emergency bypass mechanics.
Strict zero-emoji compliance.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Generator

import pytest

# Ensure script directory is accessible
SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))

import check_harvest_window as gatekeeper
from check_harvest_window import (
    BOGOTA_TZ,
    check_bypass,
    evaluate_harvest_window,
    is_harvest_season,
    is_in_restricted_hours,
    main,
    parse_timestamp,
)


class TestTimestampParsingAndTimezone:
    """Validate timestamp parsing and timezone localization."""

    def test_parse_iso_with_bogota_offset(self) -> None:
        raw = "2026-10-15T10:30:00-05:00"
        dt = parse_timestamp(raw)
        assert dt.hour == 10
        assert dt.minute == 30
        assert dt.tzinfo is not None

    def test_parse_iso_with_utc_z(self) -> None:
        # 15:00 UTC is 10:00 in America/Bogota (UTC-5)
        raw = "2026-10-15T15:00:00Z"
        dt = parse_timestamp(raw)
        assert dt.hour == 10
        assert dt.minute == 0

    def test_parse_naive_iso_defaults_to_bogota(self) -> None:
        raw = "2026-05-20T14:45:00"
        dt = parse_timestamp(raw)
        assert dt.hour == 14
        assert dt.minute == 45
        assert dt.tzinfo is not None

    def test_parse_date_only_format(self) -> None:
        raw = "2026-11-01"
        dt = parse_timestamp(raw)
        assert dt.year == 2026
        assert dt.month == 11
        assert dt.day == 1
        assert dt.hour == 0

    def test_invalid_format_raises_value_error(self) -> None:
        with pytest.raises(ValueError):
            parse_timestamp("invalid-date-string")


class TestRestrictedHours:
    """Validate exact boundaries for restricted hours (05:00:00 - 18:00:00)."""

    def test_before_restricted_window(self) -> None:
        dt = datetime(2026, 10, 15, 4, 59, 59, tzinfo=BOGOTA_TZ)
        assert not is_in_restricted_hours(dt)

    def test_start_of_restricted_window_boundary(self) -> None:
        dt = datetime(2026, 10, 15, 5, 0, 0, tzinfo=BOGOTA_TZ)
        assert is_in_restricted_hours(dt)

    def test_midday_within_restricted_window(self) -> None:
        dt = datetime(2026, 10, 15, 12, 0, 0, tzinfo=BOGOTA_TZ)
        assert is_in_restricted_hours(dt)

    def test_end_of_restricted_window_boundary(self) -> None:
        dt = datetime(2026, 10, 15, 18, 0, 0, tzinfo=BOGOTA_TZ)
        assert is_in_restricted_hours(dt)

    def test_immediately_after_restricted_window(self) -> None:
        dt = datetime(2026, 10, 15, 18, 0, 1, tzinfo=BOGOTA_TZ)
        assert not is_in_restricted_hours(dt)

    def test_night_time_outside_window(self) -> None:
        dt = datetime(2026, 10, 15, 23, 15, 0, tzinfo=BOGOTA_TZ)
        assert not is_in_restricted_hours(dt)

    def test_early_morning_midnight(self) -> None:
        dt = datetime(2026, 10, 15, 1, 30, 0, tzinfo=BOGOTA_TZ)
        assert not is_in_restricted_hours(dt)


class TestHarvestSeasonDetection:
    """Validate detection of harvest season months and custom weeks."""

    @pytest.mark.parametrize("month", [4, 5, 6, 9, 10, 11])
    def test_default_harvest_months(self, month: int) -> None:
        dt = datetime(2026, month, 15, 10, 0, 0, tzinfo=BOGOTA_TZ)
        assert is_harvest_season(dt)

    @pytest.mark.parametrize("month", [1, 2, 3, 7, 8, 12])
    def test_default_off_season_months(self, month: int) -> None:
        dt = datetime(2026, month, 15, 10, 0, 0, tzinfo=BOGOTA_TZ)
        assert not is_harvest_season(dt)

    def test_custom_harvest_weeks(self) -> None:
        # Week 42 in 2026 (mid-October)
        dt = datetime(2026, 10, 15, 10, 0, 0, tzinfo=BOGOTA_TZ)
        target_week = dt.isocalendar()[1]
        assert is_harvest_season(dt, harvest_weeks=[target_week])
        assert not is_harvest_season(dt, harvest_weeks=[target_week + 1])


class TestEvaluationScenarios:
    """Validate end-to-end evaluation logic."""

    def test_blocked_during_harvest_in_restricted_hours(self) -> None:
        dt = datetime(2026, 10, 15, 14, 0, 0, tzinfo=BOGOTA_TZ)
        res = evaluate_harvest_window(dt)
        assert not res["allowed"]
        assert res["blocked"]
        assert res["in_harvest_season"]
        assert res["in_restricted_hours"]
        assert not res["bypassed"]
        assert "BLOCKED" in res["reason"]

    def test_allowed_during_harvest_outside_hours_evening(self) -> None:
        dt = datetime(2026, 10, 15, 19, 30, 0, tzinfo=BOGOTA_TZ)
        res = evaluate_harvest_window(dt)
        assert res["allowed"]
        assert not res["blocked"]
        assert res["in_harvest_season"]
        assert not res["in_restricted_hours"]
        assert "ALLOWED" in res["reason"]
        assert "outside restricted harvest hours" in res["reason"]

    def test_allowed_during_harvest_outside_hours_early_morning(self) -> None:
        dt = datetime(2026, 10, 15, 4, 30, 0, tzinfo=BOGOTA_TZ)
        res = evaluate_harvest_window(dt)
        assert res["allowed"]
        assert not res["blocked"]
        assert "outside restricted harvest hours" in res["reason"]

    def test_allowed_outside_harvest_season_at_midday(self) -> None:
        # January is not in harvest season
        dt = datetime(2026, 1, 20, 12, 0, 0, tzinfo=BOGOTA_TZ)
        res = evaluate_harvest_window(dt)
        assert res["allowed"]
        assert not res["blocked"]
        assert not res["in_harvest_season"]
        assert "outside the scheduled harvest season" in res["reason"]

    def test_allowed_outside_harvest_season_in_july(self) -> None:
        # July is not in harvest season
        dt = datetime(2026, 7, 10, 15, 0, 0, tzinfo=BOGOTA_TZ)
        res = evaluate_harvest_window(dt)
        assert res["allowed"]
        assert not res["blocked"]
        assert not res["in_harvest_season"]


class TestEmergencyBypass:
    """Validate all emergency bypass mechanisms (CLI flag, env vars, labels, event JSON)."""

    def test_bypass_via_cli_flag(self) -> None:
        dt = datetime(2026, 10, 15, 14, 0, 0, tzinfo=BOGOTA_TZ)
        res = evaluate_harvest_window(dt, cli_bypass=True)
        assert res["allowed"]
        assert not res["blocked"]
        assert res["bypassed"]
        assert "Emergency bypass" in res["reason"]

    @pytest.mark.parametrize(
        "env_var,val",
        [
            ("EMERGENCY_OVERRIDE", "true"),
            ("EMERGENCY_OVERRIDE", "1"),
            ("INCIDENT_FLAG", "yes"),
            ("HOTFIX", "True"),
            ("DEPLOYMENT_OVERRIDE", "enabled"),
            ("HARVEST_BYPASS", "true"),
        ],
    )
    def test_bypass_via_env_var(
        self, monkeypatch: pytest.MonkeyPatch, env_var: str, val: str
    ) -> None:
        monkeypatch.setenv(env_var, val)
        bypassed, reason = check_bypass()
        assert bypassed
        assert env_var in reason

    def test_bypass_via_cli_label_incident(self) -> None:
        dt = datetime(2026, 10, 15, 14, 0, 0, tzinfo=BOGOTA_TZ)
        res = evaluate_harvest_window(dt, cli_labels=["incident"])
        assert res["allowed"]
        assert res["bypassed"]
        assert "incident" in res["reason"].lower()

    def test_bypass_via_cli_label_hotfix(self) -> None:
        dt = datetime(2026, 10, 15, 14, 0, 0, tzinfo=BOGOTA_TZ)
        res = evaluate_harvest_window(dt, cli_labels=["hotfix", "documentation"])
        assert res["allowed"]
        assert res["bypassed"]

    def test_bypass_via_env_labels(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setenv("PR_LABELS", "bug,emergency,database")
        bypassed, reason = check_bypass()
        assert bypassed
        assert "emergency" in reason

    def test_bypass_via_github_event_file_pull_request(
        self, tmp_path: Path
    ) -> None:
        payload = {
            "pull_request": {
                "number": 42,
                "labels": [
                    {"name": "backend"},
                    {"name": "incident"},
                ],
            }
        }
        event_file = tmp_path / "event.json"
        event_file.write_text(json.dumps(payload), encoding="utf-8")

        bypassed, reason = check_bypass(event_path=str(event_file))
        assert bypassed
        assert "incident" in reason

    def test_bypass_via_github_event_file_issue(self, tmp_path: Path) -> None:
        payload = {
            "issue": {
                "number": 101,
                "labels": [{"name": "hotfix"}],
            }
        }
        event_file = tmp_path / "issue_event.json"
        event_file.write_text(json.dumps(payload), encoding="utf-8")

        bypassed, reason = check_bypass(event_path=str(event_file))
        assert bypassed
        assert "hotfix" in reason

    def test_no_bypass_for_unrelated_labels(self, tmp_path: Path) -> None:
        payload = {
            "pull_request": {
                "labels": [{"name": "documentation"}, {"name": "enhancement"}],
            }
        }
        event_file = tmp_path / "normal_event.json"
        event_file.write_text(json.dumps(payload), encoding="utf-8")

        bypassed, _ = check_bypass(event_path=str(event_file))
        assert not bypassed


class TestCommandLineInterface:
    """Validate CLI execution, return codes, and formatting options."""

    def test_cli_blocked_exit_code_1(self) -> None:
        rc = main(["--timestamp", "2026-10-15T12:00:00-05:00"])
        assert rc == 1

    def test_cli_allowed_exit_code_0(self) -> None:
        rc = main(["--timestamp", "2026-10-15T20:00:00-05:00"])
        assert rc == 0

    def test_cli_emergency_override_exit_code_0(self) -> None:
        rc = main([
            "--timestamp", "2026-10-15T12:00:00-05:00",
            "--emergency",
        ])
        assert rc == 0

    def test_cli_check_only_returns_0_when_blocked(self) -> None:
        rc = main([
            "--timestamp", "2026-10-15T12:00:00-05:00",
            "--check-only",
        ])
        assert rc == 0

    def test_cli_json_output(self, capsys: pytest.CaptureFixture[str]) -> None:
        rc = main([
            "--timestamp", "2026-10-15T12:00:00-05:00",
            "--json",
            "--check-only",
        ])
        assert rc == 0
        captured = capsys.readouterr()
        data = json.loads(captured.out)
        assert data["allowed"] is False
        assert data["blocked"] is True
        assert data["in_harvest_season"] is True
        assert data["in_restricted_hours"] is True

    def test_github_output_written(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        gh_output_file = tmp_path / "github_output.txt"
        monkeypatch.setenv("GITHUB_OUTPUT", str(gh_output_file))

        rc = main([
            "--timestamp", "2026-10-15T12:00:00-05:00",
            "--check-only",
        ])
        assert rc == 0
        assert gh_output_file.exists()
        content = gh_output_file.read_text(encoding="utf-8")
        assert "allowed=false" in content
        assert "blocked=true" in content
        assert "in_harvest_season=true" in content
        assert "in_restricted_hours=true" in content
