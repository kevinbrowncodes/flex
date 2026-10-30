#!/bin/sh
# Gate (STORY_001): every ticket under docs/ has the shape CLAUDE.md prescribes ("Bugs, backlog,
# chores, epics"): the file name, the first-line heading, each kind's sections, an epic's group
# of three, and the owner-chore rule (an open box in a story or bug that names the owner acting
# cites a chore that exists). The gate first proves each rule against a planted ticket and a
# clean set, then lints docs/. A fresh folder of .gitkeep stubs lints clean by holding nothing.
cd "$(dirname "$0")/../.." || exit 1

# The sections each kind must carry, as "## <name>" headings. Status may also be a "**Status:**" line.
sections_for() {
  case "$1" in
    STORY) echo "Acceptance Criteria|Testing Plan" ;;
    BUG) echo "Summary|Steps to Reproduce|Expected vs Actual|Root Cause|Status" ;;
    CHORE) echo "Summary|Why|Changes|Testing" ;;
    *) echo "" ;;
  esac
}

has_section() { # file, name
  grep -qE "^#+ .*$2" "$1" && return 0
  [ "$2" = "Status" ] && grep -qE '^\*\*Status:?\*\*' "$1" && return 0
  return 1
}

# The owner as the one who acts, in an open box of a story or bug, with no existing chore cited.
owner_problems() { # file, "CHORE_001 CHORE_002 ..."
  awk -v chores=" $2 " -v name="$(basename "$1")" '
    function flush() {
      if (!have) return
      low = tolower(block)
      acting = (low ~ /^[ \t]*- \[ \][ \t]*(\*\*[^*]*\*\*[ \t]*)?(by hand, )?(the owner|kevin)([^a-z]|$)/ \
                || low ~ /\((the owner|kevin)([^a-z]|$)/ || low ~ /by (the owner|kevin)([^a-z]|$)/ \
                || low ~ /(the owner|kevin) (adds|makes|signs|runs|checks|types|grants|drags|drops|picks|pastes|installs|turns|opens|sets|logs|confirms|tests|updates|answers|deploys|reports|uploads)([^a-z]|$)/)
      if (acting) {
        cited = ""; ok = 0; s = block
        while (match(s, /CHORE_[0-9][0-9][0-9]/)) {
          c = substr(s, RSTART, RLENGTH); cited = cited (cited == "" ? "" : ", ") c
          if (index(chores, " " c " ") > 0) ok = 1
          s = substr(s, RSTART + RLENGTH)
        }
        if (!ok) {
          what = (cited == "" ? "cites no chore" : "cites " cited ", which is not in docs/chore/")
          printf "%s:%d: an open box names the owner and %s. Anything only the owner can do is a chore the moment work stops on it (CLAUDE.md). Fix: write docs/chore/CHORE_NNN_<slug>.md with the steps he follows and the one Claude does after, and cite CHORE_NNN on this line.\n", name, start, what
        }
      }
      have = 0; block = ""
    }
    /^[ \t]*- \[ \]/ { flush(); have = 1; start = NR; block = $0; next }
    have && /^[ \t][ \t]+[^ \t]/ && !/^[ \t]*- \[/ { block = block "\n" $0; next }
    { flush() }
    END { flush() }
  ' "$1"
}

lint_docs() { # docs dir; prints one problem per line
  docs=$1
  chores=""
  if [ -d "$docs/chore" ]; then
    chores=$(ls "$docs/chore" 2>/dev/null | grep -E '^CHORE_[0-9]{3}_' | cut -c1-9 | tr '\n' ' ')
  fi
  for kind in story bug chore backlog epic; do
    prefix=$(printf '%s' "$kind" | tr '[:lower:]' '[:upper:]')
    folder="$docs/$kind"
    [ -d "$folder" ] || continue
    for file in "$folder"/*; do
      [ -e "$file" ] || continue
      [ -d "$file" ] && continue
      name=$(basename "$file")
      [ "$name" = ".gitkeep" ] && continue
      if ! printf '%s\n' "$name" | grep -qE "^${prefix}_[0-9]{3}_[a-z0-9_]+\.md$"; then
        echo "$name: ticket files are ${prefix}_NNN_short_slug.md, three digits, lower case (CLAUDE.md)"
        continue
      fi
      id=$(printf '%s' "$name" | cut -c1-$((${#prefix} + 4)))
      first=$(sed -n '1p' "$file")
      case "$first" in
        "# $id — "?*)
          case "$first" in
            *'`'*) echo "$name: the first line must be '# $id — <plain heading>' a non-engineer reads at a glance, never a backticked symbol (CLAUDE.md)" ;;
          esac ;;
        *) echo "$name: the first line must be '# $id — <plain heading>' a non-engineer reads at a glance, never a backticked symbol (CLAUDE.md)" ;;
      esac
      needed=$(sections_for "$prefix")
      if [ -n "$needed" ]; then
        oldIFS=$IFS; IFS='|'
        for section in $needed; do
          IFS=$oldIFS
          has_section "$file" "$section" || echo "$name: a $kind needs a $section section"
          IFS='|'
        done
        IFS=$oldIFS
      fi
      if [ "$prefix" = "EPIC" ]; then
        count=$(grep -oE '(STORY|BUG|CHORE)_[0-9]{3}' "$file" | sort -u | wc -l | tr -d ' ')
        if [ "$count" -lt 3 ]; then
          echo "$name: an epic groups three or more tickets (stories, with chores and bugs counting toward its group); a single feature is just a story (CLAUDE.md)"
        fi
      fi
      case "$prefix" in
        STORY|BUG) owner_problems "$file" "$chores" ;;
      esac
    done
  done
}

# --- The gate proves its own rules first: one planted ticket per rule, then a clean set. ---
work=$(mktemp -d "${TMPDIR:-/tmp}/tickets-shape.XXXXXX")
trap 'rm -rf "$work"' EXIT
story_body='# STORY_001 — A fine story

## Acceptance Criteria

- [ ] It works.

## Testing Plan

- Unit.
'
plant() { # rule kind filename body expected-words
  dir="$work/$1/docs/$2"; mkdir -p "$dir"; printf '%s' "$4" > "$dir/$3"
  out=$(lint_docs "$work/$1/docs")
  if [ -z "$out" ]; then echo "tickets-shape self-test FAILED: rule '$1' let its planted ticket pass"; exit 1; fi
  case "$out" in
    *"$3"*"$5"*) ;;
    *) echo "tickets-shape self-test FAILED: rule '$1' named the wrong problem:"; echo "$out"; exit 1 ;;
  esac
}
plant filename story STORY_1_bad.md "$story_body" "three digits"
plant first-line story STORY_001_x.md 'STORY_001 without its heading

## Acceptance Criteria

## Testing Plan
' "plain heading"
plant backticked-heading story STORY_001_x.md '# STORY_001 — `maze.solve()` returns

## Acceptance Criteria

## Testing Plan
' "never a backticked symbol"
plant story-sections story STORY_001_x.md '# STORY_001 — No plan

## Acceptance Criteria
' "needs a Testing Plan"
plant bug-sections bug BUG_001_x.md '# BUG_001 — Broken

## Summary

## Steps to Reproduce

## Root Cause

## Status
' "needs a Expected vs Actual"
plant chore-sections chore CHORE_001_x.md '# CHORE_001 — A tidy

## Summary

## Why

## Changes
' "needs a Testing"
plant epic-too-small epic EPIC_001_x.md '# EPIC_001 — Thin

Only STORY_001 and CHORE_002 belong.
' "three or more tickets"
plant owner-box-without-a-chore story STORY_001_x.md '# STORY_001 — Waits on him

## Acceptance Criteria

- [ ] The owner signs in
      once in App Store Connect.

## Testing Plan

- Unit.
' "cites no chore"
plant kevin-box-without-a-chore story STORY_001_x.md '# STORY_001 — Waits on Kevin

## Acceptance Criteria

- [ ] Kevin answers the privacy questions.

## Testing Plan

- Unit.
' "cites no chore"
plant owner-box-citing-a-missing-chore bug BUG_001_x.md '# BUG_001 — Broken

## Summary

## Steps to Reproduce

## Expected vs Actual

## Root Cause

## Status

- [ ] Checked by the owner (CHORE_009).
' "which is not in docs/chore/"

clean="$work/clean/docs"
for kind in story bug chore backlog epic; do mkdir -p "$clean/$kind"; done
printf '%s' "$story_body" > "$clean/story/STORY_001_a_fine_story.md"
printf '%s' '# BUG_001 — A bug

## Summary

## Steps to Reproduce

## Expected vs Actual

## Root Cause

**Status:** Resolved (2026-09-28).
' > "$clean/bug/BUG_001_a_bug.md"
printf '%s' '# EPIC_001 — A group

STORY_001, STORY_002 and BUG_001 belong.
' > "$clean/epic/EPIC_001_a_group.md"
mkdir -p "$clean/epic/assets"; printf 'not a ticket\n' > "$clean/epic/assets/notes.md"
: > "$clean/backlog/.gitkeep"
printf '%s' '# CHORE_001 — He signs in

## Summary

## Why

## Changes

- [ ] The owner signs in.

## Testing
' > "$clean/chore/CHORE_001_he_signs_in.md"
printf '%s' '# STORY_002 — Waits on a chore

## Acceptance Criteria

- [ ] The owner signs
      in (CHORE_001).
- [x] Checked by the owner.
- [ ] The gate fails a bad one.
- [ ] The watch shows what the owner logged on the phone.

## Testing Plan

- Unit.
' > "$clean/story/STORY_002_waits_on_a_chore.md"
out=$(lint_docs "$clean")
if [ -n "$out" ]; then
  echo "tickets-shape self-test FAILED: the clean set was refused:"; echo "$out"; exit 1
fi

# --- Then this repo's own tickets. ---
problems=$(lint_docs docs)
if [ -n "$problems" ]; then
  echo "tickets-shape gate FAILED:"
  echo "$problems"
  echo
  echo "Rule: every ticket under docs/ keeps the shape CLAUDE.md prescribes (Bugs, backlog, chores,"
  echo "epics): <KIND>_NNN_short_slug.md, a first line '# <ID> — <plain heading>', a story's"
  echo "Acceptance Criteria and Testing Plan, a bug's and a chore's sections, an epic of three or"
  echo "more tickets, and a chore for anything only the owner can do."
  echo "Fix: edit the file each line names until this gate passes (STORY_001)."
  exit 1
fi
echo "tickets-shape gate passed"
