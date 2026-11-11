#!/bin/sh
# Gate (BUG_002): the App Store name and subtitle name no Apple product or service. App Review
# rejected 1.1.0 (guideline 5.2.5, 2026-11-10) for "Workout log & Apple Watch" as the subtitle:
# beside the app name, an Apple mark reads as part of the product's name. Apple allows its marks
# only as a reference ("works with Apple Watch") in the description, promo text or What's New.
# The gate proves itself on planted metadata first, then checks appstore/asc_meta.json.
cd "$(dirname "$0")/../.." || exit 1

# Problems in a metadata file, one per line: every "name" and "subtitle" string at any depth
# (top level and per-locale blocks) that holds an Apple mark as a whole word.
apple_marks() { # asc_meta.json
  python3 -I - "$1" <<'PY'
import json, re, sys
marks = ["Apple Watch", "Apple Health", "Apple", "iPhone", "iPad", "Mac", "macOS", "iOS",
         "iPadOS", "watchOS", "Siri", "HealthKit", "iCloud", "AirPods"]
pattern = re.compile(r"(?<![A-Za-z])(" + "|".join(re.escape(m) for m in marks) + r")(?![A-Za-z])", re.I)
def walk(node, path):
    if isinstance(node, dict):
        for k, v in node.items():
            if k in ("name", "subtitle") and isinstance(v, str):
                hit = pattern.search(v)
                if hit:
                    print(f"{path}{k} = {v!r} names {hit.group(1)!r}")
            else:
                walk(v, f"{path}{k}.")
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk(v, f"{path}{i}.")
walk(json.load(open(sys.argv[1])), "")
PY
}

work=$(mktemp -d "${TMPDIR:-/tmp}/store-names.XXXXXX")
trap 'rm -rf "$work"' EXIT
printf '{"subtitle": "Workout log & Apple Watch", "localizations": {"fr-FR": {"name": "Flex pour iPhone", "subtitle": "Journal, au poignet"}}}\n' > "$work/bad.json"
printf '{"subtitle": "Workout log, on your wrist", "description": "Works with Apple Watch and iPhone."}\n' > "$work/good.json"
hits=$(apple_marks "$work/bad.json")
case "$hits" in
  *"subtitle = 'Workout log & Apple Watch' names 'Apple Watch'"*"localizations.fr-FR.name"*"'iPhone'"*) ;;
  *) echo "store-names self-test FAILED: the planted Apple Watch subtitle or iPhone name was not caught"; echo "$hits"; exit 1 ;;
esac
case "$hits" in
  *"Journal"*) echo "store-names self-test FAILED: a clean planted subtitle was refused"; echo "$hits"; exit 1 ;;
esac
hits=$(apple_marks "$work/good.json")
if [ -n "$hits" ]; then
  echo "store-names self-test FAILED: a clean subtitle, or a mark in the description, was refused"; echo "$hits"; exit 1
fi

hits=$(apple_marks appstore/asc_meta.json)
if [ -n "$hits" ]; then
  echo "store-names gate FAILED:"
  echo "$hits"
  echo
  echo "Rule: the App Store name and subtitle never name an Apple product or service (BUG_002). App"
  echo "Review rejected Flex 1.1.0 under guideline 5.2.5 for \"Workout log & Apple Watch\" as the subtitle."
  echo "Apple's marks may appear only as a reference (\"works with Apple Watch\") in the description,"
  echo "promotional text or What's New."
  echo "Fix: reword the field in appstore/asc_meta.json without the mark (\"Workout log, on your wrist\")."
  exit 1
fi
echo "store-names gate passed"
