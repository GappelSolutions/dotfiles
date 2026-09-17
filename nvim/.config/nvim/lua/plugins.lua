local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- Cosmetics
	"cocopon/iceberg.vim",
	"norcalli/nvim-colorizer.lua",
	"nvim-treesitter/nvim-treesitter-context",
	"nvim-telescope/telescope-ui-select.nvim",
	"rcarriga/nvim-notify",
	{
		"folke/twilight.nvim",
		opts = {},
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
		"sphamba/smear-cursor.nvim",
		opts = {},
	},

	-- Text
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
		opts = {
			anti_conceal = {
				above = 3,
				below = 3,
			},
		},
	},
	{
		"ggandor/leap.nvim",
		config = function()
			require("leap").create_default_mappings()
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},
	{
		"windwp/nvim-ts-autotag",
		dependencies = "nvim-treesitter/nvim-treesitter",
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
	"mg979/vim-visual-multi",
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
	{
		"MagicDuck/grug-far.nvim",
		config = function()
			-- grug-far only strips the trailing \r on Windows, so on a WSL/Linux
			-- checkout of a CRLF repo every synced line is written back as
			-- "...\r\r\n". That stray CR kills git's eol normalization and turns a
			-- 1-line change into a whole-file diff. Strip it on every platform.
			local grug_utils = require("grug-far.utils")
			grug_utils.getLineWithoutCarriageReturn = function(line)
				if type(line) == "string" and line:sub(-1) == "\r" then
					return line:sub(1, -2)
				end
				return line
			end

			require("grug-far").setup({
				openTargetWindow = { preferredLocation = "right" },
			})
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{
		"smartpde/telescope-recent-files",
		dependencies = { "nvim-telescope/telescope.nvim" },
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
		},
		opts = function()
			return {
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
		"nvim-neotest/neotest",
		dependencies = {
			"marilari88/neotest-vitest",
		},
		opts = {
			adapters = {
				["neotest-vitest"] = {},
			},
		},
	},
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
			local rzls_path = vim.fn.expand("$MASON/packages/roslyn/libexec")
			local cmd = {
				"roslyn",
				"--stdio",
				"--logLevel=Information",
				"--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
				"--extension",
				vim.fs.joinpath(rzls_path, "Microsoft.VisualStudioCode.RazorExtension.dll"),
			}

			-- nvim 0.12 moved diagnostic refresh from vim.lsp.util._refresh to vim.lsp.diagnostic._refresh;
			-- roslyn.nvim's stock handler still calls the old path and errors, so override it here.
			local handlers = vim.tbl_deep_extend("force", require("rzls.roslyn_handlers"), {
				["workspace/projectInitializationComplete"] = function(_, _, ctx)
					vim.notify("Roslyn project initialization complete", vim.log.levels.INFO, { title = "roslyn.nvim" })
					vim.api.nvim_exec_autocmds("User", { pattern = "RoslynInitialized", modeline = false })
					_G.roslyn_initialized = true
					for _, buf in ipairs(vim.lsp.get_buffers_by_client_id(ctx.client_id)) do
						vim.lsp.diagnostic._refresh(buf)
					end
				end,
			})

			vim.lsp.config("roslyn", {
				cmd = cmd,
				handlers = handlers,
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
			})

			require("roslyn").setup({
				-- Solution filters (.slnf) shouldn't count as separate targets; always
				-- resolve to the real .slnx/.sln and remember that choice per project
				-- so `:Roslyn target` doesn't get asked again on every window.
				ignore_target = function(target)
					return target:match("%.slnf$") ~= nil
				end,
				lock_target = true,
			})
			vim.lsp.enable("roslyn")
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
		"GustavEikaas/easy-dotnet.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
		config = function()
			require("easy-dotnet").setup({
				-- easy-dotnet ships its own bundled Roslyn LSP client ("easy_dotnet") that
				-- runs *alongside* seblyng/roslyn.nvim's "roslyn" client above, and defaults
				-- to on. Two Roslyn servers attached to the same C# buffers double up
				-- codelens/references rendering (the stacked "0 references" lines) and
				-- double the target-resolution churn. roslyn.nvim already owns the LSP here.
				lsp = { enabled = false },
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
		lazy = false,
		build = ":TSUpdate",
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
		cond = function()
			return vim.uv.os_uname().sysname == "Darwin"
		end,
		dependencies = { "mfussenegger/nvim-dap" },
	},

	-- Git
	"lewis6991/gitsigns.nvim",
	"sindrets/diffview.nvim",
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
	},

	-- Others
	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		opts = {
			branch = false,
		},
	},
})
