vim.cmd("colorscheme iceberg")
vim.o.background = "dark"
vim.cmd([[
    highlight NormalFloat guibg=none guifg=white
    highlight Normal guibg=none
]])

vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#282C34", fg = "NONE" })
vim.api.nvim_set_hl(0, "Pmenu", { fg = "#C5CDD9", bg = "#22252A" })
vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "#2E323A" })
vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "#4E5259" })
vim.api.nvim_set_hl(0, "CmpItemAbbr", { fg = "#C5CDD9" })
vim.api.nvim_set_hl(0, "CmpItemAbbrDeprecated", { fg = "#7E8294", strikethrough = true })
vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg = "#82AAFF", bold = true })
vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { fg = "#82AAFF", bold = true })
vim.api.nvim_set_hl(0, "CmpItemKind", { fg = "#C792EA" })
vim.api.nvim_set_hl(0, "CmpItemMenu", { fg = "#C792EA" })
