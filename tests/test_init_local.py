import json
import shutil
import unittest

from support import BASHES, IsolatedTestCase, ROOT


class InitLocalTests(IsolatedTestCase):
    def setUp(self):
        super().setUp()
        self.local = self.home / ".config/dotfiles/local.nix"
        self.env["DOTFILES_LOCAL_NIX"] = str(self.local)
        self.stub("uname", 'case "$1" in -s) echo Linux;; -m) echo x86_64;; esac\n')
        self.stub("id", "echo audit\n")
        self.stub("hostname", "echo audit-host\n")
        self.env.pop("WSL_DISTRO_NAME", None)
        self.env.pop("WSL_INTEROP", None)
        self.git("config", "--global", "user.name", "Audit User")
        self.git("config", "--global", "user.email", "audit@example.invalid")

    def init(self, bash, *args):
        return self.run_command([bash, ROOT / "init-local.sh", *args], check=False)

    def test_invalid_identity_never_creates_or_replaces_config(self):
        original = '{ username = "preserve-me"; }\n'
        for bash in BASHES:
            for key in ("user.name", "user.email"):
                for value in ("Invalid\nValue", "Invalid\rValue"):
                    for existing in (False, True):
                        with self.subTest(bash=bash, key=key, value=value, existing=existing):
                            self.git("config", "--global", "user.name", "Audit User")
                            self.git("config", "--global", "user.email", "audit@example.invalid")
                            self.git("config", "--global", key, value)
                            self.local.parent.mkdir(parents=True, exist_ok=True)
                            if existing:
                                self.local.write_text(original)
                            elif self.local.exists():
                                self.local.unlink()
                            result = self.init(bash, "--force")
                            self.assertNotEqual(result.returncode, 0)
                            self.assertIn("must not contain newlines", result.stderr)
                            if existing:
                                self.assertEqual(self.local.read_text(), original)
                            else:
                                self.assertFalse(self.local.exists())
                            self.assertEqual(list(self.local.parent.glob("local.nix.tmp.*")), [])

    @unittest.skipUnless(shutil.which("nix"), "Nix is needed to verify string roundtrips")
    def test_valid_identity_roundtrips_without_extra_escaping(self):
        name = '監査 "Quote" \\ Path ${literal} # ; &'
        self.git("config", "--global", "user.name", name)
        for bash in BASHES:
            with self.subTest(bash=bash):
                result = self.init(bash, "--force")
                self.assertEqual(result.returncode, 0, result.stderr)
                value = self.run_command(
                    ["nix", "--extra-experimental-features", "nix-command", "eval",
                     "--impure", "--json", "--expr", f"(import {self.local}).git"]
                )
                self.assertEqual(json.loads(value.stdout), {"name": name, "email": "audit@example.invalid"})
                self.assertEqual(self.local.stat().st_mode & 0o777, 0o600)


if __name__ == "__main__":
    unittest.main()
