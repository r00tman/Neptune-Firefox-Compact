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

- **Required settings**
    - Move all toolbar buttons to the top, and the tab bar does not display any buttons.
    - If extension (Adaptive Tab Bar Color) is enabled, set all colors in the Options (theme builder) to `0%`.

## Safari-style tabs (on by default)

The address bar floats over the **active tab**: at rest the tab shows the page title; hovering it, focusing it (`Cmd+L`) or opening results shows the address, security shield and page actions in the same pill. Resting the pointer on the favicon turns it into the close button; a quick sweep across the pill doesn't.

- **Turn off / on without restarting:** in `about:config` create the boolean `neptune.safari-tabs.disabled` and set it to `true` — the layout switches back immediately. Set it to `false` (or delete it) to re-enable.
- **Hard off:** comment out the `@import "neptune/optionals/Safari_style_tabs.css";` line at the end of `userChrome.css`.
- **Tuning** (top of `neptune/optionals/Safari_style_tabs.css`): `--nept-safari-hover-delay` (how long before the favicon becomes the close button, default `30ms`), `--nept-safari-lead` / `--nept-safari-trail` (space kept for the favicon and the speaker button), `--nept-safari-tab-width`.
- It falls back to the plain layout automatically for vertical tabs, customize mode, fullscreen, popup windows, a pinned or split-view active tab, while dragging a tab, and with 12 or more visible tabs.

Requires Firefox 157+ (CSS anchor positioning).

ENJOY!