# git-deflate

A Git utility to **deflate** large repositories (especially Unity and Git LFS projects) down to their absolute minimal disk footprint (~15 MB), and generate a **self-contained `inflate.sh`** script to restore the workspace on any machine.

---

## The Problem

Large projects (such as Unity repositories with 3D models, textures, audio, and compiled binaries) often consume dozens of gigabytes on disk:
- The working copy can take tens of gigabytes.
- The `.git/lfs` cache holds duplicate copies of all checked-out binary assets.
- Build caches and ignored folders (`Library/`, `Temp/`, `Logs/`) take up even more space.

When pausing work on a repository, you often want to free up that disk space without deleting your Git clone or losing your working branch and uncommitted changes.

---

## How It Works

When you run `git deflate`:

1. **Auto-Stashes Work in Progress**: Automatically stashes any uncommitted changes (tracked modifications & untracked files) using an immutable commit hash.
2. **Records Active Branch**: Memorizes your active branch so you can resume right where you left off.
3. **Pulls Base Branch**: Switches to `main`/`master` and syncs with the remote.
4. **Cleans Ignored Clutter**: Removes `.gitignore` caches (e.g. Unity `Library/`, `Temp/`, `Logs/`), while strictly preserving any `/Local/` developer folder.
5. **Empties Working Tree**: Uses Git's native sparse checkout to uncheck all tracked files from disk (0% present, clean status).
6. **Purges Git LFS Cache**: Removes `.git/lfs`, deleting local duplicate binaries.
7. **Leaves Standalone Inflate Tools**:
   - `DEFLATED.md`: A summary explaining why the folder is empty, when it was deflated, and what branch was saved.
   - `inflate.sh`: A self-contained script to restore the project.

---

## Portability & Inflation

The generated `inflate.sh` is **completely self-contained**:
- It does **not** require `git-deflate` to be installed on the machine.
- It works on any machine with standard `git` and `bash`.
- When run (`./inflate.sh`), it restores the working directory instantly, switches back to your saved branch, downloads LFS assets with a live progress bar, re-applies your stashed changes, and cleans up after itself.

---

## Installation

Run the install script from this repository:

```bash
cd /Users/treevg/Documents/Tools/git-deflate
./install.sh
```

This symlinks `git-deflate` to `~/.local/bin/git-deflate`. Because Git automatically resolves commands matching `git-<subcommand>`, you can invoke it anywhere as:

```bash
git deflate
```

To uninstall:
```bash
./install.sh --uninstall
```

---

## Usage

```bash
# In any Git repository:
git deflate
```

By default (with no arguments), `git deflate` performs a **dry-run preview** showing the targets scheduled for removal and uncommitted changes to stash, then prompts for confirmation before touching any files.

### Options

| Flag | Description |
| :--- | :--- |
| `-n`, `--dry-run` | Show dry-run preview and exit without prompting. |
| `-y`, `--yes` | Proceed with execution without prompting. |
| `--no-stash` | Disable auto-stashing (fails if uncommitted changes exist). |
| `-f`, `--force` | Skip uncommitted changes check and confirmation prompt. |
| `-h`, `--help` | Show help message. |

---

## Restoring

To re-inflate a deflated repository on any machine, simply run the script left in the folder:

```bash
./inflate.sh
```

---

## Running Tests

An automated test suite is included in `tests/run_tests.sh`. It creates temporary repositories in `/tmp`, executes deflation/inflation cycles, tests branch memory, auto-stash, and path portability, and cleans up after itself:

```bash
./tests/run_tests.sh
```
