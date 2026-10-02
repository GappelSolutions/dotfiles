-- Community plugins that need no setup (pinned in nix/modules/shared/home-vis.nix); the rest
-- are set up in lua/config
require('plugins/vis-editorconfig-options')
require('plugins/vis-pairs')
-- nvim-surround's keys: visual S, but D and C stay vim's linewise delete and change
local surround = require('plugins/vis-surround')
surround.prefix.change[2], surround.prefix.delete[2] = nil, nil
require('plugins/vis-commentary')
require('plugins/vis-sneak')
