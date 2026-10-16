import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1]


class SourceOnlyTests(unittest.TestCase):
    def run_script(self, name, source_only, fail=False):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for tool, body in {
                'git': 'echo test-sha',
                'docker': '''echo "$*" >> "$MOCK_LOG"
case "$*" in
  *'info --json'*) echo '{"formulae":[{"installed":[{}]}]}' ;;
  *'brew test'*) exit "${FAIL_TEST:-0}" ;;
esac''',
            }.items():
                path = root / tool
                path.write_text('#!/bin/sh\n' + body + '\n')
                path.chmod(0o755)
            log = root / 'commands'
            env = dict(os.environ, PATH=f'{root}:{os.environ["PATH"]}',
                       MOCK_LOG=str(log), SOURCE_ONLY=str(source_only).lower(),
                       FAIL_TEST='1' if fail else '0', FORMULA='claude-code.latest',
                       UPLOAD='false')
            result = subprocess.run(['bash', str(SCRIPTS / name)], cwd=root,
                                    env=env, capture_output=True, text=True)
            return result, log.read_text()

    def test_source_only_uses_no_bottle_and_no_auto_sign(self):
        result, commands = self.run_script('build.sh', True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('brew install --build-from-source', commands)
        self.assertNotIn('--build-bottle', commands)
        self.assertIn('env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN', commands)

    def test_normal_formula_still_builds_bottle(self):
        result, commands = self.run_script('build.sh', False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('brew install --build-bottle', commands)

    def test_source_only_test_failure_is_blocking_without_upload(self):
        result, _ = self.run_script('test-gate.sh', True, fail=True)
        self.assertNotEqual(result.returncode, 0)


if __name__ == '__main__':
    unittest.main()
