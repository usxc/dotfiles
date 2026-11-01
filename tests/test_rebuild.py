import json
import shutil
import sys
import unittest

from support import BASHES, IsolatedTestCase, ROOT


NIX = shutil.which("nix")


@unittest.skipUnless(NIX, "Nix is required to check feature forwarding")
class RebuildTests(IsolatedTestCase):
    def setUp(self):
        super().setUp()
        self.log = self.directory / "commands.jsonl"
        self.env["DOTFILES_TEST_LOG"] = str(self.log)
        self.env["NIX_CONFIG"] = "experimental-features =\nextra-experimental-features =\n"
        self.python_stub("nix", f'''
import os, sys
args = sys.argv[1:]
if "eval" in args:
    os.execv({NIX!r}, [{NIX!r}, *args])
if "run" in args:
    separator = args.index("--")
    app = args[separator - 1].split("#")[1]
    os.execvp(app, [app, *args[separator + 1:]])
raise SystemExit("Unexpected Nix operation")
''')
        self.stub("sudo", 'shift\nexec "$@"\n')
        logger = '''
import json, os, sys
with open(os.environ["DOTFILES_TEST_LOG"], "a") as stream:
    stream.write(json.dumps({"command": os.path.basename(sys.argv[0]),
                             "args": sys.argv[1:],
                             "local": os.environ["DOTFILES_LOCAL_NIX"]}) + "\\n")
'''
        self.python_stub("darwin-rebuild", logger)
        self.python_stub("home-manager", logger + f'''
import subprocess
flags = []
args = iter(sys.argv[1:])
for arg in args:
    if arg == "--extra-experimental-features":
        flags.extend([arg, next(args)])
result = subprocess.run([{NIX!r}, *flags, "eval", "--expr",
                         "builtins.isFunction builtins.getFlake"],
                        capture_output=True, text=True)
sys.stderr.write(result.stderr)
raise SystemExit(result.returncode)
''')

    def python_stub(self, name, contents):
        target = self.bin / name
        target.write_text(f"#!{sys.executable}\n" + contents)
        target.chmod(0o755)

    def test_routes_and_feature_flags_without_activating_a_configuration(self):
        for bash in BASHES:
            for platform, wsl in (("darwin", False), ("linux", False), ("linux", True)):
                local = self.directory / "local.nix"
                local.write_text('''{
                  username = "audit"; hostname = "audit-host";
                  platform = PLATFORM; isWsl = WSL;
                }'''.replace("PLATFORM", json.dumps(platform)).replace("WSL", str(wsl).lower()))
                self.env["DOTFILES_LOCAL_NIX"] = str(local)
                for script in ("bootstrap.sh", "rebuild.sh"):
                    with self.subTest(bash=bash, platform=platform, wsl=wsl, script=script):
                        self.log.write_text("")
                        result = self.run_command([bash, ROOT / script], check=False)
                        self.assertEqual(result.returncode, 0, result.stderr)
                        command = json.loads(self.log.read_text())
                        expected = "darwin-rebuild" if platform == "darwin" else "home-manager"
                        self.assertEqual(command["command"], expected)
                        self.assertEqual(command["local"], str(local))
                        args = command["args"]
                        self.assertIn("switch", args)
                        self.assertIn("--impure", args)
                        target = ".#audit-host" if platform == "darwin" else ".#audit@audit-host"
                        self.assertEqual(args[args.index("--flake") + 1], target)
                        if platform == "linux":
                            self.assertEqual(args[args.index("-b") + 1], "backup")


if __name__ == "__main__":
    unittest.main()
