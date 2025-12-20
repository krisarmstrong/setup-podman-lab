import os
import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = PROJECT_ROOT / "src" / "setup-podman-lab.sh"


def _base_env(tmp_path: Path) -> dict[str, str]:
    env = os.environ.copy()
    lab_root = tmp_path / "lab-root"
    logs_dir = lab_root / "logs"
    env["PODMAN_LAB_ROOT"] = str(lab_root)
    env["LAB_LOG_DIR"] = str(logs_dir)
    env["LAB_LOG_FILE"] = str(logs_dir / "test.log")
    env["LAB_SKIP_REGISTRY_CHECK"] = "1"
    env.setdefault("PATH", os.defpath)
    return env


def test_help_command_emits_usage(tmp_path):
    env = _base_env(tmp_path)
    result = subprocess.run(
        ["bash", str(SCRIPT), "--help"],
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )

    assert result.returncode == 0, result.stderr
    assert "Usage: setup-podman-lab.sh" in result.stdout


def test_lan_status_handles_missing_network(tmp_path):
    env = _base_env(tmp_path)
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    podman_stub = bin_dir / "podman"
    podman_stub.write_text(
        "#!/usr/bin/env bash\n"
        "if [ \"$1\" = \"network\" ] && [ \"$2\" = \"exists\" ]; then\n"
        "  exit 1\n"
        "fi\n"
        "exit 0\n"
    )
    podman_stub.chmod(0o755)

    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"

    result = subprocess.run(
        ["bash", str(SCRIPT), "lan-status"],
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )

    assert result.returncode == 0, result.stderr
    assert "LAN network not created" in result.stdout
