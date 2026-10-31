#!/bin/sh
# Gate (STORY_004): everything under Flex/FlexShared compiles into the iPhone app and the watch app
# alike, so it may import only Foundation and Observation, plus AppIntents, which is one framework
# on both platforms and lets the Siri intent be one definition for both apps (STORY_010). No UIKit,
# SwiftUI, WatchKit, SwiftData, CloudKit or HealthKit: a model that reaches for a platform
# framework stops being shared. The gate proves itself on a planted file first, then checks the
# real folder.
cd "$(dirname "$0")/../.." || exit 1

# Imports in a folder's Swift files that are not on the allowed list, as "file:line: import X".
offending_imports() { # folder
  grep -nE '^[[:space:]]*(@testable[[:space:]]+)?import[[:space:]]+[A-Za-z_]' "$1"/*.swift 2>/dev/null \
    | grep -vE 'import[[:space:]]+(Foundation|Observation|AppIntents)([[:space:]]|$)'
}

work=$(mktemp -d "${TMPDIR:-/tmp}/shared-is-portable.XXXXXX")
trap 'rm -rf "$work"' EXIT
printf 'import Foundation\nimport SwiftData\n\nstruct Planted {}\n' > "$work/Planted.swift"
printf 'import Foundation\nimport Observation\n\nstruct Fine {}\n' > "$work/Fine.swift"
hits=$(offending_imports "$work")
case "$hits" in
  *Planted.swift:2:*SwiftData*) ;;
  *) echo "shared-is-portable self-test FAILED: the planted SwiftData import was not caught"; echo "$hits"; exit 1 ;;
esac
case "$hits" in
  *Fine.swift*) echo "shared-is-portable self-test FAILED: Foundation and Observation must pass"; echo "$hits"; exit 1 ;;
esac

hits=$(offending_imports Flex/FlexShared)
if [ -n "$hits" ]; then
  echo "shared-is-portable gate FAILED:"
  echo "$hits"
  echo
  echo "Rule: Flex/FlexShared is compiled into the iPhone app and the watch app (EPIC_001), so it"
  echo "imports only Foundation, Observation and AppIntents (the Siri intent is one definition for"
  echo "both apps, STORY_010). UIKit, SwiftUI, WatchKit, SwiftData, CloudKit and HealthKit belong"
  echo "to one platform or one device and stay in that target."
  echo "Fix: move the platform code into Flex/Flex or Flex/FlexWatch and leave the value type in"
  echo "FlexShared; the phone resolves models and the watch holds values (STORY_004)."
  exit 1
fi
echo "shared-is-portable gate passed"
