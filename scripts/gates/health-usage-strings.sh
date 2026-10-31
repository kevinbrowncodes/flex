#!/bin/sh
# Gate (STORY_008): a target whose entitlements grant HealthKit tells the user why, in both usage
# strings, or App Review rejects the build. For every XCBuildConfiguration block in the project
# whose CODE_SIGN_ENTITLEMENTS file holds com.apple.developer.healthkit, the block must set
# INFOPLIST_KEY_NSHealthShareUsageDescription and INFOPLIST_KEY_NSHealthUpdateUsageDescription.
# The gate proves itself on a planted project first, then checks the real one.
cd "$(dirname "$0")/../.." || exit 1

# Problems in a project file, one per line. $2 is the folder its CODE_SIGN_ENTITLEMENTS paths are relative to.
missing_strings() { # pbxproj, project dir
  awk -v dir="$2" '
    /isa = XCBuildConfiguration;/ { inblock = 1; ent = ""; share = 0; update = 0; start = NR; next }
    inblock && /CODE_SIGN_ENTITLEMENTS = / {
      line = $0; sub(/.*CODE_SIGN_ENTITLEMENTS = /, "", line); sub(/;.*/, "", line); gsub(/"/, "", line); ent = line
    }
    inblock && /INFOPLIST_KEY_NSHealthShareUsageDescription = "[^"]+"/ { share = 1 }
    inblock && /INFOPLIST_KEY_NSHealthUpdateUsageDescription = "[^"]+"/ { update = 1 }
    inblock && /^\t\t};/ {
      if (ent != "") {
        cmd = "grep -q com.apple.developer.healthkit \"" dir "/" ent "\" 2>/dev/null"
        if (system(cmd) == 0 && !(share && update)) {
          what = (!share && !update) ? "both Health usage strings" : (!share ? "INFOPLIST_KEY_NSHealthShareUsageDescription" : "INFOPLIST_KEY_NSHealthUpdateUsageDescription")
          printf "%s:%d: the configuration signed with %s grants HealthKit but lacks %s\n", FILENAME, start, ent, what
        }
      }
      inblock = 0
    }
  ' "$1"
}

work=$(mktemp -d "${TMPDIR:-/tmp}/health-usage-strings.XXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/App"
printf '<plist><dict><key>com.apple.developer.healthkit</key><true/></dict></plist>\n' > "$work/App/App.entitlements"
printf '<plist><dict><key>aps-environment</key><string>production</string></dict></plist>\n' > "$work/App/Plain.entitlements"
cat > "$work/project.pbxproj" <<'EOF'
		AAAA /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_ENTITLEMENTS = App/App.entitlements;
				INFOPLIST_KEY_NSHealthShareUsageDescription = "Reads heart rate.";
			};
			name = Debug;
		};
		BBBB /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_ENTITLEMENTS = App/App.entitlements;
				INFOPLIST_KEY_NSHealthShareUsageDescription = "Reads heart rate.";
				INFOPLIST_KEY_NSHealthUpdateUsageDescription = "Writes workouts.";
			};
			name = Release;
		};
		CCCC /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_ENTITLEMENTS = App/Plain.entitlements;
			};
			name = Debug;
		};
EOF
# The planted blocks' "isa" lines are 2 (missing the update string), 10 (complete) and 18 (no Health).
hits=$(missing_strings "$work/project.pbxproj" "$work")
case "$hits" in
  *":2: "*"NSHealthUpdateUsageDescription"*) ;;
  *) echo "health-usage-strings self-test FAILED: the planted block missing its update string was not caught"; echo "$hits"; exit 1 ;;
esac
case "$hits" in
  *":10: "*|*":18: "*) echo "health-usage-strings self-test FAILED: a complete block or a non-Health target was refused"; echo "$hits"; exit 1 ;;
esac

hits=$(missing_strings Flex/Flex.xcodeproj/project.pbxproj Flex)
if [ -n "$hits" ]; then
  echo "health-usage-strings gate FAILED:"
  echo "$hits"
  echo
  echo "Rule: a target whose entitlements grant HealthKit sets both INFOPLIST_KEY_NSHealthShareUsageDescription"
  echo "and INFOPLIST_KEY_NSHealthUpdateUsageDescription in every configuration (STORY_008); App Review"
  echo "rejects a HealthKit app without them, and the words are what the user reads on the Health sheet."
  echo "Fix: add the two settings to the configuration the line names, in Flex/Flex.xcodeproj/project.pbxproj."
  exit 1
fi
echo "health-usage-strings gate passed"
