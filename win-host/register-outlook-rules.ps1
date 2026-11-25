# Applies the Azure DevOps mail rules and folders to the classic Outlook mailbox. Outlook keeps
# rules and retention tags on the Exchange server, not in a file, so sync.sh has nothing to copy:
# this script is the source of truth instead. Re-running replaces the managed rules with the
# definitions below and leaves every other rule alone.
#
#   Azure DevOps Noise     succeeded / partially succeeded / canceled builds and your own PR
#                          completions -> Azure
#   Azure DevOps Fail      failed builds -> Azure - CI Fail
#   Azure DevOps Mentions  your name or a team you're in, minus the review bot -> Azure - Mention
#   Azure DevOps           everything else from Azure DevOps -> Azure
#
# Every rule stops processing, so a mail lands in exactly one folder. The Azure folder gets the
# mailbox's "1 Week Delete" retention tag (Exchange deletes in the background, not instantly).
# Needs classic Outlook (new Outlook has no COM); it attaches to the running instance.
#
#   pwsh -NoProfile -ExecutionPolicy Bypass -File win-host\register-outlook-rules.ps1
$ErrorActionPreference = 'Stop'

$sender    = 'azuredevops@microsoft.com'
$retention = '1 Week Delete'
$legacy    = @('Azure DevOps Succes')   # names this script used to own; deleted on sight

$ol = New-Object -ComObject Outlook.Application
$ns = $ol.Session
$store = $ns.DefaultStore
$root = $store.GetRootFolder()
$me = $ns.CurrentUser.Name
if (-not $me) { throw 'cannot read the Outlook profile user name' }

function Get-MailFolder($name) {
  $f = $root.Folders | Where-Object Name -eq $name
  if (-not $f) { $f = $root.Folders.Add($name); "created folder $name" | Out-Host }
  # rule actions only take a folder fetched by id, not one from the Folders collection
  $ns.GetFolderFromID($f.EntryID, $store.StoreID)
}

# Order matters: noise before mentions, since build mails name whoever queued them.
$managed = @(
  @{ Name = 'Azure DevOps Noise'; Folder = 'Azure'
     Text = @('[PR build succeeded]', '[Build succeeded]',
              '[PR build partially succeeded]', '[Build partially succeeded]',
              '[PR build canceled]', '[Build canceled]',
              "$me completed the pull request") }
  @{ Name = 'Azure DevOps Fail'; Folder = 'Azure - CI Fail'
     Text = @('[PR build failed]', '[Build failed]') }
  @{ Name = 'Azure DevOps Mentions'; Folder = 'Azure - Mention'
     Text = @($me, 'Ensor Developers'); Except = @('Hitch-Review-Bot') }
  @{ Name = 'Azure DevOps'; Folder = 'Azure' }
)

$rules = $store.GetRules()
$owned = $legacy + ($managed | ForEach-Object Name)
for ($i = $rules.Count; $i -ge 1; $i--) {
  if ($owned -contains $rules.Item($i).Name) { $rules.Remove($i) }
}

# Create() inserts at the top, so go backwards to end up with the managed rules first, in the
# order listed above.
foreach ($m in $managed[($managed.Count - 1)..0]) {
  $r = $rules.Create($m.Name, 0)   # olRuleReceive
  $from = $r.Conditions.From
  $from.Enabled = $true
  $null = $from.Recipients.Add($sender)
  if (-not $from.Recipients.ResolveAll()) { throw "cannot resolve $sender" }
  if ($m.Text) { $r.Conditions.BodyOrSubject.Enabled = $true; $r.Conditions.BodyOrSubject.Text = $m.Text }
  if ($m.Except) { $r.Exceptions.BodyOrSubject.Enabled = $true; $r.Exceptions.BodyOrSubject.Text = $m.Except }
  $move = $r.Actions.MoveToFolder
  $move.Enabled = $true
  # a plain assignment throws "The operation failed" from pwsh; the late-bound setter works
  [System.__ComObject].InvokeMember('Folder', [Reflection.BindingFlags]::SetProperty, $null, $move,
    @(Get-MailFolder $m.Folder))
  $r.Actions.Stop.Enabled = $true
}
$rules.Save($true)

# Retention tags come from the mailbox's policy; look the tag's id up by name.
$mrm = $ns.GetDefaultFolder(6).GetStorage('IPM.Configuration.MRM', 2)   # Inbox, by message class
$xml = [xml][Text.Encoding]::UTF8.GetString(
  $mrm.PropertyAccessor.GetProperty('http://schemas.microsoft.com/mapi/proptag/0x7C080102'))
$tag = $xml.UserConfiguration.Info.Data.PolicyTag | Where-Object Name -eq $retention
if (-not $tag) { throw "retention tag '$retention' is not in this mailbox's policy" }
$prop = 'http://schemas.microsoft.com/mapi/proptag/'
# PR_POLICY_TAG, PR_RETENTION_PERIOD (days), PR_RETENTION_FLAGS (explicit | personal | needs rescan)
(Get-MailFolder 'Azure').PropertyAccessor.SetProperties(
  @("${prop}0x30190102", "${prop}0x301A0003", "${prop}0x301D0003"),
  @([byte[]]([guid]$tag.Guid).ToByteArray(), [int]$tag.ContentSettings.ExpiryAgeLimit, 137))

foreach ($r in $store.GetRules()) {
  if ($owned -notcontains $r.Name) { continue }
  '[{0}] {1} -> {2}' -f $r.ExecutionOrder, $r.Name, $r.Actions.MoveToFolder.Folder.Name
}
"Azure folder retention: $retention"
