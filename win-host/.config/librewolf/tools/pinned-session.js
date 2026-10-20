// Seeds a LibreWolf session with pinned tabs (only while LibreWolf is closed; replaces the session).
//   node pinned-session.js <profileDir> <containerId|0> <url>...
const fs = require('fs')
const path = require('path')
const [profileDir, ctx, ...urls] = process.argv.slice(2)

const session = {
  version: ['sessionrestore', 1],
  windows: [{
    tabs: urls.map(url => ({
      entries: [{ url, title: url, triggeringPrincipal_base64: '{"3":{}}' }],
      index: 1,
      pinned: true,
      hidden: false,
      userContextId: Number(ctx),
    })),
    selected: 1,
    _closedTabs: [],
  }],
  selectedWindow: 1,
  _closedWindows: [],
  session: { state: 'stopped' },
}

// mozlz4 = magic + uint32 size + one LZ4 block; a literals-only block is valid LZ4
const data = Buffer.from(JSON.stringify(session))
const head = Buffer.alloc(12)
head.write('mozLz40\0', 0, 'latin1')
head.writeUInt32LE(data.length, 8)
const len = []
let token = 0xf0
let rest = data.length - 15
if (data.length < 15) token = data.length << 4
else { while (rest >= 255) { len.push(255); rest -= 255 } len.push(rest) }
const out = Buffer.concat([head, Buffer.from([token, ...len]), data])

fs.rmSync(path.join(profileDir, 'sessionstore-backups'), { recursive: true, force: true })
fs.writeFileSync(path.join(profileDir, 'sessionstore.jsonlz4'), out)
console.log(`wrote ${urls.length} pinned tabs`)
