"""Mirror ArcKit commands, changing only symlinks owned by this synchroniser."""

import json
from pathlib import Path


def sync(workspace: Path, marketplace: Path) -> None:
    destination = workspace / ".cursor/commands"
    destination.mkdir(parents=True, exist_ok=True)
    manifest = destination / ".arckit-managed.json"
    previous = json.loads(manifest.read_text()) if manifest.exists() else {}
    desired = {}
    # Project commands override AU, which overrides core commands.
    for source in (
        marketplace / "arckit-claude/commands",
        marketplace / "arckit-au/commands",
        workspace / ".arckit/plugin-arckit/commands",
    ):
        for command in sorted(source.glob("*.md")):
            if command.is_file():
                desired[f"arckit-{command.stem}.md"] = str(command.resolve())

    managed = {}
    for name, target in previous.items():
        # Do not allow a malformed manifest to address files outside commands/.
        if Path(name).name != name:
            raise ValueError("Invalid managed command name")
        path = destination / name
        if path.is_symlink() and str(path.readlink()) == target:
            path.unlink()
    for name, target in desired.items():
        path = destination / name
        if path.exists() or path.is_symlink():
            print(f"Preserving custom Cursor command: {name}")
            continue
        path.symlink_to(target)
        managed[name] = target
    temporary = manifest.with_suffix(".tmp")
    temporary.write_text(json.dumps(managed, indent=2) + "\n")
    temporary.replace(manifest)
    print(f"Cursor: {len(managed)} ArcKit commands synced")


if __name__ == "__main__":
    sync(
        Path(__file__).resolve().parent.parent,
        Path.home() / ".claude/plugins/marketplaces/arc-kit/plugins",
    )
