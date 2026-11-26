#!/usr/bin/env python3
import os
import sys
import re
import datetime
import subprocess

CHANGELOG_FILE = 'CHANGELOG.md'

def get_current_version():
    # 1. Try git describe (latest tag reachable on current branch)
    try:
        tag = subprocess.check_output(
            ["git", "describe", "--tags", "--abbrev=0"],
            stderr=subprocess.DEVNULL
        ).decode('utf-8').strip()
        if tag:
            return tag.lstrip('v')
    except Exception:
        pass

    # 2. Try git tag list sorted by version
    try:
        tags = subprocess.check_output(
            ["git", "tag", "--sort=-version:refname"],
            stderr=subprocess.DEVNULL
        ).decode('utf-8').splitlines()
        for t in tags:
            t = t.strip()
            if t:
                return t.lstrip('v')
    except Exception:
        pass

    # 3. Try reading latest version heading from CHANGELOG.md
    if os.path.exists(CHANGELOG_FILE):
        try:
            with open(CHANGELOG_FILE, 'r', encoding='utf-8') as f:
                for line in f:
                    m = re.match(r'^##\s*\[(\d+\.\d+\.\d+)\]', line.strip())
                    if m:
                        return m.group(1)
        except Exception:
            pass

    return "1.0.0"

def bump_version(current_version, bump_type):
    parts = current_version.split('.')
    if len(parts) != 3:
        raise ValueError(f"Version {current_version} is not in SemVer format (X.Y.Z)")
    
    major, minor, patch = int(parts[0]), int(parts[1]), int(parts[2])
    
    if bump_type == 'major':
        major += 1
        minor = 0
        patch = 0
    elif bump_type == 'minor':
        minor += 1
        patch = 0
    elif bump_type == 'patch':
        patch += 1
    else:
        raise ValueError(f"Unknown bump type: '{bump_type}'. Expected 'patch', 'minor', or 'major'.")
        
    return f"{major}.{minor}.{patch}"

def update_changelog_file(new_version):
    today = datetime.date.today().isoformat()
    new_release_heading = f"## [{new_version}] -- {today}"
    
    if not os.path.exists(CHANGELOG_FILE):
        content = f"# Changelog\n\n## [unreleased]\n\n{new_release_heading}\n"
    else:
        with open(CHANGELOG_FILE, 'r', encoding='utf-8') as f:
            content = f.read()

        if re.search(r'^## \[unreleased\]\s*$', content, flags=re.MULTILINE):
            content = re.sub(
                r'^## \[unreleased\]\s*$',
                f"## [unreleased]\n\n{new_release_heading}",
                content,
                count=1,
                flags=re.MULTILINE
            )
        else:
            content = f"# Changelog\n\n## [unreleased]\n\n{new_release_heading}\n\n" + content

    with open(CHANGELOG_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tools/release_version.py <patch|minor|major>")
        sys.exit(1)
        
    bump_type = sys.argv[1].lower().strip()
    
    current_version = get_current_version()
    new_version = bump_version(current_version, bump_type)
    print(f"SemVer bump ({bump_type}): {current_version} -> {new_version}")
    
    update_changelog_file(new_version)
    
    github_output = os.environ.get('GITHUB_OUTPUT')
    if github_output:
        with open(github_output, 'a', encoding='utf-8') as f:
            f.write(f"version={new_version}\n")
    print(f"Release v{new_version} prepared successfully.")

if __name__ == '__main__':
    main()
