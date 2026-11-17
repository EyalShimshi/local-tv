#!/usr/bin/env bash
# Runs the release APK on an emulator before it's published. R8 removes code it thinks is unused,
# and code that is only reached by reflection breaks only when the app runs. Opens the app, plays a
# public test stream from a localtv:// link (always available, whatever is on air), visits every
# tab and Settings, goes to the home screen, and fails if the app crashes or nothing plays. Crashes
# are shown with the original names, decoded with the build's mapping file. Screenshots
# (smoke-*.png) are published with the build.
# Usage: smoke-test.sh <apk> <mapping.txt>
set -u

apk=$1
mapping=$2
pkg=io.github.eyalshimshi.localtv
# https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8, URL-encoded for the link.
test_stream="https%3A%2F%2Ftest-streams.mux.dev%2Fx36xhzz%2Fx36xhzz.m3u8"
retrace="$ANDROID_HOME/cmdline-tools/latest/bin/retrace"

# Every adb call gives up after a minute, so a frozen emulator fails the test instead of hanging it.
adb_bin=$(command -v adb)
adb() {
  timeout 60 "$adb_bin" "$@"
}

# Fails the test; the details go to the log and to the run's Summary page.
fail() {
  local message=$1 details=${2:-}
  echo "::error::$message"
  {
    echo "## Smoke test: $message"
    if [ -n "$details" ]; then
      echo '```'
      cat "$details"
      echo '```'
    fi
  } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
  if [ -n "$details" ]; then cat "$details"; fi
  exit 1
}

# Writes $1 with the original class and method names to decoded.txt.
decode() {
  "$retrace" "$mapping" "$1" > decoded.txt 2>&1 || cp "$1" decoded.txt
}

check_no_crash() {
  adb logcat -d -b crash > crash.txt
  if grep -q "Process: $pkg" crash.txt; then
    decode crash.txt
    fail "Local TV crashed $1" decoded.txt
  fi
}

screenshot() {
  adb exec-out screencap -p > "smoke-$1.png" 2> /dev/null || true
}

# Writes the text on the screen and Local TV's own log to decoded.txt, with the original names.
collect_diagnostics() {
  local pid
  pid=$(adb shell pidof "$pkg" | tr -d '\r')
  {
    echo "--- Text on the screen ---"
    timeout 30 adb shell uiautomator dump /sdcard/window.xml > /dev/null
    adb shell cat /sdcard/window.xml | grep -oE '(text|content-desc)="[^"]+"' | head -n 80
    echo "--- Local TV's log ---"
    adb logcat -d -s LocalTV:V | tail -n 60
    if [ -n "$pid" ]; then adb logcat -d --pid="$pid" | tail -n 200; fi
  } > diagnostics.txt 2>&1
  screenshot failure
  decode diagnostics.txt
}

# Waits up to $2 seconds for Local TV's log to show $1.
wait_for_log() {
  local deadline=$((SECONDS + $2))
  while [ "$SECONDS" -lt "$deadline" ]; do
    check_no_crash "$3"
    if adb logcat -d -s LocalTV:V | grep -q "$1"; then return 0; fi
    sleep 3
  done
  return 1
}

# Taps the element whose $1 attribute (text or content-desc) is $2, found in the accessibility tree.
tap() {
  timeout 30 adb shell uiautomator dump /sdcard/window.xml > /dev/null
  local bounds x1 y1 x2 y2
  bounds=$(adb shell cat /sdcard/window.xml | grep -oE "$1=\"$2\"[^>]*bounds=\"[^\"]+\"" | head -n 1 |
    grep -oE '\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]')
  if [ -z "$bounds" ]; then return 1; fi
  read -r x1 y1 x2 y2 <<< "$(echo "$bounds" | tr -c '0-9' ' ')"
  adb shell input tap $(((x1 + x2) / 2)) $(((y1 + y2) / 2))
}

must_tap() {
  if ! tap "$1" "$2"; then
    collect_diagnostics
    fail "There is no \"$2\" on the screen" decoded.txt
  fi
}

timeout 300 "$adb_bin" install -r -g "$apk" || fail "The APK didn't install"
adb logcat -c || true

echo "Opening Local TV"
adb shell am start -W -n "$pkg/.MainActivity"
sleep 15
check_no_crash "while opening"
adb shell pidof "$pkg" > /dev/null || fail "Local TV isn't running after opening it"
screenshot watch

echo "Playing a test stream from a localtv:// link"
adb shell "am start -W -a android.intent.action.VIEW -d 'localtv://play?url=$test_stream&name=Smoke%20test' -n $pkg/.MainActivity"
if ! wait_for_log "playing preview" 90 "while playing the test stream"; then
  collect_diagnostics
  fail "The test stream didn't start playing" decoded.txt
fi
if wait_for_log "first frame preview" 20 "while showing the test stream"; then
  echo "The test stream's picture is showing"
else
  echo "::warning::No video frame was reported for the test stream (the emulator may not draw video)"
fi
sleep 5
screenshot spotlight

for tab in Channels News Watch; do
  echo "Opening the $tab tab"
  must_tap text "$tab"
  sleep 6
  check_no_crash "on the $tab tab"
  screenshot "$(echo "$tab" | tr '[:upper:]' '[:lower:]')-tab"
done

echo "Opening Settings"
if tap content-desc "More options" && sleep 2 && tap text "Settings"; then
  sleep 3
  check_no_crash "in Settings"
  screenshot settings
  adb shell input keyevent KEYCODE_BACK
  sleep 2
else
  echo "::warning::Couldn't open Settings from the menu"
  adb shell input keyevent KEYCODE_BACK
fi

echo "Going to the home screen (picture-in-picture)"
adb shell input keyevent KEYCODE_HOME
sleep 8
check_no_crash "in the background"
screenshot home

# Stops the players so the emulator shuts down quickly.
adb shell am force-stop "$pkg" || true

echo "Smoke test passed: Local TV opened, played the test stream and showed every tab."
echo "Smoke test passed: Local TV opened, played the test stream and showed every tab." >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
