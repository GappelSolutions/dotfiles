local colors = {
	bg = "#161821",
	fg = "#c6c8d1",
	blue = "#84a0c6",
	cyan = "#89b8c2",
	green = "#b4be82",
	orange = "#e2a478",
	magenta = "#a093c7",
	red = "#e27878",
	gray = "#6b7089",
	filebg = "#1e2132",
	gitbg = "#3a4059",
	branchbg = "#c6c8d1",
}

local iceberg_lualine = {
	normal = {
		a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
		b = { bg = colors.gitbg, fg = colors.fg },
		c = { bg = colors.filebg, fg = colors.fg },
		x = { bg = colors.gitbg, fg = colors.fg },
		y = { bg = colors.branchbg, fg = colors.bg },
		z = { bg = colors.branchbg, fg = colors.bg },
	},
	insert = {
		a = { bg = colors.cyan, fg = colors.bg, gui = "bold" },
		b = { bg = colors.gitbg, fg = colors.fg },
		c = { bg = colors.filebg, fg = colors.fg },
		x = { bg = colors.gitbg, fg = colors.fg },
		y = { bg = colors.branchbg, fg = colors.bg },
		z = { bg = colors.branchbg, fg = colors.bg },
	},
	visual = {
		a = { bg = colors.magenta, fg = colors.bg, gui = "bold" },
		b = { bg = colors.gitbg, fg = colors.fg },
		c = { bg = colors.filebg, fg = colors.fg },
		x = { bg = colors.gitbg, fg = colors.fg },
		y = { bg = colors.branchbg, fg = colors.bg },
		z = { bg = colors.branchbg, fg = colors.bg },
	},
	replace = {
		a = { bg = colors.red, fg = colors.bg, gui = "bold" },
		b = { bg = colors.gitbg, fg = colors.fg },
		c = { bg = colors.filebg, fg = colors.fg },
		x = { bg = colors.gitbg, fg = colors.fg },
		y = { bg = colors.branchbg, fg = colors.bg },
		z = { bg = colors.branchbg, fg = colors.bg },
	},
	command = {
		a = { bg = colors.orange, fg = colors.bg, gui = "bold" },
		b = { bg = colors.gitbg, fg = colors.fg },
		c = { bg = colors.filebg, fg = colors.fg },
		x = { bg = colors.gitbg, fg = colors.fg },
		y = { bg = colors.branchbg, fg = colors.bg },
		z = { bg = colors.branchbg, fg = colors.bg },
	},
	inactive = {
		a = { bg = colors.bg, fg = colors.gray },
		b = { bg = colors.bg, fg = colors.gray },
		c = { bg = colors.bg, fg = colors.gray },
		x = { bg = colors.bg, fg = colors.gray },
		y = { bg = colors.bg, fg = colors.gray },
		z = { bg = colors.bg, fg = colors.gray },
	},
}

require("lualine").setup({
	options = {
		icons_enabled = true,
		theme = iceberg_lualine,
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		globalstatus = true,
	},
	sections = {
		lualine_a = { { "mode", icon = "" } },
		lualine_b = {
			{
				"branch",
				icon = "",
				color = { bg = colors.branchbg, fg = colors.bg },
				separator = { right = "" },
			},
			{ "diff" },
			"diagnostics",
		},
		lualine_c = {
			{
				"filename",
				path = 1,
				symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" },
			},
		},
		lualine_x = {

			{
				"encoding",
				fmt = function(str)
					return str .. "  ✦"
				end,
				separator = { left = "" },
			},
			{
				"fileformat",
				fmt = function(str)
					return str .. "  ✦"
				end,
			},
			{
				"filetype",
				separator = { left = "" },
				icon_only = true,
			},
		},
		lualine_y = {
			{
				"progress",
				separator = { left = "" },
				color = { bg = colors.branchbg, fg = colors.bg },
			},
		},
		lualine_z = {
			{
				"location",
				separator = { left = "" },
				color = { bg = colors.branchbg, fg = colors.bg },
			},
		},
	},
	inactive_sections = {
		lualine_c = { "filename" },
		lualine_x = { "location" },
	},
	extensions = { "nvim-tree", "fugitive" },
})
