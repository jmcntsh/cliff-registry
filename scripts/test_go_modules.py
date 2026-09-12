from __future__ import annotations

import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import audit_go_modules
import seed
from go_modules import (
    GitHubGoModClient,
    GoModuleIdentityMismatch,
    GoModuleNotFound,
    GoPackageMismatch,
    canonical_install_package,
    parse_module_path,
)


class StubClient:
    def __init__(self, result: str | Exception) -> None:
        self.result = result
        self.calls: list[tuple[str, str]] = []

    def fetch(self, repo: str, ref: str = "") -> str:
        self.calls.append((repo, ref))
        if isinstance(self.result, Exception):
            raise self.result
        return self.result


class FakeResponse(io.BytesIO):
    def __enter__(self) -> FakeResponse:
        return self

    def __exit__(self, *_: object) -> None:
        self.close()


class ParseModulePathTests(unittest.TestCase):
    def test_parses_plain_and_quoted_directives(self) -> None:
        self.assertEqual(
            "example.com/tool",
            parse_module_path("module example.com/tool\n\ngo 1.22\n"),
        )
        self.assertEqual(
            "example.com/quoted",
            parse_module_path('module "example.com/quoted" // comment\n'),
        )

    def test_rejects_missing_directive(self) -> None:
        with self.assertRaises(GoModuleNotFound):
            parse_module_path("go 1.22\n")

    def test_rejects_unsafe_module_path(self) -> None:
        with self.assertRaises(GoModuleNotFound):
            parse_module_path("module `example.com/tool;echo-bad`\n")


class CanonicalPackageTests(unittest.TestCase):
    def test_rewrites_renamed_repository_owner(self) -> None:
        self.assertEqual(
            "github.com/old-owner/tool@latest",
            canonical_install_package(
                "new-owner/tool",
                "github.com/new-owner/tool@latest",
                "github.com/old-owner/tool",
            ),
        )

    def test_preserves_command_subdirectory_and_version(self) -> None:
        self.assertEqual(
            "example.com/tool/cmd/tool@v1.2.3",
            canonical_install_package(
                "owner/tool",
                "github.com/owner/tool/cmd/tool@v1.2.3",
                "example.com/tool",
            ),
        )

    def test_leaves_existing_canonical_package_unchanged(self) -> None:
        package = "charm.land/tool/v2/cmd/tool@latest"
        self.assertEqual(
            package,
            canonical_install_package(
                "owner/tool", package, "charm.land/tool/v2"
            ),
        )

    def test_rejects_unrelated_package(self) -> None:
        with self.assertRaises(GoPackageMismatch):
            canonical_install_package(
                "owner/tool",
                "github.com/someone-else/tool@latest",
                "example.com/tool",
            )


class GitHubClientTests(unittest.TestCase):
    def test_accepts_old_module_owner_when_github_redirects_to_same_repo(
        self,
    ) -> None:
        def opener(request: object, *, timeout: float) -> FakeResponse:
            del timeout
            url = request.full_url  # type: ignore[attr-defined]
            if url.endswith("/contents/go.mod?ref=main"):
                return FakeResponse(b"module github.com/old-owner/tool\n")
            if url.endswith("/repos/new-owner/tool"):
                payload = {"id": 7, "full_name": "new-owner/tool"}
            elif url.endswith("/repos/old-owner/tool"):
                payload = {"id": 7, "full_name": "new-owner/tool"}
            else:
                raise AssertionError(f"unexpected URL: {url}")
            return FakeResponse(json.dumps(payload).encode())

        client = GitHubGoModClient(opener=opener)
        self.assertEqual(
            "github.com/old-owner/tool",
            client.fetch("new-owner/tool", "main"),
        )

    def test_rejects_module_owned_by_different_repository(self) -> None:
        def opener(request: object, *, timeout: float) -> FakeResponse:
            del timeout
            url = request.full_url  # type: ignore[attr-defined]
            if url.endswith("/contents/go.mod"):
                return FakeResponse(b"module github.com/other/tool\n")
            if url.endswith("/repos/new-owner/tool"):
                payload = {"id": 7, "full_name": "new-owner/tool"}
            elif url.endswith("/repos/other/tool"):
                payload = {"id": 8, "full_name": "other/tool"}
            else:
                raise AssertionError(f"unexpected URL: {url}")
            return FakeResponse(json.dumps(payload).encode())

        client = GitHubGoModClient(opener=opener)
        with self.assertRaises(GoModuleIdentityMismatch):
            client.fetch("new-owner/tool")


class SeedInstallTests(unittest.TestCase):
    def test_go_install_uses_declared_module(self) -> None:
        client = StubClient("example.com/canonical/tool")
        got = seed.suggest_install(
            {
                "language": "Go",
                "fullName": "new-owner/tool",
                "name": "tool",
                "defaultBranch": "trunk",
            },
            go_module_client=client,
        )
        self.assertEqual(("go", "example.com/canonical/tool@latest"), got)
        self.assertEqual([("new-owner/tool", "trunk")], client.calls)


class AuditTests(unittest.TestCase):
    manifest = """\
name = "tool"
description = "A terminal tool"
author = "new-owner"
homepage = "https://github.com/new-owner/tool"

[install]
type = "go"
package = "github.com/new-owner/tool@latest"
"""

    def test_audit_reports_and_repairs_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            apps_dir = Path(directory)
            manifest_path = apps_dir / "tool.toml"
            manifest_path.write_text(self.manifest, encoding="utf-8")
            client = StubClient("github.com/old-owner/tool")

            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(
                io.StringIO()
            ):
                self.assertEqual(
                    1,
                    audit_go_modules.audit(
                        apps_dir,
                        fix=False,
                        strict=False,
                        workers=1,
                        client=client,
                    ),
                )
                self.assertEqual(
                    0,
                    audit_go_modules.audit(
                        apps_dir,
                        fix=True,
                        strict=False,
                        workers=1,
                        client=client,
                    ),
                )

            self.assertIn(
                'package = "github.com/old-owner/tool@latest"',
                manifest_path.read_text(encoding="utf-8"),
            )


if __name__ == "__main__":
    unittest.main()
