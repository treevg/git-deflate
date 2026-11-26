# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [unreleased]

### Added
- Initial release of `git-deflate`.
- Core deflation workflow emptying tracked files via Git native sparse-checkout.
- Git LFS local cache purging (`.git/lfs`) to free duplicate local binary cache.
- Preservation rules for `/Local/` directories at any folder depth.
- Automatic stashing of uncommitted working tree changes with hash-based restore.
- Active branch memory to resume working on the previous branch upon inflation.
- Generation of standalone, self-contained `inflate.sh` in deflated workspaces.
- Human-readable `DEFLATED.md` marker file in deflated workspaces.
- Interactive dry-run inspection and confirmation prompt by default.
- CLI flags: `-n` (`--dry-run`), `-y` (`--yes`), `--no-stash`, `-f` (`--force`).
- Installation and uninstallation script (`install.sh`).
- Automated test suite covering deflate/inflate cycles, branch memory, auto-stash, Local/ preservation, dry-run, and standalone portability (`tests/run_tests.sh`).
- Cross-platform GitHub Actions CI workflow running automated tests on Ubuntu and macOS (`.github/workflows/ci.yml`).
