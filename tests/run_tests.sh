#!/usr/bin/env bash
set -e

# ==============================================================================
# Automated Test Suite for git-deflate & inflate.sh
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_DEFLATE="$ROOT_DIR/git-deflate"

# Terminal formatting
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
BOLD="\033[1m"
RESET="\033[0m"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Ensure git-deflate exists and is executable
if [ ! -x "$GIT_DEFLATE" ]; then
  echo -e "${RED}Error: git-deflate executable not found at $GIT_DEFLATE${RESET}" >&2
  exit 1
fi

# Create a temporary sandbox directory for all tests
TEST_SANDBOX=$(mktemp -d /tmp/git-deflate-tests-XXXXXX)
cleanup() {
  rm -rf "$TEST_SANDBOX"
}
trap cleanup EXIT

# Assertion helpers
assert() {
  local condition="$1"
  local message="$2"
  if ! eval "$condition"; then
    echo -e "    ${RED}Assertion failed:${RESET} $message"
    return 1
  fi
  return 0
}

assert_file_exists() {
  local path="$1"
  assert "[ -e '$path' ]" "Expected file to exist: $path"
}

assert_file_not_exists() {
  local path="$1"
  assert "[ ! -e '$path' ]" "Expected file NOT to exist: $path"
}

assert_file_contains() {
  local path="$1"
  local expected="$2"
  assert "grep -q '$expected' '$path'" "Expected '$path' to contain '$expected'"
}

assert_branch() {
  local expected="$1"
  local current
  current=$(git branch --show-current)
  assert "[ '$current' = '$expected' ]" "Expected branch '$expected', but got '$current'"
}

run_test() {
  local test_name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo -e "${BLUE}Running:${RESET} $test_name..."

  # Run test in an isolated subshell
  if ( $test_name ); then
    echo -e "  ${GREEN}✓ PASSED${RESET}\n"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "  ${RED}✗ FAILED${RESET}\n"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ==============================================================================
# Test Cases
# ==============================================================================

test_basic_deflate_and_inflate() {
  local repo="$TEST_SANDBOX/test_basic"
  mkdir -p "$repo" && cd "$repo"
  git init -b main >/dev/null 2>&1
  git config user.email "test@test.com"
  git config user.name "Test User"

  echo "Hello World" > main.txt
  mkdir -p Assets/Scripts && echo "Console.WriteLine();" > Assets/Scripts/App.cs
  git add . && git commit -m "Initial commit" >/dev/null 2>&1

  # Deflate
  "$GIT_DEFLATE" -y >/dev/null

  assert_file_not_exists "$repo/main.txt"
  assert_file_not_exists "$repo/Assets/Scripts/App.cs"
  assert_file_exists "$repo/DEFLATED.md"
  assert_file_exists "$repo/inflate.sh"

  # Inflate via standalone script
  ./inflate.sh >/dev/null

  assert_file_exists "$repo/main.txt"
  assert_file_exists "$repo/Assets/Scripts/App.cs"
  assert_file_not_exists "$repo/DEFLATED.md"
  assert_file_not_exists "$repo/inflate.sh"
  assert_branch "main"
}

test_branch_memory() {
  local repo="$TEST_SANDBOX/test_branch"
  mkdir -p "$repo" && cd "$repo"
  git init -b main >/dev/null 2>&1
  git config user.email "test@test.com"
  git config user.name "Test User"

  echo "Base commit" > base.txt
  git add base.txt && git commit -m "Base commit" >/dev/null 2>&1

  git checkout -b "feature/combat-system" >/dev/null 2>&1
  echo "Combat feature code" > combat.cs
  git add combat.cs && git commit -m "Add combat system" >/dev/null 2>&1

  # Deflate while on feature branch
  "$GIT_DEFLATE" -y >/dev/null

  # Working tree is emptied, DEFLATED.md records feature branch
  assert_file_not_exists "$repo/combat.cs"
  assert_file_contains "$repo/DEFLATED.md" "feature/combat-system"
  assert_file_contains "$repo/inflate.sh" "feature/combat-system"

  # Inflate
  ./inflate.sh >/dev/null

  assert_branch "feature/combat-system"
  assert_file_exists "$repo/combat.cs"
  assert_file_not_exists "$repo/DEFLATED.md"
  assert_file_not_exists "$repo/inflate.sh"
}

test_autostash_modified_and_untracked() {
  local repo="$TEST_SANDBOX/test_autostash"
  mkdir -p "$repo" && cd "$repo"
  git init -b main >/dev/null 2>&1
  git config user.email "test@test.com"
  git config user.name "Test User"

  echo "Original content" > tracked.txt
  git add tracked.txt && git commit -m "Initial commit" >/dev/null 2>&1

  # Make uncommitted changes
  echo "Modified content" >> tracked.txt
  echo "Untracked new file" > new_untracked.txt

  # Deflate with auto-stash
  "$GIT_DEFLATE" -y >/dev/null

  assert_file_not_exists "$repo/tracked.txt"
  assert_file_not_exists "$repo/new_untracked.txt"
  assert_file_contains "$repo/DEFLATED.md" "Stashed"

  # Inflate
  ./inflate.sh >/dev/null

  assert_file_exists "$repo/tracked.txt"
  assert_file_exists "$repo/new_untracked.txt"
  assert_file_contains "$repo/tracked.txt" "Modified content"
  assert_file_contains "$repo/new_untracked.txt" "Untracked new file"

  # Ensure stash was cleanly applied and dropped
  local stash_count
  stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  assert "[ '$stash_count' = '0' ]" "Expected stash list to be empty after clean inflation"
}

test_local_directory_preservation() {
  local repo="$TEST_SANDBOX/test_local_dirs"
  mkdir -p "$repo" && cd "$repo"
  git init -b main >/dev/null 2>&1
  git config user.email "test@test.com"
  git config user.name "Test User"

  echo -e "Assets/Local/\nLocal/" > .gitignore
  echo "Tracked file" > tracked.txt
  git add .gitignore tracked.txt && git commit -m "Initial commit" >/dev/null 2>&1

  # Create developer-only ignored Local directories
  mkdir -p Assets/Local Local/Credentials
  echo "Developer notes" > Assets/Local/notes.md
  echo "SECRET_KEY=12345" > Local/Credentials/keys.env

  # Deflate
  "$GIT_DEFLATE" -y >/dev/null

  # Tracked files are removed, but Local/ directories are strictly preserved
  assert_file_not_exists "$repo/tracked.txt"
  assert_file_exists "$repo/Assets/Local/notes.md"
  assert_file_exists "$repo/Local/Credentials/keys.env"

  # Inflate
  ./inflate.sh >/dev/null

  assert_file_exists "$repo/tracked.txt"
  assert_file_exists "$repo/Assets/Local/notes.md"
  assert_file_exists "$repo/Local/Credentials/keys.env"
}

test_dry_run_leaves_files_untouched() {
  local repo="$TEST_SANDBOX/test_dry_run"
  mkdir -p "$repo" && cd "$repo"
  git init -b main >/dev/null 2>&1
  git config user.email "test@test.com"
  git config user.name "Test User"

  echo "Important file" > important.txt
  git add important.txt && git commit -m "Initial commit" >/dev/null 2>&1

  # Run dry run
  "$GIT_DEFLATE" -n >/dev/null

  # Nothing should be touched or created
  assert_file_exists "$repo/important.txt"
  assert_file_not_exists "$repo/DEFLATED.md"
  assert_file_not_exists "$repo/inflate.sh"
}

test_standalone_inflate_without_git_deflate_in_path() {
  local repo="$TEST_SANDBOX/test_standalone"
  mkdir -p "$repo" && cd "$repo"
  git init -b main >/dev/null 2>&1
  git config user.email "test@test.com"
  git config user.name "Test User"

  echo "Source code" > App.cs
  git add App.cs && git commit -m "Initial commit" >/dev/null 2>&1

  # Deflate
  "$GIT_DEFLATE" -y >/dev/null

  assert_file_not_exists "$repo/App.cs"
  assert_file_exists "$repo/inflate.sh"

  # Execute inflate.sh with restricted PATH containing only standard system binaries
  PATH="/usr/bin:/bin" ./inflate.sh >/dev/null

  assert_file_exists "$repo/App.cs"
  assert_file_not_exists "$repo/inflate.sh"
}

test_no_stash_flag_prevents_deflate_on_dirty_tree() {
  local repo="$TEST_SANDBOX/test_no_stash"
  mkdir -p "$repo" && cd "$repo"
  git init -b main >/dev/null 2>&1
  git config user.email "test@test.com"
  git config user.name "Test User"

  echo "Original file" > file.txt
  git add file.txt && git commit -m "Initial commit" >/dev/null 2>&1

  echo "Dirty modification" >> file.txt

  # Deflate with --no-stash should fail and refuse to deflate
  if "$GIT_DEFLATE" --no-stash -y >/dev/null 2>&1; then
    echo -e "    ${RED}Expected git-deflate --no-stash to fail on dirty tree, but it succeeded!${RESET}"
    return 1
  fi

  assert_file_exists "$repo/file.txt"
  assert_file_not_exists "$repo/DEFLATED.md"
  assert_file_not_exists "$repo/inflate.sh"
}

# ==============================================================================
# Suite Runner
# ==============================================================================

echo -e "${BOLD}=== Running git-deflate Automated Test Suite ===${RESET}\n"

run_test test_basic_deflate_and_inflate
run_test test_branch_memory
run_test test_autostash_modified_and_untracked
run_test test_local_directory_preservation
run_test test_dry_run_leaves_files_untouched
run_test test_standalone_inflate_without_git_deflate_in_path
run_test test_no_stash_flag_prevents_deflate_on_dirty_tree

echo -e "${BOLD}=== Test Results ===${RESET}"
echo -e "Total:  $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${RESET}"
if [ "$TESTS_FAILED" -gt 0 ]; then
  echo -e "Failed: ${RED}$TESTS_FAILED${RESET}"
  exit 1
else
  echo -e "Failed: 0"
  echo -e "\n${GREEN}${BOLD}All tests passed successfully!${RESET}"
  exit 0
fi
