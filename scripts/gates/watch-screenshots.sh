#!/bin/sh
# Gate (STORY_012): the watch screenshots the store shows exist and are an Apple Watch App Store
# size. appstore/screenshots/out-watch/ holds the raw captures from scripts/screenshots.sh (the
# watch has no frame or caption; shotkit knows no watch device and would call these sizes wrong,
# which is why they live beside out/, not in it). App Store Connect takes 416x496 (Series 10 and
# 11, 46mm) or 410x502 (Ultra), at most ten. The gate proves itself on planted files first.
cd "$(dirname "$0")/../.." || exit 1

# Problems with a folder of watch screenshots, one per line.
check_folder() { # folder
  folder=$1
  [ -d "$folder" ] || { echo "$folder: missing"; return; }
  count=0
  for file in "$folder"/*.png; do
    [ -e "$file" ] || continue
    count=$((count + 1))
    width=$(sips -g pixelWidth "$file" 2>/dev/null | awk '/pixelWidth/ { print $2 }')
    height=$(sips -g pixelHeight "$file" 2>/dev/null | awk '/pixelHeight/ { print $2 }')
    case "${width}x${height}" in
      416x496|410x502) ;;
      *) echo "$file: ${width}x${height} is not an Apple Watch App Store size (416x496 or 410x502)" ;;
    esac
  done
  [ "$count" -eq 0 ] && echo "$folder: no PNG screenshots"
  [ "$count" -gt 10 ] && echo "$folder: $count screenshots, App Store Connect takes at most 10"
  return 0
}

work=$(mktemp -d "${TMPDIR:-/tmp}/watch-screenshots.XXXXXX")
trap 'rm -rf "$work"' EXIT
source_png=Flex/Flex/Assets.xcassets/AppIcon.appiconset/icon-1024.png
mkdir -p "$work/bad" "$work/good" "$work/empty"
sips -z 100 100 "$source_png" --out "$work/bad/01-wrong.png" >/dev/null 2>&1
sips -z 496 416 "$source_png" --out "$work/good/01-home.png" >/dev/null 2>&1
sips -z 502 410 "$source_png" --out "$work/good/02-ultra.png" >/dev/null 2>&1
hits=$(check_folder "$work/bad")
case "$hits" in
  *"100x100 is not an Apple Watch App Store size"*) ;;
  *) echo "watch-screenshots self-test FAILED: the planted 100x100 file was not caught"; echo "$hits"; exit 1 ;;
esac
hits=$(check_folder "$work/good")
if [ -n "$hits" ]; then echo "watch-screenshots self-test FAILED: the right sizes were refused"; echo "$hits"; exit 1; fi
hits=$(check_folder "$work/empty")
case "$hits" in
  *"no PNG screenshots"*) ;;
  *) echo "watch-screenshots self-test FAILED: an empty folder was not caught"; echo "$hits"; exit 1 ;;
esac

hits=$(check_folder appstore/screenshots/out-watch)
if [ -n "$hits" ]; then
  echo "watch-screenshots gate FAILED:"
  echo "$hits"
  echo
  echo "Rule: the watch app ships with its App Store screenshots: appstore/screenshots/out-watch/"
  echo "holds one to ten PNGs at 416x496 or 410x502, captured by FlexWatchUITests/WatchScreenshotTests"
  echo "on the Apple Watch Series 11 (46mm) simulator (STORY_012)."
  echo "Fix: run 'scripts/screenshots.sh --watch-only' and commit what it writes to out-watch/."
  exit 1
fi
echo "watch-screenshots gate passed"
