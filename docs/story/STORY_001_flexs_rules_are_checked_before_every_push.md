# STORY_001 — Flex's rules are checked before every push

**Status:** Approved by the owner 2026-10-30 ("proceed to completion", through the picker); built by Fable. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 1.

As Kevin, I want Flex to carry the same ticket and gate conventions as my other repos (a story
before code, a ticket id on every commit, gates in a pre-push hook), so that a fresh session,
mine or Claude's, finds the rules where it expects them and cannot push past a broken one.

## Acceptance Criteria

- [x] `CLAUDE.md` at the repo root says how we work: no story file, no code; the story, bug,
      chore, backlog and epic shapes and where they live; commit subjects start with the ticket
      id; anything only the owner can do is a chore; ticket prose is frozen once implemented;
      every checkable rule is a gate in `scripts/gates/` run by the pre-push hook. `README.md`
      stays the source of truth for facts (versions, commands, simulators) and gains the hook
      setup line and the release commands.
- [x] `docs/story`, `docs/bug`, `docs/chore` and `docs/backlog` exist (a `.gitkeep` where empty)
      beside the existing `docs/epic`.
- [x] `.githooks/commit-msg` refuses a subject that does not start with `STORY_NNN: `,
      `BUG_NNN: `, `CHORE_NNN: ` or `EPIC_NNN: ` whose ticket file exists under `docs/`, and an
      `EPIC_` subject on a commit that stages anything outside `docs/epic/`. Merges, reverts,
      fixups and squashes pass. The message states the rule and the fix.
- [x] `.githooks/pre-push` refuses a push to `main`, a push that deletes a bug, and a push that
      rewrites a ticket finished at the push base (every box ticked; only `[ ]` → `[x]` flips and
      appended lines pass), then runs every `scripts/gates/*.sh` and fails if any fails. It is
      turned on with `git config core.hooksPath .githooks`.
- [x] `scripts/gates/tickets-shape.sh` fails a ticket with a wrong file name, a first line that
      is not `# <ID> — <plain heading>` or carries a backtick, a story without Acceptance
      Criteria or Testing Plan, a bug or chore missing one of its sections, an epic naming fewer
      than three tickets, and an open box in a story or bug that names the owner (or Kevin)
      acting and cites no chore that exists. It self-tests each rule against a planted ticket
      and a clean set before linting `docs/`.
- [x] `scripts/gates/commit-subjects.sh` runs the commit-msg hook against sample subjects and
      fails if a bad one passes or a good one is refused.
- [x] `scripts/gates/tests.sh` runs `FlexTests` and `FlexUITests/WorkoutFlowUITests` on the
      iPhone 17 Pro simulator and fails on any red test, naming the failures.
- [x] Every gate's failure message states the rule and the fix, written for a session that has
      never seen the decision.

## Testing Plan

- **Unit (shell):** `scripts/gates/tickets-shape.sh` carries its own fixtures: one planted ticket
  per rule, each broken exactly its own way, asserted to fail with its rule's words, and a clean
  set of all five kinds asserted to pass, run every time the gate runs.
  `scripts/gates/commit-subjects.sh` feeds the commit-msg hook `tidy up`, `STORY_1: short id`,
  `STORY_999: no file`, `STORY_001: ok`, `Merge branch 'x'` and `Revert "x"` and asserts refuse,
  refuse, refuse, pass, pass, pass.
- **Unit / UI (Swift):** `scripts/gates/tests.sh` is the existing `FlexTests` and
  `WorkoutFlowUITests`; this story adds no Swift and changes none.
- **Regression cover:** this story's own commit is the first one the commit-msg hook judges.

## Notes

- Modelled on the PATHS template's `CLAUDE.md`, `.githooks/` and `tests/unit/test_tickets.py`
  (ported to shell, since Flex has no Python) and on Anchor's `scripts/gates/` layout.
- The pre-push hook does not scan for secrets or tag shapes; Flex has no `.env` and releases
  through ascpilot, not tags. Add those gates with the rule that needs them.
