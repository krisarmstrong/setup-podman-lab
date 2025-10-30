# Repository Guidelines

## Project Structure & Module Organization
- Primary entrypoint is `setup-podman-lab.sh`, a Bash orchestrator that installs Podman, provisions the rootful machine, and writes Containerfiles into `~/PodmanProjects`.
- Persistent volumes are created under `~/PodmanData` (e.g., `~/PodmanData/librenms-data`) during execution; do not commit generated contents back into the repo.
- Keep additional helpers in the repo root; mirror their runtime output under `~/PodmanProjects/<component>` to stay consistent with the current layout.

## Build, Test, and Development Commands
- `./setup-podman-lab.sh` builds the full stack from scratch; expect ~15 containers and the Kali VNC desktop.
- `./setup-podman-lab.sh light` skips heavier dev images; use it when iterating on changes that do not touch the security tooling.
- `./setup-podman-lab.sh teardown` stops containers, removes images, and purges `~/PodmanProjects` / `~/PodmanData`.
- Use `podman ps`, `podman logs <name>`, and `podman machine inspect` for spot checks while developing or debugging.

## Coding Style & Naming Conventions
- Script is POSIX-friendly Bash; keep indentation at two spaces and prefer pipeline-friendly, set `-e` compatible constructs.
- Derive helper functions like `create_user_cmd()` with lower_snake_case names; reserve UPPERCASE for exported configuration such as `DEV_USER`.
- When adding Containerfiles, write them with explicit package lists and comment atypical choices inline so the generated files remain readable.

## Testing Guidelines
- Run `shellcheck setup-podman-lab.sh` before submitting; fix all warnings or justify suppressions in-line.
- Smoke test locally with `./setup-podman-lab.sh light` to validate machine provisioning and Containerfile generation; follow with `./setup-podman-lab.sh teardown` to verify cleanup paths.
- For changes affecting specific containers, rebuild just that directory via `podman build ~/PodmanProjects/<container>` to confirm the generated Containerfile is valid.

## Commit & Pull Request Guidelines
- The distributed snapshot lacks Git metadata; adopt imperative, present-tense commit subjects (e.g., `Add Kali desktop hardening defaults`) and include a brief body explaining runtime impact.
- Pull requests should summarize affected containers or host setup segments, link to tracked issues when available, and note manual validation steps (full run, light run, targeted build).
- Include relevant console snippets instead of screenshots unless GUI changes are involved; redact any sensitive credentials before sharing.

## Security & Configuration Tips
- Default credentials (`dev:dev`, `kali:kali`, etc.) are for lab use; highlight any alterations in your change notes so reviewers can update documentation.
- Confirm new network-facing services bind to expected ports and document them in `README.md` alongside existing access points.
