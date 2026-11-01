import json
import shutil
import unittest

from support import IsolatedTestCase, ROOT

NIX = shutil.which("nix")
ZSH = shutil.which("zsh")
SHELL_MODULE = ROOT / "home/common/shell.nix"


@unittest.skipUnless(NIX and ZSH, "Nix and zsh are required")
class ShellTests(IsolatedTestCase):
    def setUp(self):
        super().setUp()
        local = self.directory / "local.nix"
        local.write_text('''{
          username = "audit"; hostname = "audit-host";
          platform = "linux"; system = "x86_64-linux";
          homeDirectory = "/home/audit";
          git = { name = "Audit User"; email = "audit@example.invalid"; };
        }''')
        self.env["DOTFILES_LOCAL_NIX"] = str(local)
        self.env["USER"] = "dotfiles-test"
        self.profile = self.home / ".nix-profile/bin"
        self.profile.mkdir(parents=True)
        self.project = self.directory / "project/bin"
        self.project.mkdir(parents=True)
        for directory, label in ((self.profile, "profile"), (self.project, "project")):
            node = directory / "node"
            node.write_text(f"#!/bin/sh\nprintf '{label}\\n'\n")
            node.chmod(0o755)

    def shell_config(self, platform):
        expression = '''
          let
            f = builtins.getFlake ROOT;
            lib = f.inputs.nixpkgs.lib;
            evaluated = lib.evalModules {
              specialArgs.local.platform = PLATFORM;
              modules = [
                {
                  options.home = lib.mkOption { type = lib.types.attrsOf lib.types.anything; };
                  options.programs.zsh = lib.mkOption {
                    type = lib.types.submodule {
                      freeformType = lib.types.attrsOf lib.types.anything;
                      options.initContent = lib.mkOption { type = lib.types.lines; };
                    };
                  };
                  config.home.homeDirectory = HOME_DIRECTORY;
                }
                (builtins.toPath SHELL_MODULE)
              ];
            };
          in evaluated.config.programs.zsh.initContent
        '''.replace("SHELL_MODULE", json.dumps(str(SHELL_MODULE))).replace(
            "HOME_DIRECTORY", json.dumps(str(self.home))
        ).replace(
            "PLATFORM", json.dumps(platform)
        ).replace("ROOT", json.dumps(str(ROOT)))
        result = self.run_command(
            [NIX, "--extra-experimental-features", "nix-command flakes", "eval",
             "--impure", "--raw", "--expr", expression]
        )
        source = self.directory / f"shell-{platform}.zsh"
        source.write_text(result.stdout)
        return source

    def test_project_toolchain_keeps_priority_in_nested_shells(self):
        for platform in ("darwin", "linux"):
            with self.subTest(platform=platform):
                source = self.shell_config(platform)
                self.env["PATH"] = f"{self.project}:/usr/bin:/bin:{self.profile}"
                result = self.run_command(
                    [ZSH, "-f", "-c", '''
                      source "$1"
                      [[ $(node) = project ]] || exit 21
                      first_path=$PATH
                      source "$1"
                      [[ $PATH = "$first_path" ]] || exit 22
                      [[ $(node) = project ]] || exit 23
                    ''', "test-shell", source], check=False
                )
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_profile_is_available_before_choosing_editor(self):
        code = self.profile / "code"
        code.write_text("#!/bin/sh\nexit 0\n")
        code.chmod(0o755)
        source = self.shell_config("linux")
        self.env["PATH"] = "/usr/bin:/bin"
        result = self.run_command(
            [ZSH, "-f", "-c", '''
              source "$1"
              [[ ${path[(Ie)$2]} -gt 0 ]] || exit 21
              [[ $EDITOR = "code --wait" && $VISUAL = "$EDITOR" ]] || exit 22
            ''', "test-shell", source, self.profile], check=False
        )
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
