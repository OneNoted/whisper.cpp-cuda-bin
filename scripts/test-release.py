"""Exercise release selection and publication recovery without external services."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


DETECT = Path(__file__).resolve().with_name("detect-release.sh")


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "PKGBUILD").write_text(
            "pkgver=1.9.2\npkgrel=5\n_libggml_pkgver=0.23.0\n_libggml_pkgrel=1\n"
        )
        curl = self.root / "curl"
        curl.write_text(
            '#!/usr/bin/env bash\nset -euo pipefail\n'
            'case "${!#}" in\n'
            '  */upstream) cat "$FIXTURES/upstream.json" ;;\n'
            '  */dependency) printf \'{"tag_name":"v0.23.0-1"}\' ;;\n'
            '  *) printf "%s" "${ASSET_STATUS:-200}" ;;\n'
            'esac\n'
        )
        curl.chmod(0o755)
        self.releases = [
            {"tag_name": tag, "draft": draft, "prerelease": pre}
            for tag, draft, pre in [
                ("b4938", False, False),
                ("v9.0.0", True, False),
                ("v8.0.0", False, True),
                ("v1.9.2", False, False),
            ]
        ]

    def detect(self, **overrides):
        (self.root / "upstream.json").write_text(json.dumps(self.releases))
        env = {
            "PATH": f"{self.root}:{os.environ['PATH']}",
            "FIXTURES": str(self.root),
            "UPSTREAM_RELEASE_API": "https://fixture/upstream",
            "LIBGGML_RELEASE_API": "https://fixture/dependency",
            "RELEASE_DOWNLOAD_URL": "https://fixture/download",
            **overrides,
        }
        return subprocess.run(
            ["bash", str(DETECT)], cwd=self.root, env=env,
            capture_output=True, text=True, check=False,
        )

    def test_stable_release_ignores_build_tags_drafts_and_prereleases(self):
        result = self.detect()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("should_release=false\n", result.stdout)

    def test_missing_asset_repairs_with_new_pkgrel(self):
        result = self.detect(ASSET_STATUS="404")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("should_release=true\n", result.stdout)
        self.assertIn("release_tag=v1.9.2-6\n", result.stdout)

    def test_service_failure_does_not_trigger_rebuild(self):
        result = self.detect(ASSET_STATUS="503")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("should_release=true", result.stdout)

    def test_no_stable_release_fails_before_build(self):
        self.releases = self.releases[:3]
        self.assertNotEqual(self.detect().returncode, 0)

    def test_invalid_override_fails_before_build(self):
        self.assertNotEqual(self.detect(UPSTREAM_VERSION_OVERRIDE="b4938").returncode, 0)

    def test_new_upstream_resets_pkgrel(self):
        result = self.detect(UPSTREAM_VERSION_OVERRIDE="v1.9.3")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("release_tag=v1.9.3-1\n", result.stdout)


if __name__ == "__main__":
    unittest.main()
