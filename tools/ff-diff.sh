#!/bin/bash
# ff-diff.sh — triage helper for updating this userChrome theme after a Firefox release.
#
#   tools/ff-diff.sh <old-version> <new-version> [workdir]
#   e.g. tools/ff-diff.sh 152 154
#
# What it does:
#   1. Downloads the theme-relevant Firefox source files at FIREFOX_<old>_0_RELEASE and
#      FIREFOX_<new>_0_RELEASE from the mozilla-firefox GitHub mirror into <workdir>/src<ver>/.
#   2. Writes unified diffs to <workdir>/diffs/ and prints them sorted by size.
#   3. Unzips the *installed* Firefox's shipped CSS/XUL/JS (omni.ja) into <workdir>/omni/.
#   4. Reports every CSS custom property the browser-chrome CSS references that Firefox no longer
#      defines (and how many consumers Firefox still has), so renamed tokens are found mechanically.
#
# Nothing here touches the repo; read the report, then patch chrome/ by hand.
# Env: FIREFOX_APP (default /Applications/Firefox.app), VERBOSE=1 (show theme-local vars too)

set -u
OLD="${1:?usage: ff-diff.sh <old> <new> [workdir]}"
NEW="${2:?usage: ff-diff.sh <old> <new> [workdir]}"
WORK="${3:-${TMPDIR:-/tmp}/ff-diff-$OLD-$NEW}"
FIREFOX_APP="${FIREFOX_APP:-/Applications/Firefox.app}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RAW="https://raw.githubusercontent.com/mozilla-firefox/firefox"
# Browser-chrome CSS only. Content-page CSS (chrome/neptune/firefox/) targets about: pages whose
# Firefox side lives outside the omni.ja subset extracted below, so it is excluded from the report.
CHROME_CSS="$REPO/chrome/neptune/theme $REPO/chrome/neptune/share $REPO/chrome/neptune/optionals $REPO/chrome/userChrome.css"

# Files whose changes have historically broken the theme. Add paths as new areas get themed.
PATHS='
browser/themes/shared/tabbrowser/tabs.css
browser/themes/shared/tabbrowser/tab.tokens.css
browser/themes/shared/tabbrowser/tabs-navbar.tokens.css
browser/themes/shared/tabbrowser/tab-hover-preview.css
browser/themes/shared/tabbrowser/content-area.css
browser/themes/shared/tabbrowser/fullscreen-and-pointerlock.css
browser/themes/shared/tabbrowser/ctrlTab.css
browser/themes/shared/browser-shared.css
browser/themes/shared/browser-colors.css
browser/themes/shared/urlbar-searchbar.css
browser/themes/shared/identity-block/identity-block.css
browser/themes/shared/notification-icons.css
browser/themes/shared/sidebar.css
browser/themes/shared/customizableui/panelUI-shared.css
browser/themes/shared/customizableui/customizeMode.css
browser/themes/shared/addons/unified-extensions.css
browser/themes/shared/downloads/indicator.css
browser/themes/shared/places/tree-icons.css
browser/themes/shared/places/editBookmark.css
browser/themes/shared/toolbarbutton-icons.css
browser/themes/shared/toolbarbuttons.css
browser/themes/osx/browser.css
browser/base/content/browser.xhtml
browser/base/content/navigator-toolbox.inc.xhtml
browser/base/content/browser-box.inc.xhtml
browser/base/content/browser.js
browser/components/tabbrowser/content/tab.js
browser/components/tabbrowser/content/tabs.js
browser/components/tabbrowser/content/tabgroup.js
browser/components/tabbrowser/content/tabgroup-menu.js
browser/components/tabbrowser/content/tabsplitview.js
browser/components/tabbrowser/content/drag-and-drop.js
browser/components/sidebar/sidebar-main.css
browser/components/sidebar/sidebar-main.mjs
browser/components/sidebar/browser-sidebar.js
browser/components/sidebar/sidebar-panel-header.css
browser/components/genai/content/chat.css
browser/components/urlbar/UrlbarInput.mjs
browser/components/urlbar/content/urlbar.inc.xhtml
toolkit/content/xul.css
toolkit/content/widgets/toolbarbutton.js
toolkit/content/widgets/arrowscrollbox.js
toolkit/themes/shared/global-shared.css
toolkit/themes/shared/popup.css
toolkit/themes/shared/menu.css
toolkit/themes/shared/toolbarbutton.css
toolkit/themes/shared/design-system/tokens-shared.css
toolkit/themes/shared/design-system/tokens-platform.css
toolkit/themes/osx/global/global.css
'

mkdir -p "$WORK/diffs" "$WORK/omni"
echo "==> workdir: $WORK"

# ---- 1. fetch sources -------------------------------------------------------
for ver in "$OLD" "$NEW"; do
  tag="FIREFOX_${ver}_0_RELEASE"
  code=$(curl -s -o /dev/null -w '%{http_code}' "$RAW/$tag/browser/themes/shared/tabbrowser/tabs.css")
  if [ "$code" != 200 ]; then
    echo "!! tag $tag not found on the mirror (HTTP $code) — check the version number" >&2
    exit 1
  fi
  for p in $PATHS; do
    out="$WORK/src$ver/$p"
    [ -s "$out" ] && continue
    mkdir -p "$(dirname "$out")"
    code=$(curl -s -o "$out" -w '%{http_code}' "$RAW/$tag/$p")
    [ "$code" = 200 ] || { rm -f "$out"; echo "   ($ver: no $p)"; }
  done
done

# ---- 2. diffs ---------------------------------------------------------------
echo
echo "==> changed files $OLD -> $NEW (lines changed, largest first):"
for p in $PATHS; do
  a="$WORK/src$OLD/$p"; b="$WORK/src$NEW/$p"
  [ -f "$a" ] && [ -f "$b" ] || continue
  d="$WORK/diffs/$(echo "$p" | tr / _).diff"
  diff -U3 "$a" "$b" > "$d"
  n=$(grep -c '^[-+][^-+]' "$d")
  [ "$n" = 0 ] && { rm -f "$d"; continue; }
  printf '%6d  %s\n' "$n" "$p"
done | sort -rn
echo "   (full diffs in $WORK/diffs/)"

# ---- 3. shipped CSS from the installed Firefox ------------------------------
echo
if [ ! -d "$FIREFOX_APP" ]; then
  echo "!! $FIREFOX_APP not found — skipping omni.ja extraction and the variable report" >&2
  exit 0
fi
installed=$(defaults read "$FIREFOX_APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
echo "==> installed Firefox: ${installed:-unknown} ($FIREFOX_APP)"
# unzip exits 2 on omni.ja's (harmless) central-directory warning, so never chain these with &&.
( cd "$WORK/omni" || exit 1
  unzip -q -o "$FIREFOX_APP/Contents/Resources/browser/omni.ja" \
    'chrome/browser/skin/classic/browser/*' 'chrome/browser/content/browser/*' 'defaults/preferences/firefox.js' >/dev/null 2>&1
  unzip -q -o "$FIREFOX_APP/Contents/Resources/omni.ja" \
    'chrome/toolkit/skin/classic/global/*' 'chrome/toolkit/content/global/*' >/dev/null 2>&1 )
[ -d "$WORK/omni/chrome/browser" ] || { echo "!! browser omni.ja extraction failed" >&2; exit 1; }
[ -d "$WORK/omni/chrome/toolkit" ] || echo "!! toolkit omni.ja extraction failed" >&2
echo "   shipped CSS/XUL/JS unzipped to $WORK/omni/ (this is ground truth; source diffs are the map)"
echo "   prefs of interest:"
grep -hE 'pref\("(browser\.nova\.enabled|sidebar\.verticalTabs|sidebar\.visibility|browser\.tabs\.notes\.enabled)"' \
  "$WORK/omni/defaults/preferences/firefox.js" 2>/dev/null | sed 's/^/     /'

# ---- 4. custom-property report ----------------------------------------------
echo
echo "==> CSS custom properties referenced by the browser-chrome CSS (theme/, share/, optionals/) that"
echo "    Firefox $NEW does not define.  ours = places in our CSS;  ff-def/ff-use = definitions/consumers"
echo "    in shipped $NEW CSS;  old-def = definitions in the downloaded $OLD sources (>0 = real rename/removal)."
echo "    Theme-local rows are hidden unless VERBOSE=1."
printf '    %-52s %5s %6s %6s %7s\n' property ours ff-def ff-use old-def
# shellcheck disable=SC2086
grep -rhoE --include='*.css' -- '--[A-Za-z][A-Za-z0-9_-]*' $CHROME_CSS | sort | uniq -c | sort -k2 \
| while read -r ours v; do
  case "$v" in --nept-*|--shadow-inner-*) continue ;; esac   # theme-local names
  ffdef=$(grep -rhoE -- "$v:" "$WORK/omni/chrome" | wc -l | tr -d ' ')
  [ "$ffdef" != 0 ] && continue
  ffuse=$(grep -rhoF -- "var($v" "$WORK/omni/chrome" | wc -l | tr -d ' ')
  olddef=$(grep -rhoE -- "$v:" "$WORK/src$OLD" 2>/dev/null | wc -l | tr -d ' ')
  # shellcheck disable=SC2086
  wedef=$(grep -rhoE --include='*.css' -- "$v:" $CHROME_CSS | wc -l | tr -d ' ')
  if [ "$olddef" != 0 ]; then
    flag="  <-- REMOVED/RENAMED in Firefox"
  elif [ "$wedef" = 0 ] && [ "$ffuse" != 0 ]; then
    flag="  (no CSS definition but Firefox consumes it: probably set from JS)"
  elif [ "$wedef" = 0 ]; then
    flag="  <-- no CSS definition anywhere: dead reference (or JS-set with no CSS consumer)"
  elif [ "${VERBOSE:-0}" = 0 ]; then
    continue
  elif [ "$ffuse" != 0 ]; then
    flag="  (defined by us, consumed by Firefox; fine)"
  else
    flag="  (theme-local; fine)"
  fi
  printf '    %-52s %5s %6s %6s %7s%s\n' "$v" "$ours" "$ffdef" "$ffuse" "$olddef" "$flag"
done

cat <<EOF

==> next steps
   - Read the largest diffs above; grep chrome/ for every removed/renamed id, class, attribute or var.
   - Check who *consumes* a var before renaming ours: grep -rhoF -- 'var(--name' "$WORK/omni/chrome"
   - Reference (never merge): curl https://github.com/yiiyahui/Neptune-Firefox/commit/<sha>.patch
   - After patching: cp -R chrome/. "\$HOME/Library/Application Support/Firefox/Profiles/<profile>/chrome/" and restart Firefox.
EOF
