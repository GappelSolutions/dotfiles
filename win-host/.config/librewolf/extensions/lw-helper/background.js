// Ctrl+1..0 are Sidebery's switch_to_tab_N (set by install.ps1): they count the active
// workspace's own pins, which Firefox's built-in Ctrl+N can't since pinned tabs never hide.

// Pinned tabs remember the URL they were pinned with ("home", kept in session data so it
// survives restarts). Closing a pinned tab puts it back, unloaded, at its home URL.
// To get rid of a pinned tab for good: unpin it, then close it.
const HOME = 'home'
const pinned = new Map() // tabId -> { url, windowId, index, cookieStoreId }

async function track(tab, resetHome = false) {
  let url = resetHome ? undefined : await browser.sessions.getTabValue(tab.id, HOME)
  if (!url) {
    url = tab.url
    await browser.sessions.setTabValue(tab.id, HOME, url)
  }
  // re-read: the tab may have moved (pinning moves it) while we were awaiting
  const { windowId, index, cookieStoreId } = await browser.tabs.get(tab.id)
  pinned.set(tab.id, { url, windowId, index, cookieStoreId })
}

// trackNew only at startup: tabs created later are either pinned via onUpdated or recreated below
async function refreshIndexes(trackNew = false) {
  for (const tab of await browser.tabs.query({ pinned: true })) {
    const entry = pinned.get(tab.id)
    if (entry) Object.assign(entry, { windowId: tab.windowId, index: tab.index })
    else if (trackNew) await track(tab)
  }
}

browser.tabs.onUpdated.addListener(
  (tabId, change, tab) => {
    if (change.pinned === true && !pinned.has(tabId)) track(tab, true)
    else if (change.pinned === false) {
      pinned.delete(tabId)
      browser.sessions.removeTabValue(tabId, HOME)
    }
  },
  { properties: ['pinned'] }
)

for (const ev of ['onMoved', 'onAttached', 'onCreated']) browser.tabs[ev].addListener(() => refreshIndexes())

browser.tabs.onRemoved.addListener(async (tabId, { isWindowClosing }) => {
  const entry = pinned.get(tabId)
  pinned.delete(tabId)
  if (!entry || isWindowClosing) return

  const props = {
    windowId: entry.windowId,
    index: entry.index,
    url: entry.url,
    active: false,
    cookieStoreId: entry.cookieStoreId,
  }
  // Pinned tabs can't be created discarded, but a discarded tab stays unloaded when pinned
  let tab
  try {
    tab = await browser.tabs.create({ ...props, discarded: true })
  } catch {
    tab = await browser.tabs.create(props) // about: pages can't be created discarded
  }
  pinned.set(tab.id, { ...entry, index: tab.index })
  await browser.sessions.setTabValue(tab.id, HOME, entry.url)
  await browser.tabs.update(tab.id, { pinned: true })
  // give Sidebery time to sync the pin first, otherwise it reverts the move
  await new Promise(r => setTimeout(r, 500))
  await browser.tabs.move(tab.id, { index: entry.index })
})

refreshIndexes(true)

// Sideloaded themes start disabled and extensions.activeThemeID alone doesn't switch them.
// Enable Iceberg once per theme version (install.ps1 reinstalling a changed theme disables it
// again); picking another theme later sticks until the next theme update.
browser.management.get('iceberg-theme@cgpp').then(async theme => {
  const { themeApplied } = await browser.storage.local.get('themeApplied')
  if (theme.enabled || themeApplied === theme.version) return
  await browser.management.setEnabled(theme.id, true)
  await browser.storage.local.set({ themeApplied: theme.version })
})
