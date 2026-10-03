// Hot-reload Neptune's userChrome.css without restarting Firefox.
//
// 1. Once: about:config -> devtools.chrome.enabled = true
// 2. Open the Browser Console: Cmd+Shift+J (Tools > Browser Tools > Browser Console)
// 3. Paste this whole file into its command line and press Enter. Repeat after each edit.
//
// How it works: Firefox loads the profile's userChrome.css once at startup and
// offers no reload. This registers the on-disk file AGAIN as a user-origin sheet
// (cache-busted) via nsIStyleSheetService; it lands later in the cascade, so any
// rule you changed wins over the stale startup copy.
//
// Caveat: the startup copy can't be unloaded, so RULES YOU DELETED still apply
// until a real restart. Good for iterating on additions/overrides; restart to
// confirm a clean state before committing.
(() => {
  const PROFILE_CHROME = "file:///Users/erudneva/Library/Application%20Support/Firefox/Profiles/pxx3k2z3.default-release/chrome/";
  const sss = Cc["@mozilla.org/content/style-sheet-service;1"].getService(Ci.nsIStyleSheetService);
  // Drop the previous hot-loaded copies so repeated runs don't pile up.
  for (const u of (globalThis.__neptuneHotSheets ||= [])) {
    try { sss.unregisterSheet(u, sss.USER_SHEET); } catch {}
  }
  globalThis.__neptuneHotSheets = [];
  for (const name of ["userChrome.css"]) {
    const uri = Services.io.newURI(PROFILE_CHROME + name + "?reload=" + Date.now());
    sss.loadAndRegisterSheet(uri, sss.USER_SHEET);
    globalThis.__neptuneHotSheets.push(uri);
  }
  console.log("Neptune: userChrome.css hot-reloaded at " + new Date().toLocaleTimeString() +
              " (deleted rules need a real restart)");
})();
