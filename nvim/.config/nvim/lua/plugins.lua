local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- Cosmetics
	"norcalli/nvim-colorizer.lua",
	"nvim-treesitter/nvim-treesitter-context",
	"nvim-telescope/telescope-ui-select.nvim",
	"rcarriga/nvim-notify",
	"cocopon/iceberg.vim",
	{
		"folke/twilight.nvim",
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
	{
		"mluders/comfy-line-numbers.nvim",
	},
	{
		"eoh-bse/minintro.nvim",
		opts = { color = "#8f84b0" },
		config = true,
		lazy = false,
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = { "MunifTanjim/nui.nvim" },
	},
	{
		"echasnovski/mini.animate",
		config = function()
			require("mini.animate").setup({
				cursor = {
					timing = require("mini.animate").gen_timing.linear({ duration = 200, unit = "total" }),
				},
				scroll = {
					enable = false,
				},
			})
		end,
	},

	-- Text
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" }, -- if you use standalone mini plugins
		opts = {},
	},
	{
		"ggandor/leap.nvim",
		config = function()
			require("leap").create_default_mappings()
		end,
	},
	{
		"ggandor/flit.nvim",
		dependencies = { "ggandor/leap.nvim" },
		config = function()
			require("flit").setup()
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},
	{
		"numToStr/Comment.nvim",
		opts = {},
	},
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup()
		end,
	},

	-- Files
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	{
		"stevearc/oil.nvim",
		opts = {},
		dependencies = { { "echasnovski/mini.icons", opts = {} } },
	},
	{
		"ThePrimeagen/harpoon",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{ "echasnovski/mini.ai" },

	-- Search
	{
		"MagicDuck/grug-far.nvim",
		config = function()
			require("grug-far").setup({})
		end,
	},
	"mg979/vim-visual-multi",
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
	},

	-- Completion
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	"rcarriga/cmp-dap",
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"tailwind-tools",
			"onsails/lspkind-nvim",
			-- ...
		},
		opts = function()
			return {
				-- ...
				formatting = {
					format = require("lspkind").cmp_format({
						before = require("tailwind-tools.cmp").lspkind_format,
					}),
				},
			}
		end,
	},

	-- LSP
	"artemave/workspace-diagnostics.nvim",
	"MunifTanjim/prettier.nvim",
	"neovim/nvim-lspconfig",
	"folke/trouble.nvim",
	"joeveiga/ng.nvim",
	{
		"luckasRanarison/tailwind-tools.nvim",
		name = "tailwind-tools",
		build = ":UpdateRemotePlugins",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {},
	},
	{
		"seblyng/roslyn.nvim",
		ft = { "cs", "razor" },
		dependencies = {
			{
				"tris203/rzls.nvim",
				config = true,
			},
		},
		config = function()
			local rzls_path = vim.fn.expand("$MASON/packages/rzls/libexec")
			local dotnet_ls_path = vim.fn.expand("$MASON/packages/dotnet-language-server/libexec")
			local cmd = {
				"dotnet",
				vim.fs.joinpath(dotnet_ls_path, "DotnetLanguageServer.dll"),
				"--stdio",
				"--logLevel=Information",
				"--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
				"--razorSourceGenerator=" .. vim.fs.joinpath(rzls_path, "Microsoft.CodeAnalysis.Razor.Compiler.dll"),
				"--razorDesignTimePath="
					.. vim.fs.joinpath(rzls_path, "Targets", "Microsoft.NET.Sdk.Razor.DesignTime.targets"),
				"--extension",
				vim.fs.joinpath(rzls_path, "RazorExtension", "Microsoft.VisualStudioCode.RazorExtension.dll"),
			}

			require("roslyn").setup({
				cmd = cmd,
				config = {
					handlers = require("rzls.roslyn_handlers"),
					settings = {
						["csharp|inlay_hints"] = {
							csharp_enable_inlay_hints_for_implicit_object_creation = true,
							csharp_enable_inlay_hints_for_implicit_variable_types = true,
							csharp_enable_inlay_hints_for_lambda_parameter_types = true,
							csharp_enable_inlay_hints_for_types = true,
							dotnet_enable_inlay_hints_for_indexer_parameters = true,
							dotnet_enable_inlay_hints_for_literal_parameters = true,
							dotnet_enable_inlay_hints_for_object_creation_parameters = true,
							dotnet_enable_inlay_hints_for_other_parameters = true,
							dotnet_enable_inlay_hints_for_parameters = true,
							dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
							dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
							dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
						},
						["csharp|code_lens"] = {
							dotnet_enable_references_code_lens = true,
						},
					},
				},
			})
		end,
		init = function()
			vim.filetype.add({
				extension = {
					razor = "razor",
					cshtml = "razor",
				},
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
	},
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
	},
	{
		"windwp/nvim-ts-autotag",
		dependencies = "nvim-treesitter/nvim-treesitter",
	},
	{
		"mfussenegger/nvim-dap",
		lazy = true,
		dependencies = {
			"jay-babu/mason-nvim-dap.nvim",
			"rcarriga/nvim-dap-ui",
		},
	},
	{
		"nvimtools/none-ls.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
	},

	-- DAP
	{
		"rcarriga/nvim-dap-ui",
		lazy = true,
		dependencies = { "nvim-neotest/nvim-nio" },
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		lazy = true,
	},
	{
		"Cliffback/netcoredbg-macOS-arm64.nvim",
		dependencies = { "mfussenegger/nvim-dap" },
	},

	-- Git
	"lewis6991/gitsigns.nvim",
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "kyazdani42/nvim-web-devicons" },
	},
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>G", DeleteLockFileAndOpenLazyGit, desc = "Open lazy git" },
		},
	},

	-- Others
	"mbbill/undotree",
	-- "github/copilot.vim",
	{
		"coffebar/neovim-project",
		opts = {
			projects = {
				"/Users/cgpp/dev/*",
				"/Users/cgpp/dev/gappel-cloud/src/backend/GappelCloud",
				"/Users/cgpp/dev/gappel-cloud/src/frontend",
			},
			picker = {
				type = "telescope",
			},
		},
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-telescope/telescope.nvim", tag = "0.1.4" },
			{ "Shatur/neovim-session-manager" },
		},
		lazy = false,
		priority = 100,
	},
	{
		"smartpde/telescope-recent-files",
		dependencies = { "nvim-telescope/telescope.nvim" },
	},
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
			"DBUIFindBuffer",
		},
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_win_position = "right"
			vim.g.db_ui_winwidth = RightScreenSpace
		end,
	},
	-- {
	-- 	"yetone/avante.nvim",
	-- 	dependencies = {
	-- 		"nvim-tree/nvim-web-devicons",
	-- 		"stevearc/dressing.nvim",
	-- 		"nvim-lua/plenary.nvim",
	-- 		"MunifTanjim/nui.nvim",
	-- 		{
	-- 			"MeanderingProgrammer/render-markdown.nvim",
	-- 			opts = { file_types = { "markdown", "Avante" } },
	-- 			ft = { "markdown", "Avante" },
	-- 		},
	-- 	},
	-- 	build = "make",
	-- 	opts = { provider = "copilot" },
	-- },
})
