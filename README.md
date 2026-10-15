# ArcKit Workspace Template

A VS Code Dev Container with **Claude Code, Codex, and Cursor Agent CLI**,
Python 3.13, Node 22, GitHub CLI, Azure CLI, `uv`, Ruff, pytest, ShellCheck,
Graphviz, Marp, and Markdownlint. All three AI CLIs are installed in the image
and verified as the `vscode` user; an editor extension is not required to use them.

The container configures the Claude Code and Codex VS Code extensions, plus
Python, Markdown, Mermaid, draw.io, YAML, TOML, and formatting extensions.
Cursor Agent runs as `agent` (or `cursor-agent`) in the terminal. The Cursor
editor itself runs on your host; this template does not install a third-party
Cursor extension or replace the editor's `cursor` command.

## Getting started

1. Create a repository from this template and clone it. Install Docker and
   VS Code's Dev Containers extension, or use a Codespace.
2. **Before opening the container**, create your local environment file:
   ```bash
   cp .env.example .env
   ```
   Keep an existing `.env` when upgrading. Optional keys and Git identity are
   documented in `.env.example`; account login is also available for each CLI.
   An absent `.env` causes container creation to fail with a missing-file error.
   For a Codespace, create `.env` through its recovery container and rebuild.
3. Choose **Dev Containers: Reopen in Container**. The first build downloads
   the pinned CLI releases. Post-create configures Git and installs the optional
   ArcKit plugins. No personal credentials are needed to build the image.
4. Run `claude`, `codex`, or `agent` and follow that tool's sign-in prompts.
   API-key environment variables and account login are separate authentication
   methods; in Codex, follow its API-key login flow if using `OPENAI_API_KEY`.
5. Run `npm run serve` or the **Serve** task, then open the forwarded port 8080.

## Environment in every shell

The root `.env` is passed to Docker using `--env-file`. Variables are present
before lifecycle scripts, the editor server, tasks, debuggers, or terminals
start. Independent `docker exec` processes inherit them too, including Bash,
Zsh, and POSIX `sh`, in interactive, login, and non-interactive modes.
Applications that explicitly filter or clear their environment can still
remove variables (for example `env -i`, `sudo`, or agent-specific policies).

Use Docker env-file syntax:

```dotenv
GIT_USERNAME=Your Name
GIT_EMAIL=you@example.com
ARCKIT_PROFILE=development
```

Do not use `export`, quote values, or use shell substitutions such as `$HOME`
or `$(command)`: Docker treats values literally. Blank assignments explicitly
set an empty value; leave optional variables commented out instead. This file
is not sourced as shell code, and host variables are not implicitly forwarded.
Put the values you want in `.env`; there are no competing API-key overrides in
`containerEnv` or `.bashrc`.

**After changing `.env`, run Dev Containers: Rebuild Container.** An existing
container or a newly opened terminal does not reload Docker's environment.
The obsolete `scripts/load-env.sh` has been removed to prevent a second parser
from interpreting the same values differently.

When migrating: remove quotes/`export` from existing `.env` entries, replace
`GIT_PAT` with `GH_TOKEN`, and recreate the container. Git's GitHub helper uses
`GH_TOKEN` (or `GITHUB_TOKEN`) without copying the token into a credential file.
`AZURE_DEVOPS_EXT_PAT` is for Azure DevOps CLI; Git authentication for Azure
DevOps continues to use your forwarded credential helper.

## ArcKit plugins and Cursor commands

Post-create installs `arckit@arc-kit` and `arckit-au@arc-kit` for Claude,
checking each plugin separately, and `arckit-codex@arckit` for Codex. The Codex
repository is `tractorjuice/arckit-codex`; its marketplace is named `arckit`.
Optional plugin failures are reported and do not hide a missing required CLI.
Retry plugin installation with:

```bash
bash .devcontainer/install-plugins.sh
```

The compatibility command `bash scripts/claude.sh` invokes the same installer.
Post-start verifies all three CLIs, reapplies Git configuration, and resyncs
Cursor commands without requiring a marketplace download on every restart.

Cursor commands are generated in `.cursor/commands/` from the Claude marketplace.
Project commands in `.arckit/plugin-arckit/commands/` override the Australian
pack, which overrides core commands. The synchroniser tracks only its own
symlinks; hand-authored commands, user replacements, and unrelated symlinks
are preserved. Generated files are gitignored. Cursor command availability
depends on the optional Claude marketplace being installed successfully.

## Authentication and rebuilds

CLI sign-in state belongs to the container user's home, not the repository.
It survives stop/start but **is not guaranteed to survive a rebuild**. Sign in
again after rebuilding, or supply your own per-workspace persistent mounts for
the documented credential directories of the tools you use. Do not bake login
state into the image or commit it. This template deliberately does not share
one credential volume between unrelated projects. API keys in the host `.env`
are injected again when the container is recreated.

## Maintenance and validation

Core tool versions are Dockerfile build arguments. Node has one installation;
there is no duplicate Node feature. Claude, Codex, Cursor, Marp, Markdownlint,
Ruff, and uv have explicit version defaults. Upgrades should update those pins
and run the checks below. OS packages, remaining Python dependencies, and ArcKit
marketplaces still follow their upstream releases; this is not a fully locked
image. Native tools may also offer runtime updates. Prefer a rebuild to reset
the tools to the reviewed image versions.

```bash
python3 -m unittest discover -s tests -v
ruff check scripts/ .devcontainer/ tests/
ruff format --check scripts/ .devcontainer/ tests/
shellcheck scripts/*.sh .devcontainer/*.sh tests/*.sh
docker build -t arckit-template:test -f .devcontainer/Dockerfile .
bash tests/container-smoke.sh arckit-template:test
```

CI runs these checks. Smoke tests use dummy values, exercise independent shells
and CLI availability, check Git identity, and start the docs server. The server
rejects hidden files (including `.env` and `.git`) and escaping symlinks.
`.dockerignore` excludes local secrets, authentication state, and caches from
the build context. Keep `.env` out of Git; only `.env.example` is committed.

## License

[MIT](LICENSE)
