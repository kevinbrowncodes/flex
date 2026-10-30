#!/bin/sh
# Gate (STORY_005): the phone is the only writer of SwiftData and CloudKit (EPIC_001). The watch
# app holds values and what the phone sends it, so nothing under Flex/FlexWatch imports SwiftData
# or CloudKit or names a ModelContainer or ModelContext. The gate proves itself on a planted file
# first, then checks the real folder.
cd "$(dirname "$0")/../.." || exit 1

# Lines in a folder's Swift files that reach for the phone's store, as "file:line: text".
store_reaches() { # folder
  find "$1" -name '*.swift' -print0 2>/dev/null | xargs -0 grep -nE \
    '^[[:space:]]*(@testable[[:space:]]+)?import[[:space:]]+(SwiftData|CloudKit)([[:space:]]|$)|ModelContainer|ModelContext' 2>/dev/null \
    | grep -vE ':[0-9]+:[[:space:]]*//'
}

work=$(mktemp -d "${TMPDIR:-/tmp}/watch-no-swiftdata.XXXXXX")
trap 'rm -rf "$work"' EXIT
printf 'import Foundation\nimport SwiftData\n\nstruct Planted {}\n' > "$work/Planted.swift"
printf 'import Foundation\n// a comment may say ModelContext without reaching for one\nstruct Fine {}\n' > "$work/Fine.swift"
hits=$(store_reaches "$work")
case "$hits" in
  *Planted.swift:2:*SwiftData*) ;;
  *) echo "watch-no-swiftdata self-test FAILED: the planted SwiftData import was not caught"; echo "$hits"; exit 1 ;;
esac
case "$hits" in
  *Fine.swift*) echo "watch-no-swiftdata self-test FAILED: a comment is not a reach"; echo "$hits"; exit 1 ;;
esac

hits=$(store_reaches Flex/FlexWatch)
if [ -n "$hits" ]; then
  echo "watch-no-swiftdata gate FAILED:"
  echo "$hits"
  echo
  echo "Rule: the phone is the only writer of SwiftData and CloudKit (EPIC_001, STORY_005). The watch"
  echo "never opens a store: it holds LiveWorkout values and the WatchSnapshot the phone sends, and"
  echo "sends finished workouts back for the phone to save."
  echo "Fix: put what the watch needs into WatchSnapshot (Flex/FlexShared) and build it on the phone"
  echo "in WatchSnapshotBuilder; keep SwiftData under Flex/Flex."
  exit 1
fi
echo "watch-no-swiftdata gate passed"
