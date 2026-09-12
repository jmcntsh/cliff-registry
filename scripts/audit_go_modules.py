#!/usr/bin/env python3
"""Check or repair Go install paths against repositories' root go.mod files."""

from __future__ import annotations

import argparse
import concurrent.futures
import sys
import tomllib
import urllib.parse
from dataclasses import dataclass
from pathlib import Path

from go_modules import (
    GitHubGoModClient,
    GoModuleError,
    GoModuleNotFound,
    canonical_install_package,
)


@dataclass(frozen=True)
class GoInstall:
    manifest: Path
    repo: str
    package: str


def github_repo(homepage: str) -> str:
    parsed = urllib.parse.urlparse(homepage)
    if parsed.hostname not in ("github.com", "www.github.com"):
        return ""
    parts = [part for part in parsed.path.split("/") if part]
    if len(parts) < 2:
        return ""
    return f"{parts[0]}/{parts[1].removesuffix('.git')}"


def discover(apps_dir: Path) -> tuple[list[GoInstall], list[str]]:
    installs: list[GoInstall] = []
    warnings: list[str] = []
    for path in sorted(apps_dir.glob("*.toml")):
        try:
            manifest = tomllib.loads(path.read_text(encoding="utf-8"))
        except (OSError, tomllib.TOMLDecodeError) as error:
            warnings.append(f"{path}: cannot read manifest: {error}")
            continue

        methods = manifest.get("installs")
        if methods is None:
            single = manifest.get("install")
            methods = [single] if isinstance(single, dict) else []

        go_packages = [
            method.get("package", "")
            for method in methods
            if isinstance(method, dict) and method.get("type") == "go"
        ]
        if not go_packages:
            continue

        repo = github_repo(str(manifest.get("homepage", "")))
        if not repo:
            warnings.append(f"{path}: cannot derive GitHub repository from homepage")
            continue
        for package in go_packages:
            if package:
                installs.append(GoInstall(path, repo, str(package)))
    return installs, warnings


def audit(
    apps_dir: Path,
    *,
    fix: bool,
    strict: bool,
    workers: int,
    client: GitHubGoModClient | None = None,
) -> int:
    installs, warnings = discover(apps_dir)
    resolver = client or GitHubGoModClient()
    repos = sorted({install.repo for install in installs})

    modules: dict[str, str] = {}
    unavailable: dict[str, str] = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, workers)) as pool:
        futures = {repo: pool.submit(resolver.fetch, repo) for repo in repos}
        for repo, future in futures.items():
            try:
                modules[repo] = future.result()
            except GoModuleNotFound as error:
                unavailable[repo] = str(error)
            except GoModuleError as error:
                unavailable[repo] = str(error)
            except Exception as error:  # Keep one repository from aborting the audit.
                unavailable[repo] = f"unexpected resolver error: {error}"

    replacements: dict[Path, list[tuple[str, str]]] = {}
    mismatches: list[str] = []
    for install in installs:
        module = modules.get(install.repo)
        if module is None:
            continue
        try:
            canonical = canonical_install_package(
                install.repo, install.package, module
            )
        except GoModuleError as error:
            mismatches.append(f"{install.manifest}: {error}")
            continue
        if canonical != install.package:
            mismatches.append(
                f"{install.manifest}: {install.package} -> {canonical}"
            )
            replacements.setdefault(install.manifest, []).append(
                (install.package, canonical)
            )

    repaired = 0
    if fix:
        for path, changes in replacements.items():
            body = path.read_text(encoding="utf-8")
            for old, new in changes:
                needle = f'package = "{old}"'
                if needle not in body:
                    warnings.append(
                        f"{path}: could not locate exact package field for {old}"
                    )
                    continue
                body = body.replace(needle, f'package = "{new}"', 1)
                repaired += 1
            path.write_text(body, encoding="utf-8")

    for warning in warnings:
        print(f"warn: {warning}", file=sys.stderr)
    for repo, error in sorted(unavailable.items()):
        print(f"warn: {repo}: {error}", file=sys.stderr)
    for mismatch in mismatches:
        label = "repair" if fix else "mismatch"
        print(f"{label}: {mismatch}", file=sys.stderr)

    checked = len(installs) - sum(
        1 for install in installs if install.repo in unavailable
    )
    print(
        f"Go module audit: {checked} checked, {len(mismatches)} mismatch(es), "
        f"{repaired} repaired, {len(unavailable)} repository error(s)"
    )

    unresolved_repairs = bool(mismatches) and repaired < len(mismatches)
    if (mismatches and not fix) or unresolved_repairs:
        return 1
    if strict and (warnings or unavailable):
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apps_dir", nargs="?", type=Path, default=Path("apps"))
    parser.add_argument(
        "--fix", action="store_true", help="rewrite mismatched package fields"
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="fail when a repository cannot be checked",
    )
    parser.add_argument("--workers", type=int, default=12)
    args = parser.parse_args()
    return audit(
        args.apps_dir,
        fix=args.fix,
        strict=args.strict,
        workers=args.workers,
    )


if __name__ == "__main__":
    raise SystemExit(main())
