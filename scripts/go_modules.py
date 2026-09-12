"""Resolve canonical Go module paths for GitHub-hosted applications."""

from __future__ import annotations

import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Callable


class GoModuleError(RuntimeError):
    """Base error for Go module discovery failures."""


class GoModuleNotFound(GoModuleError):
    """The repository does not expose a root go.mod at the requested ref."""


class GoModuleUnavailable(GoModuleError):
    """GitHub could not be reached or returned a transient error."""


class GoPackageMismatch(GoModuleError):
    """An install package cannot be mapped safely to the repository module."""


class GoModuleIdentityMismatch(GoModuleError):
    """A declared module resolves to a different source repository."""


_MODULE_RE = re.compile(
    r'^\s*module\s+(?:"([^"\r\n]+)"|`([^`\r\n]+)`|(\S+))'
    r"(?:\s+//.*)?\s*$",
    re.MULTILINE,
)
_SAFE_MODULE_RE = re.compile(r"^[A-Za-z0-9._~+\-/]+$")


def parse_module_path(go_mod: str) -> str:
    """Return the module directive from go.mod."""
    match = _MODULE_RE.search(go_mod)
    if match is None:
        raise GoModuleNotFound("go.mod has no module directive")
    module = next(part for part in match.groups() if part is not None).strip()
    if not module or not _SAFE_MODULE_RE.fullmatch(module):
        raise GoModuleNotFound(f"go.mod has invalid module path {module!r}")
    return module


def canonical_install_package(repo: str, package: str, module: str) -> str:
    """Rewrite a GitHub-derived package prefix to the declared module path.

    A command package below the module root keeps its subdirectory and version.
    Packages unrelated to either the repository or declared module are rejected
    instead of being guessed.
    """
    path, separator, version = package.rpartition("@")
    if not separator:
        path = package
        version_suffix = ""
    else:
        version_suffix = "@" + version

    if path == module or path.startswith(module + "/"):
        return path + version_suffix

    repo_prefix = "github.com/" + repo.strip("/")
    if path == repo_prefix:
        subdirectory = ""
    elif path.startswith(repo_prefix + "/"):
        subdirectory = path[len(repo_prefix) :]
    else:
        raise GoPackageMismatch(
            f"{package!r} is not within {repo_prefix!r} or {module!r}"
        )
    return module + subdirectory + version_suffix


def github_repo_from_module(module: str) -> str:
    """Return owner/repository for a github.com module path."""
    parts = module.split("/")
    if len(parts) < 3 or parts[0].lower() != "github.com":
        return ""
    return f"{parts[1]}/{parts[2]}"


class GitHubGoModClient:
    """Fetch root go.mod files through GitHub's contents API."""

    def __init__(
        self,
        *,
        token: str | None = None,
        base_url: str | None = None,
        timeout: float = 10.0,
        retries: int = 2,
        opener: Callable[..., object] | None = None,
    ) -> None:
        self.token = token if token is not None else (
            os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
        )
        self.base_url = (
            base_url or os.environ.get("GITHUB_API_URL") or "https://api.github.com"
        ).rstrip("/")
        self.timeout = timeout
        self.retries = retries
        self.opener = opener or urllib.request.urlopen

    def fetch(self, repo: str, ref: str = "") -> str:
        """Fetch a module path and verify that it resolves to the same repo."""
        parts = repo.strip("/").split("/")
        if len(parts) != 2 or not all(parts):
            raise GoModuleNotFound(f"invalid GitHub repository {repo!r}")

        owner, name = (urllib.parse.quote(part, safe="") for part in parts)
        endpoint = f"{self.base_url}/repos/{owner}/{name}/contents/go.mod"
        if ref:
            endpoint += "?" + urllib.parse.urlencode({"ref": ref})
        body = self._read(
            endpoint,
            accept="application/vnd.github.raw+json",
            subject=f"{repo}/go.mod",
            missing=f"github.com/{repo} has no root go.mod",
        )
        try:
            module = parse_module_path(body.decode("utf-8"))
        except UnicodeError as error:
            raise GoModuleUnavailable(
                f"github.com/{repo}/go.mod is not valid UTF-8"
            ) from error

        module_repo = github_repo_from_module(module)
        if not module_repo:
            raise GoModuleIdentityMismatch(
                f"{repo} declares non-GitHub module {module!r}; source identity "
                "cannot be verified automatically"
            )
        if module_repo.casefold() == repo.casefold():
            return module

        expected_id, expected_name = self._repo_identity(repo)
        module_id, module_name = self._repo_identity(module_repo)
        if expected_id != module_id:
            raise GoModuleIdentityMismatch(
                f"{repo} declares module {module!r}, which resolves to "
                f"{module_name} instead of {expected_name}"
            )
        return module

    def _repo_identity(self, repo: str) -> tuple[int, str]:
        parts = repo.strip("/").split("/")
        if len(parts) != 2 or not all(parts):
            raise GoModuleNotFound(f"invalid GitHub repository {repo!r}")
        owner, name = (urllib.parse.quote(part, safe="") for part in parts)
        endpoint = f"{self.base_url}/repos/{owner}/{name}"
        body = self._read(
            endpoint,
            accept="application/vnd.github+json",
            subject=repo,
            missing=f"github.com/{repo} was not found",
        )
        try:
            payload = json.loads(body)
            repo_id = int(payload["id"])
            full_name = str(payload["full_name"])
        except (KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
            raise GoModuleUnavailable(
                f"GitHub returned invalid repository metadata for {repo}"
            ) from error
        return repo_id, full_name

    def _read(
        self,
        endpoint: str,
        *,
        accept: str,
        subject: str,
        missing: str,
    ) -> bytes:
        request = urllib.request.Request(
            endpoint,
            headers={
                "Accept": accept,
                "X-GitHub-Api-Version": "2022-11-28",
                "User-Agent": "cliff-registry",
            },
        )
        if self.token:
            request.add_header("Authorization", "Bearer " + self.token)

        for attempt in range(self.retries + 1):
            try:
                with self.opener(request, timeout=self.timeout) as response:
                    return response.read()
            except urllib.error.HTTPError as error:
                if error.code == 404:
                    raise GoModuleNotFound(missing) from error
                if error.code not in (429, 500, 502, 503, 504):
                    raise GoModuleUnavailable(
                        f"GitHub returned HTTP {error.code} for {subject}"
                    ) from error
                last_error: Exception = error
            except (OSError, UnicodeError, urllib.error.URLError) as error:
                last_error = error

            if attempt < self.retries:
                time.sleep(0.25 * (attempt + 1))

        raise GoModuleUnavailable(
            f"could not fetch {subject}: {last_error}"
        ) from last_error
