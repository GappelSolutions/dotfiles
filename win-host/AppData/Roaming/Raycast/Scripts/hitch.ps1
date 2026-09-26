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

function Row($name, $kind, $what, $built) {
  $color = if ($built) { $green } else { $dim }
  '  {0}{1,-15}{2} {3}{4,-6}{2} {5}' -f $color, $name, $reset, $dim, $kind, $what
}

"$bold$cyan PLAN$reset"
Row 'hitch-duck'     '/cmd'  'Grills you, challenges one-way doors, slices Stories' $true
Row 'hitch-scout'    'agent' 'Blind code research: path:line facts, no opinions' $true
Row 'hitch-clerk'    'skill' 'Azure: Story = PR, Task = step, Predecessor = batch' $true
''
"$bold$cyan EXECUTE$reset"
Row 'hitch-tower'    '/cmd'  'Runs the crew: batches, reviews, draft PRs, approval' $false
Row 'hitch-bouncer'  'gate'  'Readiness gate: no ACs, no entry; gaps -> duck' $false
Row 'hitch-mechanic' 'agent' 'Implements one Story (= one PR)' $false
Row 'hitch-skeptic'  'agent' 'Review: correctness, failure modes' $false
Row 'hitch-pedant'   'agent' 'Review: conventions, simplicity, bloat' $false
Row 'hitch-referee'  'agent' 'Merges both reviews into the final version' $false
Row 'hitch-janitor'  'agent' 'Cleanup once the Feature is done' $false
''
"  $dim" + 'usage  /hitch-duck <feature-id | story-id | text>' + $reset
"  $dim" + 'ADRs   ~/.hitch/<repo>/adr  (daily backup: P:\backup)' + $reset
"  $green" + 'built' + "$reset  $dim" + 'planned' + $reset
