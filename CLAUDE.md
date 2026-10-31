# Flex

A workout tracker for iPhone, iPad and Apple Watch: SwiftUI, SwiftData, CloudKit. `README.md`
is the source of truth for facts (versions, commands, simulators, how it ships); when the two
disagree about a fact, trust the README and flag it. This file covers how we work.

Kevin's user-level rules (`~/.claude/CLAUDE.md`) apply: ask through the picker, every feature
on trial, rules are gates.

## How features are built

> No story file, no code. No exceptions. Trivial work that does not merit a story (a copy tweak, a
> rename, a dependency bump) uses a chore instead. Chores carry the same testing bar; only the
> ticket is lighter.

1. Every feature has a story in `docs/story/STORY_NNN_short_slug.md` before any code is written.
   If work is requested without one, draft the story, get approval, then implement.
2. Story format: a `**Status:**` line, the user story sentence ("As Kevin, I want … so that …"),
   `## Acceptance Criteria` (a checklist) and `## Testing Plan`, plus `## UI Mockup` when the
   UI changes. `## Notes` is optional. Keep it short: a story is a spec for one person, not a
   report.
3. Stories are implemented one at a time, with the story as the spec. Land one, verify it, then
   start the next.
4. `## UI Mockup` sketches the layout in ASCII art and is agreed before implementation. A story
   with no UI change leaves it out.
5. `## Testing Plan` says which layers apply and what each test proves, in plain English, one
   line per test file: **unit** (`FlexTests`, and `FlexWatchTests` for the watch, Swift Testing,
   in-memory `ModelContainer` from `TestSupport`), **UI** (`FlexUITests` / `FlexWatchUITests`,
   XCUITest, launched with `FLEX_DEMO` so no sign-in and no network), and **by hand** only for
   what a simulator cannot do (two real devices, HealthKit mirroring), which is then a chore
   the owner runs. If a layer does not apply, say so and why; "no tests needed" is not an
   answer.
6. A story is Done when its Testing Plan tests are written and every gate in `scripts/gates/` is
   green locally. There is no CI; the pre-push hook is the gate.
7. An acceptance criterion that asserts what a screen shows, where a tap goes, or what is saved
   is written after opening the file that decides it. A comment is not evidence. If the
   criterion turns out wrong, correct it in the story and say so; the next person reads the
   story, not the diff.
8. The same applies to any claim about live state (the shipped version, a CloudKit schema, what
   App Store Connect says): check the thing itself. `README.md` describes state; it is never
   evidence of it.

## Bugs, backlog, chores, epics

- Bugs: `docs/bug/BUG_NNN_short_slug.md`. Sections: Summary, Steps to Reproduce, Expected vs
  Actual, Root Cause, Acceptance Criteria, and Status (a `## Status` heading or a `**Status:**`
  line). Use a bug when existing behaviour is broken; when the fix needs meaningful new code,
  write a story that references the bug. Never delete a bug: set Status to Resolved and add a
  Resolution note at the bottom (the pre-push hook refuses a push that deletes one).
- Backlog: `docs/backlog/BACKLOG_NNN_short_slug.md`. Summary, user impact, rough scope,
  dependencies, open questions, priority. Never implement from a backlog item; promote it to a
  story first.
- Chores: `docs/chore/CHORE_NNN_short_slug.md`. Summary, Why, a Changes checklist, Testing. Same
  testing bar as a story. If scope grows, promote it to a story before writing more code.
- Epics: `docs/epic/EPIC_NNN_short_slug.md` group three or more related stories: goal, why, the
  stories in order with each one's gate, status. A single feature is just a story.
- Numbers are three digits, zero-padded. Story numbers match implementation order within their
  epic; if priorities shift, renumber the unimplemented stories before any code. Headings are
  plain English a non-engineer reads at a glance: `# STORY_003 — A rest timer counts down
  between sets`, never a function name or a backticked symbol.
  `scripts/gates/tickets-shape.sh` fails a ticket that breaks these shapes (STORY_001).
- Anything only the owner can do (a sign-in, an App Store Connect answer, a check on a real
  watch) is a chore the moment work stops on it: `docs/chore/CHORE_NNN_*.md`, its Changes the
  steps he follows and then the step Claude does after, and the ticket that waits on it cites
  the chore. Never a list in chat alone. The ticket gate fails an open story or bug box that
  names the owner acting and cites no chore of the repo (STORY_001).
- Ticket prose is frozen once implemented: flip `[ ]` to `[x]`, never rewrite the description.
  New requirements are a new ticket. The pre-push hook refuses a push that rewrites a ticket
  finished at the push base; flips and appended lines pass (STORY_001).
- Commit subjects start with the ticket id: `STORY_003: …`, `BUG_002: …`, `CHORE_001: …`. The
  commit-msg hook in `.githooks/` refuses any other subject, and a ticket id whose file is
  missing from `docs/`. An `EPIC_` subject fits only a commit that touches `docs/epic/` alone
  (STORY_001).

## Rules are gates

- A rule that can be checked is a script in `scripts/gates/`, run by `.githooks/pre-push`
  (turned on once per clone with `git config core.hooksPath .githooks`). Its failure message
  states the rule and the fix for a session that has never seen the decision. The CLAUDE.md line
  explains the gate; it never replaces it. When a story creates a rule, the gate ships in the
  same story and the story names it.
- Gates today: `tickets-shape.sh` (ticket shapes, the owner-chore rule), `commit-subjects.sh`
  (the commit-msg hook against sample subjects), `tests.sh` (`FlexTests` and
  `WorkoutFlowUITests` on the iPhone 17 Pro simulator, `FlexWatchTests` and `FlexWatchUITests`
  on an Apple Watch simulator), `shared-is-portable.sh` (`Flex/FlexShared` imports only
  Foundation, Observation and AppIntents, STORY_004 and STORY_010), `watch-no-swiftdata.sh` (`Flex/FlexWatch` and `Flex/FlexWatchWidgets` never
  import SwiftData or CloudKit or name a ModelContainer or ModelContext, STORY_005, STORY_011),
  `health-usage-strings.sh` (a target whose entitlements grant HealthKit sets both Health usage
  strings, STORY_008). Each watch story in EPIC_001 adds its own.
- Run a gate by hand with `sh scripts/gates/<name>.sh`. `git push --no-verify` is for
  emergencies only, with the justification in the commit message.

## Dev workflow

- Push to `develop` only. Never push to `main`; the pre-push hook refuses it.
- Before every commit: `sh scripts/gates/tickets-shape.sh`, then `sh scripts/gates/tests.sh`
  (cheapest first). Never commit on red: fix, re-run from the failed step, then commit.
- Stage explicit paths. Never `git add -A`, `git add .`, or `git add <dir>/`; a blanket add
  sweeps unrelated drafts into the commit. Run `git status --short` before every commit and
  read it.
- Batch work: several logical commits, one push.
- Build and test commands, simulators and the release steps are in `README.md`.
- A test that fails because it asserts the behaviour you just removed is a review comment, not a
  chore. Sort red tests into "asserts an implementation detail I changed" and "asserts behaviour
  the owner can perceive" before touching either; the second kind is usually right and the code
  is wrong.
- Always end with a clear summary: what changed, what commands ran, what the outcome was.

## Phone, watch and the shared folder

- `Flex/Flex` is the iPhone and iPad app, `Flex/FlexWatch` the watch app, `Flex/FlexWatchWidgets`
  its complication (a WidgetKit extension that reads only the App Group the watch app writes,
  STORY_011), `Flex/FlexShared` the value types all three compile (the live workout, formatting,
  the demo-launch parser, the Siri intent). The phone is
  the only device that touches SwiftData and CloudKit (EPIC_001); the watch holds values and what
  the phone sends it. `shared-is-portable.sh` holds the first half of that;
  `watch-no-swiftdata.sh` the second. What the watch needs goes into `WatchSnapshot`
  (`Flex/FlexShared`), built on the phone by `WatchSnapshotBuilder` and sent by `PhoneWatchLink`
  over WatchConnectivity whenever a SwiftData save or a preference changes it.
- The watch app runs independently of the phone (`WKRunsIndependentlyOfCompanionApp`), carries
  the iOS app's version and build numbers, and is embedded by the Flex target, so one install
  puts Flex on the watch. Watch tests run through the shared `FlexWatch` scheme.

## SwiftData and CloudKit

- Every `@Model` attribute has a default value or is optional, and every relationship is
  optional with an inverse: CloudKit requires it.
- Never name an attribute after an `NSManagedObject` member (`isDeleted`, `hasChanges`,
  `description`): `Exercise.isDeleted` read back `false` after every save until it became
  `isArchived` (2026-09-05).
- A model change is a CloudKit schema change: deploy the development schema to Production in
  CloudKit Console before the release ships, or devices on the old schema stop syncing. Say so in
  the story that changes a model.
- A `ModelContext` must not outlive its `ModelContainer`. A test helper that returns
  `container.mainContext` and lets the container go out of scope leaves a context whose next
  fetch traps inside SwiftData with no message (EXC_BREAKPOINT, three SwiftData frames, nothing
  in the crash report). Return or hold the container; take the context from it where it is used
  (STORY_005, 2026-10-30, a bisection of four identical crashes).
