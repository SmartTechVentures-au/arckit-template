"""Regression tests for provisioning, independent of network or credentials."""

import importlib.util
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location(
    "cursor_sync", ROOT / ".devcontainer/sync_cursor_commands.py"
)
cursor_sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cursor_sync)


class ProvisioningTests(unittest.TestCase):
    def test_partial_plugin_install_is_repaired_and_repeated_setup_is_idempotent(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            state = root / "state.json"
            state.write_text(
                json.dumps({"claude": ["arckit@arc-kit"], "codex": False, "events": []})
            )
            mock = root / "mock-cli"
            shutil.copy(ROOT / "tests/mock_plugin_cli.py", mock)
            mock.chmod(0o755)
            for name in ("claude", "codex"):
                (root / name).symlink_to(mock)
            installer = root / "install-plugins.sh"
            shutil.copy(ROOT / ".devcontainer/install-plugins.sh", installer)
            (root / "sync-cursor-commands.sh").write_text("exit 0\n")
            env = {
                **os.environ,
                "PATH": f"{root}:{os.environ['PATH']}",
                "ARCKIT_TEST_PLUGIN_STATE": str(state),
            }
            for _ in range(2):
                subprocess.run(["bash", str(installer)], env=env, check=True)
            self.assertEqual(
                json.loads(state.read_text())["events"],
                ["claude install arckit-au@arc-kit", "codex add arckit-codex@arckit"],
            )
            # An optional Claude failure must be reported, and must not stop
            # Codex installation from being attempted.
            state.write_text(json.dumps({"claude": [], "codex": False, "events": []}))
            result = subprocess.run(
                ["bash", str(installer)],
                env={**env, "ARCKIT_TEST_FAIL_CLAUDE": "1"},
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("WARNING: Claude", result.stderr)
            self.assertTrue(json.loads(state.read_text())["codex"])

    def test_cursor_preserves_custom_commands_and_removes_stale_managed_links(self):
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary) / "renamed workspace"
            marketplace = Path(temporary) / "marketplace"
            source = marketplace / "arckit-claude/commands"
            source.mkdir(parents=True)
            for name in ("custom", "linked", "managed", "stale"):
                (source / f"{name}.md").write_text(name)
            commands = workspace / ".cursor/commands"
            commands.mkdir(parents=True)
            custom = commands / "arckit-custom.md"
            custom.write_text("keep me")
            unrelated = commands / "arckit-linked.md"
            unrelated.symlink_to("missing-user-target")
            cursor_sync.sync(workspace, marketplace)
            self.assertEqual(custom.read_text(), "keep me")
            self.assertEqual(str(unrelated.readlink()), "missing-user-target")
            self.assertTrue((commands / "arckit-managed.md").is_symlink())
            (source / "stale.md").unlink()
            project = workspace / ".arckit/plugin-arckit/commands"
            project.mkdir(parents=True)
            (project / "managed.md").write_text("project override")
            cursor_sync.sync(workspace, marketplace)
            self.assertFalse((commands / "arckit-stale.md").is_symlink())
            self.assertEqual(
                (commands / "arckit-managed.md").read_text(), "project override"
            )
            (commands / "arckit-managed.md").unlink()
            (commands / "arckit-managed.md").write_text("user replacement")
            cursor_sync.sync(workspace, marketplace)
            self.assertEqual(
                (commands / "arckit-managed.md").read_text(), "user replacement"
            )

    def test_git_identity_is_applied_and_repeated_start_does_not_duplicate_paths(self):
        with tempfile.TemporaryDirectory() as temporary:
            config = Path(temporary) / "gitconfig"
            env = {
                **os.environ,
                "GIT_CONFIG_GLOBAL": str(config),
                "GIT_CONFIG_NOSYSTEM": "1",
                "GIT_USERNAME": "Example Developer",
                "GIT_EMAIL": "developer@example.test",
                "GH_TOKEN": "",
                "GITHUB_TOKEN": "",
            }
            for _ in range(2):
                subprocess.run(
                    ["bash", str(ROOT / ".devcontainer/configure-git.sh")],
                    env=env,
                    check=True,
                )

            def get(key):
                return subprocess.check_output(
                    ["git", "config", "--global", "--get-all", key],
                    env=env,
                    text=True,
                ).splitlines()

            self.assertEqual(get("user.name"), ["Example Developer"])
            self.assertEqual(get("user.email"), ["developer@example.test"])
            self.assertEqual(get("safe.directory"), [str(ROOT)])

    def test_configuration_is_valid_json_and_uses_container_env_file(self):
        config = json.loads((ROOT / ".devcontainer/devcontainer.json").read_text())
        self.assertEqual(
            config["runArgs"], ["--env-file", "${localWorkspaceFolder}/.env"]
        )
        self.assertNotIn("OPENAI_API_KEY", config["containerEnv"])
        for name in (
            "package.json",
            ".vscode/tasks.json",
            ".devcontainer/devcontainer-lock.json",
        ):
            json.loads((ROOT / name).read_text())


if __name__ == "__main__":
    unittest.main()
