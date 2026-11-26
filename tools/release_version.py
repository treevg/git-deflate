#!/usr/bin/env python3
import os
import sys
import re
import datetime

VERSION_FILE = 'VERSION'
CHANGELOG_FILE = 'CHANGELOG.md'

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

def update_version_file(new_version):
    with open(VERSION_FILE, 'w', encoding='utf-8') as f:
        f.write(new_version + '\n')

def update_changelog_file(new_version):
    today = datetime.date.today().isoformat()
    new_release_heading = f"## [{new_version}] -- {today}"
    
    if not os.path.exists(CHANGELOG_FILE):
        content = f"# Changelog\n\n## [unreleased]\n\n{new_release_heading}\n"
    else:
        with open(CHANGELOG_FILE, 'r', encoding='utf-8') as f:
            content = f.read()

        # Anchor precisely on markdown heading '## [unreleased]'
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
    
    current_version = "1.0.0"
    if os.path.exists(VERSION_FILE):
        with open(VERSION_FILE, 'r', encoding='utf-8') as f:
            v = f.read().strip()
            if v:
                current_version = v
                
    new_version = bump_version(current_version, bump_type)
    print(f"SemVer bump ({bump_type}): {current_version} -> {new_version}")
    
    update_version_file(new_version)
    update_changelog_file(new_version)
    
    github_output = os.environ.get('GITHUB_OUTPUT')
    if github_output:
        with open(github_output, 'a', encoding='utf-8') as f:
            f.write(f"version={new_version}\n")
    print(f"Release v{new_version} prepared successfully.")

if __name__ == '__main__':
    main()
