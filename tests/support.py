import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
GIT = shutil.which("git")
BASHES = list(dict.fromkeys(filter(None, ["/bin/bash", shutil.which("bash")])))


class IsolatedTestCase(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name).resolve()
        self.home = self.directory / "home"
        self.home.mkdir()
        self.bin = self.directory / "bin"
        self.bin.mkdir()
        self.env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith(("GIT_", "XDG_", "DIRENV_", "__HM_", "STARSHIP_"))
            and key not in ("BASH_ENV", "ENV", "ZDOTDIR", "DOTFILES_LOCAL_NIX")
        }
        self.env.update(
            HOME=str(self.home),
            XDG_CONFIG_HOME=str(self.home / ".config"),
            XDG_DATA_HOME=str(self.home / ".local/share"),
            XDG_STATE_HOME=str(self.home / ".local/state"),
            XDG_CACHE_HOME=str(self.home / ".cache"),
            GIT_CONFIG_NOSYSTEM="1",
            PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
        )

    def run_command(self, args, *, cwd=None, check=True, env=None):
        return subprocess.run(
            [str(arg) for arg in args],
            cwd=cwd or self.directory,
            env=self.env if env is None else env,
            text=True,
            capture_output=True,
            check=check,
            timeout=60,
        )

    def git(self, *args, **kwargs):
        return self.run_command([GIT, *args], **kwargs)

    def stub(self, name, contents):
        target = self.bin / name
        target.write_text("#!/bin/sh\n" + contents)
        target.chmod(0o755)
        return target
