"""Lays out hitch-graph's model (stdin) as an Excalidraw drawing (stdout).

One band per Feature, stacked top to bottom. In a band each Story is a lane
(a row; Stories without Tasks share one), and a Task's column is its place in
the dependency order, so the work flows left to right. Predecessor links
inside a band, transitively reduced, are orthogonal arrows routed through the
gaps between columns, each source or target getting its own track there.
Links to items outside the band, or to a Story with Tasks, are "after #id"
and "before #id" badges instead of long lines.
"""

import json
import sys
import textwrap

W, H = 260, 76  # node
ROW_GAP = 34  # between rows in a lane; badges and channels run here
LANE_PAD = 18
LANE_GAP = 10
LABEL_W = 300  # lane label cell
GAP_MIN, TRACK = 100, 20  # column gap: minimum width, per track
BAND_HEAD = 64
BAND_GAP = 90
ISOLATED_COLS = 4  # nodes without links fill rows of at least this many

COLORS = {
    "done": ("#2b8a3e", "#d3f9d8"),
    "review": ("#e67700", "#fff3bf"),
    "build": ("#1971c2", "#d0ebff"),
    "todo": ("#868e96", "#f1f3f5"),
}
# Links from an open item, one color per source so its lines can be followed; from a closed one grey.
LINE_COLORS = ["#343a40", "#1971c2", "#c2255c", "#e8590c", "#6741d9", "#0c8599", "#5c940d", "#9c36b5"]
LINE_DONE = "#ced4da"
LEGEND = [("done", "Closed"), ("review", "PR in review"), ("build", "Active"), ("todo", "New")]

model = json.load(sys.stdin)
url = model["url"]
elements = []


def add(kind, **props):
    n = len(elements) + 1
    element = {
        "id": f"{kind[0]}{n}", "type": kind, "angle": 0, "opacity": 100, "groupIds": [], "frameId": None,
        "seed": n, "version": 1, "versionNonce": n, "isDeleted": False, "updated": 1, "locked": False,
        "link": None, "boundElements": None, "roundness": None, "strokeWidth": 1, "strokeStyle": "solid",
        "roughness": 0, "fillStyle": "solid", "strokeColor": "#1e1e1e", "backgroundColor": "transparent",
    }
    element.update(props)
    elements.append(element)
    return element


def wrap(text, width, lines):
    out = textwrap.wrap(text, width) or [""]
    if len(out) > lines:
        out = out[:lines]
        out[-1] = out[-1][: width - 1].rstrip() + "…"
    return "\n".join(out)


def text(x, y, value, size, color="#1e1e1e", link=None, container=None, width=None):
    lines = value.count("\n") + 1
    longest = max(len(line) for line in value.split("\n"))
    return add(
        "text", x=x, y=y, width=width or longest * size * 0.55, height=lines * size * 1.25, text=value,
        originalText=value, fontSize=size, fontFamily=2, lineHeight=1.25, autoResize=container is None,
        textAlign="center" if container else "left", verticalAlign="middle" if container else "top",
        containerId=container, strokeColor=color, link=link,
    )


def box(x, y, w, h, cls, value, link):
    stroke, fill = COLORS[cls]
    rect = add("rectangle", x=x, y=y, width=w, height=h, strokeColor=stroke, backgroundColor=fill,
               strokeWidth=2, roundness={"type": 3}, link=link)
    label = text(x + 10, y + 8, value, 16, link=link, container=rect["id"], width=w - 20)
    label["y"] = y + (h - label["height"]) / 2
    rect["boundElements"] = [{"type": "text", "id": label["id"]}]
    return rect


def badges(x, y, refs, size=13):
    """"after #1, before #2" as one text element per id, each linked to its item."""
    for word in ("after", "before"):
        ids = sorted(refs.get(word, ()))
        if not ids:
            continue
        text(x, y, word, size, "#868e96")
        x += (len(word) + 1) * size * 0.55
        for i in ids:
            text(x, y, f"#{i}", size, "#1971c2", link=f"{url}{i}")
            x += (len(str(i)) + 2.5) * size * 0.55
        x += size


def reduce_transitive(succ):
    """Drops a -> c when a reaches c through another successor."""
    memo = {}

    def reach(n):
        if n not in memo:
            memo[n] = set()
            for s in succ[n]:
                memo[n] |= {s} | reach(s)
        return memo[n]

    return {n: {s for s in ss if not any(s in reach(o) for o in ss if o != s)} for n, ss in succ.items()}


def band(top, title, link, stories, items):
    """Draws one Feature's band from y=top; returns its bottom."""
    nodes = {}  # id -> lane key; Tasks, and Stories without Tasks
    lanes = {}  # lane key -> story or None (Stories without Tasks)
    for s in stories:
        tasks = [t for t in model["tasks"] if t["story"] == s["id"]]
        if tasks:
            lanes[s["id"]] = s
            nodes.update({t["id"]: s["id"] for t in tasks})
        else:
            lanes.setdefault("loose", None)
            nodes[s["id"]] = "loose"

    refs = {}  # id (node or Story) -> {"after": ids, "before": ids}
    succ = {n: set() for n in nodes}
    for a, b in model["edges"]:
        if a in nodes and b in nodes:
            succ[a].add(b)
        else:
            if b in nodes or b in lanes:
                refs.setdefault(b, {}).setdefault("after", set()).add(a)
            if a in nodes or a in lanes:
                refs.setdefault(a, {}).setdefault("before", set()).add(b)
    succ = reduce_transitive(succ)
    pred = {n: {a for a in nodes if n in succ[a]} for n in nodes}

    # Columns: longest path from the sources; a source sits right before its first successor.
    col = {}

    def depth(n):
        if n not in col:
            col[n] = max((depth(p) + 1 for p in pred[n]), default=0)
        return col[n]

    linked = [n for n in nodes if succ[n] or pred[n]]
    for n in linked:
        depth(n)
    for n in linked:
        if not pred[n]:
            col[n] = min(col[s] for s in succ[n]) - 1
    cols = max([col[n] + 1 for n in linked], default=0)

    # Rows in a lane: a node takes the free row nearest its predecessors' in the same lane.
    row = {}
    order = sorted(lanes, key=lambda k: (k == "loose", min((col[n] for n in linked if nodes[n] == k), default=cols), str(k)))
    for c in range(cols):
        for lane in order:
            here = [n for n in linked if col[n] == c and nodes[n] == lane]
            taken = set()

            def want(n):
                rows = [row[p] for p in pred[n] if nodes[p] == lane]
                return sum(rows) / len(rows) if rows else 0

            for n in sorted(here, key=lambda n: (want(n), n)):
                r = min((r for r in range(len(here) + len(taken) + 1) if r not in taken),
                        key=lambda r: (abs(r - want(n)), r))
                row[n] = r
                taken.add(r)
    width = max(cols, ISOLATED_COLS)
    for lane in order:
        first = max((row[n] + 1 for n in row if nodes[n] == lane), default=0)
        for i, n in enumerate(sorted(n for n in nodes if nodes[n] == lane and n not in row)):
            row[n], col[n] = first + i // width, i % width

    # Tracks: per column gap, one per source fanning out and per target fanned into,
    # sharing a track where their vertical spans don't overlap.
    y_of, lane_top, y = {}, {}, top + BAND_HEAD
    for lane in order:
        lane_top[lane] = y
        rows = max(row[n] for n in nodes if nodes[n] == lane) + 1
        for n in nodes:
            if nodes[n] == lane:
                y_of[n] = y + LANE_PAD + row[n] * (H + ROW_GAP) + H / 2
        y += 2 * LANE_PAD + rows * H + (rows - 1) * ROW_GAP + LANE_GAP
    bottom = y - LANE_GAP
    at = {(col[n], y_of[n]) for n in nodes}

    def clear(cy, c1, c2):
        return all((c, cy) not in at for c in range(c1, c2))

    routes, spans = [], {}  # spans: (gap, key) -> [lo, hi]

    def track(gap, key, *ys):
        lo, hi = spans.get((gap, key), (min(ys), max(ys)))
        spans[(gap, key)] = (min(lo, *ys), max(hi, *ys))
        return (gap, key)

    for a in sorted(nodes):
        for b in sorted(succ[a]):
            ca, cb, ya, yb = col[a], col[b], y_of[a], y_of[b]
            if ya == yb and clear(ya, ca + 1, cb):
                routes.append((a, b, [ya]))
            elif cb == ca + 1 or clear(yb, ca + 1, cb):
                routes.append((a, b, [ya, track(ca, ("out", a), ya, yb), yb]))
            elif clear(ya, ca + 1, cb):
                routes.append((a, b, [ya, track(cb - 1, ("in", b), ya, yb), yb]))
            else:  # through the row gap above b
                cy = yb - H / 2 - ROW_GAP / 2
                routes.append((a, b, [ya, track(ca, ("out", a), ya, cy), cy, track(cb - 1, ("in", b), cy, yb), yb]))
    # Out-tracks left of in-tracks, so a stub leaving a node never runs along one entering the next.
    slot, used = {}, {}
    for (gap, key), (lo, hi) in sorted(spans.items(), key=lambda kv: (kv[0][0], kv[1])):
        ends = used.setdefault((gap, key[0]), [])
        free = next((i for i, end in enumerate(ends) if end < lo - 8), len(ends))
        ends[free:free + 1] = [hi]
        slot[(gap, key)] = free
    tracks = [(len(used.get((c, "out"), [])), len(used.get((c, "in"), []))) for c in range(width)]
    gaps = [max(GAP_MIN, TRACK * (o + i + 1)) for o, i in tracks]
    x_of = [LABEL_W + LANE_PAD + sum(W + g for g in gaps[:c]) for c in range(width)]
    right = x_of[-1] + W + LANE_PAD

    def track_x(t):
        gap, (side, _) = t
        n = sum(tracks[gap])
        k = slot[t] + (tracks[gap][0] if side == "in" else 0)
        return x_of[gap] + W + (k + 1) * gaps[gap] / (n + 1)

    # Band: background, title; lanes: background, label cell.
    add("rectangle", x=-LANE_PAD, y=top, width=right + 2 * LANE_PAD, height=bottom - top + LANE_PAD,
        strokeColor="#adb5bd", backgroundColor="#f8f9fa", strokeWidth=2, roundness={"type": 3})
    text(0, top + 14, title, 28, "#343a40", link)
    for lane in order:
        story = lanes[lane]
        h = (max(y_of[n] for n in nodes if nodes[n] == lane) + H / 2 + LANE_PAD) - lane_top[lane]
        add("rectangle", x=0, y=lane_top[lane], width=right, height=h, strokeColor="#dee2e6",
            backgroundColor="#ffffff", roundness={"type": 3})
        if story:
            stroke, fill = COLORS[story["class"]]
            add("rectangle", x=0, y=lane_top[lane], width=LABEL_W - 12, height=h, strokeColor=stroke,
                backgroundColor=fill, strokeWidth=2, roundness={"type": 3}, link=story["link"])
            t = text(14, lane_top[lane] + 12, wrap(story["text"], 26, 4), 18, link=story["link"])
            if story["id"] in refs:
                badges(14, t["y"] + t["height"] + 8, refs[story["id"]])
        else:
            text(14, lane_top[lane] + 12, "Stories without Tasks", 18, "#868e96")

    for n in nodes:
        item = items[n]
        x, cy = x_of[col[n]], y_of[n]
        box(x, cy - H / 2, W, H, item["class"], wrap(item["text"], 26, 3), item["link"])
        if n in refs:
            badges(x + 2, cy + H / 2 + 6, refs[n])

    # Grey lines first, under the colored ones.
    routes.sort(key=lambda r: (items[r[0]]["class"] != "done", r[0]))
    sources = sorted({a for a, _, _ in routes if items[a]["class"] != "done"})
    for a, b, path in routes:
        xa, xb = x_of[col[a]] + W, x_of[col[b]]
        pts = [(xa, path[0])]
        for i in range(1, len(path), 2):
            tx = track_x(path[i])
            pts += [(tx, path[i - 1]), (tx, path[i + 1])]
        pts.append((xb, path[-1]))
        x0, y0 = pts[0]
        add("arrow", x=x0, y=y0, points=[[px - x0, py - y0] for px, py in pts],
            width=max(p[0] for p in pts) - min(p[0] for p in pts),
            height=max(p[1] for p in pts) - min(p[1] for p in pts),
            strokeColor=LINE_COLORS[sources.index(a) % len(LINE_COLORS)] if a in sources else LINE_DONE,
            strokeWidth=2,
            startBinding=None, endBinding=None, startArrowhead=None, endArrowhead="triangle",
            lastCommittedPoint=None, elbowed=False)
    return bottom + LANE_PAD


items = {i["id"]: i for i in model["stories"] + model["tasks"]}

# Legend
x = 0
text(0, 0, "hitch: my active Features", 36, "#343a40")
for cls, name in LEGEND:
    box(x, 64, 150, 40, cls, name, None)
    x += 170
text(x + 10, 74, "arrow: predecessor → successor;  after/before #id: link outside the band", 16, "#495057")

y = 150
for f in model["features"]:
    stories = [s for s in model["stories"] if s["feature"] == f["id"]]
    y = band(y, f["text"], f["link"], stories, items) + BAND_GAP

json.dump({"type": "excalidraw", "version": 2, "source": "hitch-graph", "elements": elements,
           "appState": {"viewBackgroundColor": "#ffffff", "gridSize": None}, "files": {}}, sys.stdout)
