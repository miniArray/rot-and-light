#!/usr/bin/env -S nix shell nixpkgs#python3 nixpkgs#bash --command python3
"""Exercise the shell runner with controlled Godot command exit/output cases."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
COMMAND = '''#!/usr/bin/env python3
import os
from pathlib import Path
import sys

if os.environ.get("VERIFY_ISOLATION"):
    for kind in ("CONFIG", "DATA", "CACHE"):
        value = os.environ.get("XDG_" + kind + "_HOME", "")
        if not value or value == os.environ.get("ORIGINAL_" + kind):
            sys.exit(43)
    settings = Path(os.environ["XDG_CONFIG_HOME"]) / "godot/editor_settings-4.7.tres"
    if "export/android/shutdown_adb_on_exit = false" not in settings.read_text():
        sys.exit(44)
if "--import" in sys.argv:
    count = Path("import_count")
    attempt = int(count.read_text()) + 1 if count.exists() else 1
    count.write_text(str(attempt))
    if os.environ.get("SCRIPT_ERROR"):
        print("SCRIPT ERROR: deliberate runner test")
    failures = int(os.environ.get("IMPORT_FAILURES", "0"))
    sys.exit(42 if attempt <= failures else 0)
sys.exit(int(os.environ.get("TEST_EXIT", "0")))
'''


class GodotRunnerTest(unittest.TestCase):
    def run_case(self, **settings):
        with tempfile.TemporaryDirectory(prefix="rot-and-light-runner-") as temporary:
            root = Path(temporary)
            (root / "scripts").mkdir()
            (root / "godot/tests").mkdir(parents=True)
            (root / "bin").mkdir()
            (root / "godot/tests/runner_test.gd").touch()
            runner = root / "scripts/test-godot"
            shutil.copyfile(ROOT / "scripts/test-godot", runner)
            command = root / "bin/godot4"
            command.write_text(COMMAND)
            command.chmod(0o755)
            env = dict(os.environ, **settings)
            for kind in ("CONFIG", "DATA", "CACHE"):
                env["ORIGINAL_" + kind] = env.get("XDG_" + kind + "_HOME", "")
            env["PATH"] = str(root / "bin") + os.pathsep + env["PATH"]
            result = subprocess.run(["bash", str(runner)], env=env, text=True,
                                    capture_output=True, timeout=10)
            count = root / "import_count"
            return result, int(count.read_text()) if count.exists() else 0

    def test_two_failed_imports_fail_the_runner(self):
        result, attempts = self.run_case(IMPORT_FAILURES="2")
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(attempts, 2)

    def test_one_transient_import_failure_can_retry(self):
        result, attempts = self.run_case(IMPORT_FAILURES="1")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(attempts, 2)

    def test_script_errors_are_not_retried_or_suppressed(self):
        result, attempts = self.run_case(IMPORT_FAILURES="1", SCRIPT_ERROR="1")
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(attempts, 1)

    def test_test_exit_is_preserved(self):
        result, _ = self.run_case(TEST_EXIT="42")
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_godot_profile_is_isolated(self):
        result, _ = self.run_case(VERIFY_ISOLATION="1")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
