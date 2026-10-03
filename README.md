<h1 align="center"><strong>Neptune Firefox</strong></h1>

**Instructions:** 
- This theme is compatible with the latest release of Firefox and works on both Windows and macOS.
- To enable adaptive colors, you need to install the **[Adaptive Tab Bar Color](https://addons.mozilla.org/firefox/addon/adaptive-tab-bar-colour)** extension. If not, the tabs will appear transparent.

<img src="info/preview.png" alt="Preview Image" width="800px">

## Installation

- Download the theme file and unzip the `chrome` folder into your `profile` folder.
- You can modify the wallpaper in the `userContent.css`, and edit the file names for the light and dark modes

```css
body {
	background: url("neptune/image/RainbowLight.png") center/cover no-repeat fixed;

	@media (prefers-color-scheme: dark) {
		background: url("neptune/image/RainbowDark.png") center/cover no-repeat fixed;
	}
}
```

## Configuration

- **about:config**
    - Set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`.
    - Set `svg.context-properties.content.enabled` to `true`.
    - Set `widget.non-native-theme.use-theme-accent` to `true`.
    - **Firefox 157+:** set `browser.nova.enabled` to `false`. Firefox 157 turned on its "Nova" redesign by default; this theme targets the classic layout (accent-bordered rows, the "joint" address bar surface and the new tab tokens are all Nova). Firefox may reset this on upgrade, so it is safer to pin it in a `user.js` file next to `prefs.js` in your profile folder:
      ```js
      user_pref("browser.nova.enabled", false);
      ```

- **Required settings**
    - Move all toolbar buttons to the top, and the tab bar does not display any buttons.
    - If extension (Adaptive Tab Bar Color) is enabled, set all colors in the Options (theme builder) to `0%`.

- **Sidebar:** Firefox 157 also switched everyone to the new sidebar and, for existing profiles, to `sidebar.visibility = hide-launcher` (the panel title becomes a switcher dropdown). Both are styled; if you prefer the old sidebar, `user_pref("sidebar.revamp", false);` still works for now.

## Updating

Firefox updates regularly rename the ids, classes and CSS tokens this theme relies on, so after an update that changes the look:

1. `tools/ff-diff.sh <old> <new>` (e.g. `tools/ff-diff.sh 157 158`) downloads the relevant Firefox sources at both release tags, diffs them, unzips the installed build's shipped CSS, and reports every token the theme uses that Firefox no longer defines — plus the `firefox.js` default-pref diff, which is where surprises like Nova show up.
2. Patch `chrome/`, then copy it into the profile: `cp -R chrome/. "<profile>/chrome/"`. The profile copy is a plain copy, not a link.
3. To try CSS changes without restarting, set `devtools.chrome.enabled` to `true`, open the Browser Console (`Cmd+Shift+J`) and paste `tools/reload-userchrome.js`. Rules you *deleted* only disappear after a real restart.

## Safari-style tabs (on by default)

The address bar floats over the **active tab**: at rest the tab shows the page title; hovering it, focusing it (`Cmd+L`) or opening results shows the address, security shield and page actions in the same pill. Resting the pointer on the favicon turns it into the close button; a quick sweep across the pill doesn't.

- **Turn off / on without restarting:** in `about:config` create the boolean `neptune.safari-tabs.disabled` and set it to `true` — the layout switches back immediately. Set it to `false` (or delete it) to re-enable.
- **Hard off:** comment out the `@import "neptune/optionals/Safari_style_tabs.css";` line at the end of `userChrome.css`.
- **Tuning** (top of `neptune/optionals/Safari_style_tabs.css`): `--nept-safari-hover-delay` (how long before the favicon becomes the close button, default `30ms`), `--nept-safari-lead` / `--nept-safari-trail` (space kept for the favicon and the speaker button), `--nept-safari-tab-width`.
- It falls back to the plain layout automatically for vertical tabs, customize mode, fullscreen, popup windows, a pinned or split-view active tab, while dragging a tab, and with 12 or more visible tabs.

Requires Firefox 157+ (CSS anchor positioning).

ENJOY!