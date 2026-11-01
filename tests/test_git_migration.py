import os
import unittest

from support import BASHES, GIT, IsolatedTestCase, ROOT


MIGRATION = ROOT / "home/common/migrate-git-config.sh"


class GitMigrationTests(IsolatedTestCase):
    def setUp(self):
        super().setUp()
        self.legacy = self.home / ".gitconfig"
        self.managed = self.home / ".config/git/config"
        self.managed.parent.mkdir(parents=True)
        self.managed.write_text('''[user]
 name = Managed User
 email = managed@example.invalid
[init]
 defaultBranch = main
''')

    def migrate(self, bash=None, **kwargs):
        return self.run_command(
            [bash or BASHES[0], MIGRATION, self.legacy, self.managed], check=False, **kwargs
        )

    def backups(self):
        return list(self.home.glob(".gitconfig.before-dotfiles.*"))

    def test_managed_defaults_take_effect_and_migration_is_idempotent(self):
        original = '''[user]
 name = Old User
 name = Duplicate Old User
 email = old@example.invalid
[init]
 defaultBranch = legacy-master
'''
        for bash in BASHES:
            with self.subTest(bash=bash):
                self.legacy.write_text(original)
                self.legacy.chmod(0o640)
                previous_backups = set(self.backups())
                before = len(previous_backups)
                result = self.migrate(bash)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(len(self.backups()), before + 1)
                backup = (set(self.backups()) - previous_backups).pop()
                self.assertEqual(backup.read_text(), original)
                self.assertEqual(backup.stat().st_mode & 0o777, 0o600)
                self.assertEqual(self.legacy.stat().st_mode & 0o777, 0o640)
                self.assertEqual(self.git("config", "--get", "user.email").stdout.strip(),
                                 "managed@example.invalid")
                repository = self.directory / ("repo-" + str(before))
                self.git("init", "--quiet", repository)
                self.assertEqual(self.git("symbolic-ref", "--short", "HEAD", cwd=repository).stdout.strip(), "main")
                self.git("commit", "--quiet", "--allow-empty", "-m", "Audit identity", cwd=repository)
                self.assertEqual(self.git("log", "-1", "--format=%an <%ae>", cwd=repository).stdout.strip(),
                                 "Managed User <managed@example.invalid>")
                migrated = self.legacy.read_bytes()
                self.assertEqual(self.migrate(bash).returncode, 0)
                self.assertEqual(self.legacy.read_bytes(), migrated)
                self.assertEqual(len(self.backups()), before + 1)

    def test_preserves_signing_authentication_aliases_and_relative_conditional_includes(self):
        included = self.home / "extra/git.inc"
        included.parent.mkdir()
        included.write_text('[credential]\n helper = cache\n[alias]\n st = status\n')
        work_identity = self.home / "work.inc"
        work_identity.write_text('[user]\n name = Work User\n email = work@example.invalid\n')
        work = self.home / "work/project"
        work.parent.mkdir()
        self.git("init", "--quiet", work)
        original = f'''# Keep my non-managed settings.
[user]
 name = Old User
 email = old@example.invalid
 signingKey = audit-signing-key
[commit]
 gpgSign = true
[gpg]
 format = ssh
[include]
 path = extra/git.inc
[includeIf "gitdir:{self.home}/work/"]
 path = work.inc
'''
        self.legacy.write_text(original)
        result = self.migrate()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.backups()[0].read_text(), original)
        for key, value in (("user.signingKey", "audit-signing-key"), ("commit.gpgSign", "true"),
                           ("gpg.format", "ssh"), ("credential.helper", "cache"), ("alias.st", "status")):
            self.assertEqual(self.git("config", "--get", key).stdout.strip(), value)
        self.assertEqual(self.git("config", "--get", "user.email", cwd=work).stdout.strip(),
                         "work@example.invalid")
        self.assertEqual(included.read_text(), '[credential]\n helper = cache\n[alias]\n st = status\n')
        self.assertEqual(work_identity.read_text(), '[user]\n name = Work User\n email = work@example.invalid\n')
        self.assertIn("# Keep my non-managed settings.", self.legacy.read_text())

    def test_preserves_a_symlink_to_a_writable_config(self):
        target = self.directory / "external config.gitconfig"
        target.write_text('[user]\n name = Old User\n[alias]\n st = status\n')
        self.legacy.symlink_to("../external config.gitconfig")
        result = self.migrate()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(os.readlink(self.legacy), "../external config.gitconfig")
        self.assertEqual(self.git("config", "--get", "user.name").stdout.strip(), "Managed User")
        self.assertEqual(self.git("config", "--get", "alias.st").stdout.strip(), "status")

    def test_no_changes_for_missing_nonconflicting_or_already_managed_configs(self):
        self.assertEqual(self.migrate().returncode, 0)
        original = '[alias]\n st = status\n'
        self.legacy.write_text(original)
        self.assertEqual(self.migrate().returncode, 0)
        self.assertEqual(self.legacy.read_text(), original)
        self.legacy.unlink()
        self.legacy.symlink_to(self.managed)
        managed_before = self.managed.read_bytes()
        self.assertEqual(self.migrate().returncode, 0)
        self.assertEqual(self.managed.read_bytes(), managed_before)
        self.assertEqual(self.backups(), [])

    def test_dry_run_and_existing_lock_leave_config_untouched(self):
        original = '[user]\n name = Old User\n'
        self.legacy.write_text(original)
        result = self.migrate(env=dict(self.env, DRY_RUN="1"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.legacy.read_text(), original)
        self.assertEqual(self.backups(), [])
        lock = self.home / ".gitconfig.lock"
        lock.write_text("another Git process\n")
        result = self.migrate()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.legacy.read_text(), original)
        self.assertEqual(lock.read_text(), "another Git process\n")
        self.assertEqual(self.backups(), [])

    def test_edit_failure_preserves_original_and_removes_our_locks(self):
        original = '[user]\n name = Old User\n email = old@example.invalid\n'
        self.legacy.write_text(original)
        self.env["DOTFILES_TEST_GIT"] = GIT
        self.stub("git", '''case "$*" in
          *--unset-all*user.email*) exit 17;;
        esac
        exec "$DOTFILES_TEST_GIT" "$@"
''')
        result = self.migrate()
        self.assertEqual(result.returncode, 17)
        self.assertEqual(self.legacy.read_text(), original)
        self.assertEqual(self.backups()[0].read_text(), original)
        self.assertEqual(list(self.home.glob(".gitconfig.lock*")), [])

    def test_concurrent_edit_is_not_overwritten(self):
        original = '[user]\n name = Old User\n email = old@example.invalid\n'
        addition = '\n[alias]\n concurrent = status\n'
        self.legacy.write_text(original)
        self.env["DOTFILES_TEST_GIT"] = GIT
        self.env["DOTFILES_TEST_LEGACY"] = str(self.legacy)
        self.stub("git", '''case "$*" in
          *--unset-all*user.email*)
            printf '\\n[alias]\\n concurrent = status\\n' >> "$DOTFILES_TEST_LEGACY";;
        esac
        exec "$DOTFILES_TEST_GIT" "$@"
''')
        result = self.migrate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("changed during migration", result.stderr)
        self.assertEqual(self.legacy.read_text(), original + addition)
        self.assertEqual(self.backups()[0].read_text(), original)
        self.assertEqual(list(self.home.glob(".gitconfig.lock*")), [])

    def test_malformed_config_is_rejected_before_writing(self):
        original = '[user\n name = Invalid\n'
        self.legacy.write_text(original)
        result = self.migrate()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.legacy.read_text(), original)
        self.assertEqual(self.backups(), [])
        self.assertEqual(list(self.home.glob(".gitconfig.lock*")), [])


if __name__ == "__main__":
    unittest.main()
