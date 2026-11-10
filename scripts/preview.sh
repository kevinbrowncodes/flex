#!/usr/bin/env bash
#
# Records and renders the iPhone App Store preview (STORY_014):
#   1. boots the iPhone 6.9" simulator with a 9:41 status bar and starts `simctl io recordVideo`
#   2. runs FlexUITests/PreviewTests, which plays the storyboard in demo mode and writes a
#      wall-clock mark file for every beat (start, opened, tick1, restcue, tick2, finished, end)
#      into FLEX_PREVIEW_DIR
#   3. stops the recording, trims it to the storyboard, scales it to Apple's 886 x 1920, burns the
#      five overlays between the beats, and writes appstore/preview/iphone-6.9.mp4
#      (H.264, 30 fps, with a silent AAC track, which App Store Connect requires); scripts/gates/app-preview.sh checks it
#
# Usage: scripts/preview.sh [--render-only]   (render again from the last recording in PREVIEW_WORK)
# Env:   IPHONE_SIM (name or UDID), DERIVED_DATA, PREVIEW_WORK (scratch folder)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IPHONE_SIM="${IPHONE_SIM:-iPhone 17 Pro Max}"   # 1320×2868; the 6.9" group Apple sizes at 886×1920
DERIVED="${DERIVED_DATA:-$ROOT/.build/DerivedData}"
WORK="${PREVIEW_WORK:-$ROOT/.build/preview}"
OUT="$ROOT/appstore/preview/iphone-6.9.mp4"
MODE="${1:-all}"
PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
command -v ffmpeg >/dev/null || { echo "ffmpeg not found: brew install ffmpeg" >&2; exit 1; }

udid_for() {
  if [[ "$1" =~ ^[0-9A-Fa-f-]{36}$ ]]; then echo "$1"; return; fi
  xcrun simctl list devices available | grep -F "$1 (" | tail -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
}

boot() {  # $1 = udid. Reboot for a clean state, as screenshots.sh does.
  xcrun simctl shutdown "$1" 2>/dev/null || true
  xcrun simctl boot "$1"
  xcrun simctl bootstatus "$1" -b >/dev/null
}

now() { python3 -c 'import time; print(f"{time.time():.3f}")'; }

record() {
  local udid; udid="$(udid_for "$IPHONE_SIM")"
  [[ -n "$udid" ]] || { echo "No simulator named '$IPHONE_SIM'" >&2; exit 1; }
  rm -rf "$WORK"; mkdir -p "$WORK/marks"
  boot "$udid"
  xcrun simctl status_bar "$udid" override \
    --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
  # Build first so the recording does not start during a compile.
  xcodebuild build-for-testing -project "$ROOT/Flex/Flex.xcodeproj" -scheme Flex \
    -destination "id=$udid" -derivedDataPath "$DERIVED" -quiet 2>&1 | grep -E "error:" || true
  now > "$WORK/recording-start.txt"
  xcrun simctl io "$udid" recordVideo --codec h264 --force "$WORK/raw.mov" &
  local rec=$!
  sleep 2
  env TEST_RUNNER_FLEX_PREVIEW=1 TEST_RUNNER_FLEX_PREVIEW_DIR="$WORK/marks" \
    xcodebuild test-without-building \
      -project "$ROOT/Flex/Flex.xcodeproj" -scheme Flex \
      -destination "id=$udid" -derivedDataPath "$DERIVED" \
      -only-testing:FlexUITests/PreviewTests \
    | grep -E "Test Case.*(passed|failed|skipped)|error:|\*\* TEST" || true
  sleep 1
  kill -INT "$rec" 2>/dev/null || true
  wait "$rec" 2>/dev/null || true
  xcrun simctl status_bar "$udid" clear
  [[ -f "$WORK/marks/end.txt" ]] || { echo "PreviewTests wrote no end mark; the storyboard did not finish" >&2; exit 1; }
}

# Seconds into the recording for a mark.
at() { python3 -c "print(max(0.0, float(open('$WORK/marks/$1.txt').read()) - float(open('$WORK/recording-start.txt').read())))"; }

render() {
  local opened tick1 restcue tick2 finished end
  opened=$(at opened); tick1=$(at tick1); restcue=$(at restcue)
  tick2=$(at tick2); finished=$(at finished); end=$(at end)
  # The clip opens a second before the workout appears; the tab-and-folder taps before that are
  # the test's business, not the shopper's. Apple takes 15 to 30 seconds; 29.5 leaves the
  # frame-rate conversion its rounding room.
  local clip; clip=$(python3 -c "print(max(0.0, $opened - 1.0))")
  local dur; dur=$(python3 -c "print(min(29.5, $end - $clip))")
  rel() { python3 -c "print(max(0.0, $1 - $clip))"; }
  local o1b o2b o3b o4b
  o1b=$(rel "$opened + 2.0"); o2b=$(rel "$restcue"); o3b=$(rel "$tick2"); o4b=$(rel "$finished + 1.5")

  # Each overlay is two lines, a white line then the key words in the screenshot accent, rendered
  # to a PNG by scripts/preview-overlay.swift and laid over the clip between its beats.
  local lines=(
    "Flex, now on|Apple Watch|0|$o1b"
    "Log sets|from your wrist|$o1b|$o2b"
    "Rest on a|wrist-tap timer|$o2b|$o3b"
    "Finish with your|phone in the locker|$o3b|$o4b"
    "Or just say|“Log bench press in Flex”|$o4b|$dur"
  )
  local inputs=(-ss "$clip" -i "$WORK/raw.mov")
  local filter="[0:v]scale=886:1920:flags=lanczos[v0]"
  local i=0
  for spec in "${lines[@]}"; do
    IFS='|' read -r top bottom a b <<<"$spec"
    swift "$ROOT/scripts/preview-overlay.swift" "$top" "$bottom" "$WORK/overlay$i.png"
    inputs+=(-i "$WORK/overlay$i.png")
    filter+=";[v$i][$((i + 1)):v]overlay=x=33:y=1430:enable='between(t,$a,$b)'[v$((i + 1))]"
    i=$((i + 1))
  done
  mkdir -p "$(dirname "$OUT")"
  # App Store Connect refuses a preview with no audio track, even a silent one (ASSET_FAILED on
  # 2026-11-10), and a simulator recording has none: add silence.
  inputs+=(-f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=44100")
  ffmpeg -v error -y "${inputs[@]}" -filter_complex "$filter" -map "[v$i]" -map "$((i + 1)):a" -t "$dur" \
    -r 30 -fps_mode cfr -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -c:a aac -b:a 64k \
    -movflags +faststart "$OUT"
  echo "wrote $OUT ($(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$OUT")s); clip starts ${clip}s into the recording; beats: opened=$opened tick1=$tick1 restcue=$restcue tick2=$tick2 finished=$finished end=$end"
}

case "$MODE" in
  all) record; render ;;
  --render-only) render ;;
  *) echo "Usage: scripts/preview.sh [--render-only]" >&2; exit 2 ;;
esac
sh "$ROOT/scripts/gates/app-preview.sh"
