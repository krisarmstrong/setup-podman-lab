"""Automation sessions for setup-podman-lab."""

from __future__ import annotations

import nox

nox.options.sessions = ["tests"]


@nox.session
def tests(session: nox.Session) -> None:
    """Run the test suite under the active interpreter."""
    session.install("-e", ".[dev]")
    session.run("pytest", "--cov", "--cov-report=term-missing")
