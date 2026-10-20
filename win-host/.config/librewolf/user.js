// LibreWolf user prefs (copied into the profile by install.ps1, re-applied on every start)

// --- session: reopen all tabs, keep logins --------------------------------
user_pref("browser.startup.page", 3);
// pinned tabs are restored eagerly by default: six web apps loading at once made startup ~5s
// (they also get a real browser each; librewolf.overrides.cfg makes them lazy)
user_pref("browser.sessionstore.restore_pinned_tabs_on_demand", true);
// LibreWolf turns the disk cache off: web apps would re-download all their assets after every start
user_pref("browser.cache.disk.enable", true);
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
user_pref("privacy.clearOnShutdown_v2.cache", false);
user_pref("privacy.clearOnShutdown_v2.browsingHistoryAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.formdata", false);
user_pref("privacy.clearOnShutdown_v2.siteSettings", false);
user_pref("browser.sessionstore.resume_from_crash", true);
user_pref("browser.tabs.closeWindowWithLastTab", false);
user_pref("browser.warnOnQuit", false);

// --- Firefox account / sync -------------------------------------------------
user_pref("identity.fxaccounts.enabled", true);

// --- privacy tradeoffs for a daily driver ---------------------------------
// RFP forces UTC time, light color scheme for sites and a spoofed UA/locale.
// Firefox's lighter fingerprinting protection (FPP) stays on instead.
user_pref("privacy.resistFingerprinting", false);
user_pref("privacy.fingerprintingProtection", true);
user_pref("layout.css.prefers-color-scheme.content-override", 0); // sites get dark
// trust the Windows cert store (company CA for internal hosts)
user_pref("security.enterprise_roots.enabled", true);

// --- UI: Sidebery replaces the tab strip ----------------------------------
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("sidebar.revamp", false);
user_pref("sidebar.verticalTabs", false);
user_pref("sidebar.position_start", true);
user_pref("browser.toolbars.bookmarks.visibility", "always");
user_pref("browser.tabs.inTitlebar", 1);
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);
user_pref("browser.tabs.groups.enabled", false);
user_pref("browser.tabs.splitView.enabled", true);
// Sidebery open in windows without restored sidebar state (first start, new windows)
user_pref("sidebar.visibility", "always-show");
user_pref("sidebar.backupState", "{\"command\":\"_3c078156-979c-498b-8990-85f7987dd929_-sidebar-action\",\"panelOpen\":true,\"launcherExpanded\":false,\"launcherVisible\":false}");

// --- keys ------------------------------------------------------------------
// Ctrl+Tab cycles in tab order, no preview popup
user_pref("browser.ctrlTab.sortByRecentlyUsed", false);
// Alt alone must not focus the menubar (Vimium / komorebi friendly)
user_pref("ui.key.menuAccessKeyFocuses", false);

// --- extensions --------------------------------------------------------------
// install.ps1 drops .xpi files into <profile>/extensions; enable them without a prompt
user_pref("extensions.autoDisableScopes", 0);
user_pref("extensions.enabledScopes", 15);
// local unsigned add-ons (iceberg theme, lw-helper)
user_pref("xpinstall.signatures.required", false);
// (the Iceberg theme gets enabled once by lw-helper; extensions.activeThemeID alone does nothing)

// --- misc --------------------------------------------------------------------
user_pref("browser.newtabpage.enabled", false); // blank new tab, no flash
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.download.autohideButton", true);
user_pref("full-screen-api.transition-duration.enter", "0 0");
user_pref("full-screen-api.transition-duration.leave", "0 0");
