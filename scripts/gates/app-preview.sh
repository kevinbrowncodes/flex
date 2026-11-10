#!/bin/sh
# Gate (STORY_014): the iPhone app preview Launch uploads exists and is what App Store Connect
# takes for the 6.9" slot: appstore/preview/iphone-6.9.mp4, 886 x 1920 portrait, H.264, 30 fps or
# less, 15 to 30 seconds. The gate first proves each rule against planted videos, then checks the
# real one. Needs ffprobe and ffmpeg (brew install ffmpeg).
cd "$(dirname "$0")/../.." || exit 1

PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
if ! command -v ffprobe >/dev/null 2>&1 || ! command -v ffmpeg >/dev/null 2>&1; then
  echo "app-preview gate FAILED: ffprobe/ffmpeg not found."
  echo "Rule: the pre-push gates check the App Store preview video with ffprobe (STORY_014)."
  echo "Fix: brew install ffmpeg"
  exit 1
fi

PREVIEW="appstore/preview/iphone-6.9.mp4"

# Prints the problems with one video, one per line; nothing when it passes.
problems() { # file
  if [ ! -f "$1" ]; then echo "missing: $1"; return; fi
  probe=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name,width,height,r_frame_rate:format=duration \
    -of default=noprint_wrappers=1 "$1" 2>/dev/null)
  codec=$(echo "$probe" | sed -n 's/^codec_name=//p')
  width=$(echo "$probe" | sed -n 's/^width=//p')
  height=$(echo "$probe" | sed -n 's/^height=//p')
  rate=$(echo "$probe" | sed -n 's/^r_frame_rate=//p')
  duration=$(echo "$probe" | sed -n 's/^duration=//p')
  fps=$(echo "$rate" | awk -F/ '{ if ($2 > 0) printf "%.2f", $1 / $2; else print $1 }')
  [ "$codec" = "h264" ] || echo "codec is '$codec', not h264"
  [ "$width" = "886" ] && [ "$height" = "1920" ] || echo "size is ${width}x${height}, not 886x1920"
  awk -v f="$fps" 'BEGIN { exit !(f > 30.01) }' && echo "frame rate is $fps, over 30"
  awk -v d="$duration" 'BEGIN { exit !(d < 15 || d > 30) }' && echo "duration is ${duration}s, outside 15 to 30"
}

# Self-test: a planted wrong video fails on every count; a planted right one passes.
tmp=$(mktemp -d)
ffmpeg -v error -y -f lavfi -i "color=c=black:s=100x100:r=60:d=2" -c:v mpeg4 "$tmp/wrong.mp4" || exit 1
ffmpeg -v error -y -f lavfi -i "color=c=black:s=886x1920:r=30:d=16" -c:v libx264 -preset ultrafast -pix_fmt yuv420p "$tmp/right.mp4" || exit 1
wrong=$(problems "$tmp/wrong.mp4")
right=$(problems "$tmp/right.mp4")
rm -rf "$tmp"
for want in "not h264" "not 886x1920" "over 30" "outside 15 to 30"; do
  case "$wrong" in *"$want"*) ;; *)
    echo "app-preview gate FAILED its self-test: a planted wrong video was not refused for '$want'."
    echo "Fix: scripts/gates/app-preview.sh's checks changed; make them refuse it again."
    exit 1 ;;
  esac
done
if [ -n "$right" ]; then
  echo "app-preview gate FAILED its self-test: a planted right video was refused:"
  echo "$right"
  exit 1
fi

found=$(problems "$PREVIEW")
if [ -n "$found" ]; then
  echo "app-preview gate FAILED:"
  echo "$found" | sed 's/^/  /'
  echo "Rule: Launch uploads $PREVIEW as the iPhone 6.9\" app preview, so it is 886 x 1920 H.264"
  echo "at 30 fps or less and 15 to 30 seconds long, Apple's spec for the slot (STORY_014)."
  echo "Fix: scripts/preview.sh records and renders it from the simulator; run it and commit the result."
  exit 1
fi
echo "app-preview gate passed"
