#!/bin/sh
# Gate (STORY_001): the commit-msg hook still judges subjects the way CLAUDE.md says. It is run
# against sample subjects: the bad ones must be refused and the good ones must pass, so a change
# to the hook that loosens or breaks it fails here before it is pushed.
cd "$(dirname "$0")/../.." || exit 1
hook=.githooks/commit-msg
msg=$(mktemp)
trap 'rm -f "$msg"' EXIT
failed=0
expect() { # refuse|pass, subject
  printf '%s\n' "$2" > "$msg"
  if sh "$hook" "$msg" > /dev/null 2>&1; then got=pass; else got=refuse; fi
  if [ "$got" != "$1" ]; then
    echo "commit-subjects gate FAILED: \"$2\" was ${got}d, expected $1"
    failed=1
  fi
}
expect refuse "tidy up"
expect refuse "STORY_1: short id"
expect refuse "STORY_001x: glued"
expect refuse "STORY_999: no ticket file"
expect refuse "BUG_999: no such bug"
expect pass "STORY_001: the hooks land"
expect pass "EPIC_001: the epic alone"
expect pass "Merge branch 'develop'"
expect pass "Revert \"STORY_001: the hooks land\""
expect pass "fixup! STORY_001: the hooks land"
if [ "$failed" = 1 ]; then
  echo
  echo "Rule: commit subjects start with the ticket id whose file exists under docs/ (CLAUDE.md);"
  echo "merges, reverts, fixups and an EPIC_ id for a docs/epic-only commit also pass."
  echo "Fix: restore .githooks/commit-msg so each sample above is judged as expected (STORY_001)."
  exit 1
fi
echo "commit-subjects gate passed"
