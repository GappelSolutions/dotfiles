# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Hitch Crew
# @raycast.mode fullOutput
# @raycast.packageName Hitch

# Optional parameters:
# @raycast.platform windows
# @raycast.icon 🦆
# @raycast.description Names and roles of the hitch-* skills and agents

# Keep ASCII only: Windows PowerShell 5.1 misreads BOM-less UTF-8 (the icon
# line above is a comment and only read by Raycast).
$e = [char]27
$bold = "$e[1m"; $cyan = "$e[36m"; $green = "$e[32m"; $dim = "$e[90m"; $reset = "$e[0m"

function Row($name, $kind, $what) {
  '  {0}{1,-15}{2} {3}{4,-6}{2} {5}' -f $green, $name, $reset, $dim, $kind, $what
}

"$bold$cyan PLAN$reset"
Row 'hitch-duck'     '/cmd'  'Grills a Story, challenges one-way doors, slices Tasks'
Row 'hitch-scout'    'agent' 'Blind code research: path:line facts, no opinions'
Row 'hitch-clerk'    '/cmd'  'Azure conventions; publishes your own branch as a PR'
''
"$bold$cyan EXECUTE$reset"
Row 'hitch-tower'    '/cmd'  'Runs the crew: batches, draft PRs, merge, next'
Row 'hitch-bouncer'  'agent' 'Readiness gate + Task brief; gaps -> duck'
Row 'hitch-mechanic' 'agent' 'Builds one Task in its worktree, dev, annotations'
Row 'hitch-skeptic'  'agent' 'Full review incl. comment slop; 2 run blind'
Row 'hitch-referee'  'agent' '3rd review on top of both: the final fix list'
Row 'hitch-janitor'  'agent' 'Story done: worktrees, branches, leftovers'
''
"$bold$cyan REVIEW + CHECK$reset"
Row 'hitch-jury'     '/cmd'  "Review a colleague's PR: 2 skeptics + referee"
Row 'hitch-inspector' '/cmd' 'Weekly scorecard: loops, slow, corrections, PRs'
''
"  $dim" + 'plan   /hitch-duck <story-id | task-id | feature-id | text>' + $reset
"  $dim" + 'run    /hitch-tower <story-id | task-id>' + $reset
"  $dim" + 'pr     /hitch-clerk [task-id] [branch]   again after a push: sync' + $reset
"  $dim" + 'review /hitch-jury [pr-id]   no id: PRs waiting on you' + $reset
"  $dim" + 'check  /hitch-inspector [since]   mark live: #flag <note>' + $reset
"  $dim" + 'merge  approval (10) by someone else + every comment fixed/wontFix' + $reset
"  $dim" + 'after  pipeline deploys, smoke test on shared dev, then close' + $reset
"  $dim" + 'ADRs   ~/.hitch/<repo>/adr  (daily backup: P:\backup)' + $reset
