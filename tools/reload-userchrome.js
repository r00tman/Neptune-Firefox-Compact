// Hot-reload Neptune's userChrome.css without restarting Firefox.
//
// 1. Once: about:config -> devtools.chrome.enabled = true
// 2. Open the Browser Console: Cmd+Shift+J (Tools > Browser Tools > Browser Console)
// 3. Paste this whole file into its command line and press Enter. Repeat after each edit.
//
// How it works: Firefox loads the profile's userChrome.css once at startup and
// offers no reload. This walks the @import tree from the on-disk userChrome.css
// and registers every file in it AGAIN as a user-origin sheet, each with a
// cache-busting query (an @import of an unchanged URL would just return the copy
// cached at startup). They land later in the cascade, in the same order, so your
// edits win over the stale startup copies.
//
// Caveat: the startup copies can't be unloaded, so RULES YOU DELETED still apply
// until a real restart. Good for iterating on additions/overrides; restart to
// confirm a clean state before committing.
(async () => {
  const PROFILE_CHROME = PathUtils.join(PathUtils.profileDir, "chrome");
  const sss = Cc["@mozilla.org/content/style-sheet-service;1"].getService(Ci.nsIStyleSheetService);
  for (const u of (globalThis.__neptuneHotSheets ||= [])) {
    try { sss.unregisterSheet(u, sss.USER_SHEET); } catch {}
  }
  globalThis.__neptuneHotSheets = [];

  // Pre-order: a parent before its children. Re-registering a parent also pulls in
  // its children's STALE cached copies via its plain @imports, so the fresh child
  // copies must come after it to win. (userChrome.css and main.css contain only
  // @imports, so registering them first doesn't misorder any rules of their own.)
  const order = [];
  const seen = new Set();
  async function walk(path) {
    if (seen.has(path)) return;
    seen.add(path);
    order.push(path);
    const text = (await IOUtils.readUTF8(path)).replace(/\/\*[\s\S]*?\*\//g, "");
    for (const m of text.matchAll(/@import\s+(?:url\()?["']([^"']+)["']\)?/g)) {
      await walk(PathUtils.normalize(PathUtils.join(PathUtils.parent(path), ...m[1].split("/"))));
    }
  }
  await walk(PathUtils.join(PROFILE_CHROME, "userChrome.css"));

  const bust = Date.now();
  for (const path of order) {
    const uri = Services.io.newURI(PathUtils.toFileURI(path) + "?reload=" + bust);
    sss.loadAndRegisterSheet(uri, sss.USER_SHEET);
    globalThis.__neptuneHotSheets.push(uri);
  }
  console.log(`Neptune: ${order.length} stylesheets hot-reloaded at ${new Date().toLocaleTimeString()} (deleted rules need a real restart)`);
})();
