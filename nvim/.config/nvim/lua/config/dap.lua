local dap = require("dap")

require("mason-nvim-dap").setup()
--
-- dap.adapters.coreclr = {
-- 	type = "executable",
-- 	command = "/Users/cgpp/dev/netcoredbg/netcoredbg",
-- 	args = { "--interpreter=vscode" },
-- }
require("netcoredbg-macOS-arm64").setup(dap)

dap.configurations.cs = {
	{
		type = "coreclr",
		name = "attach - WebApi",
		request = "attach",
		processId = require("dap.utils").pick_process,
	},
}
--
-- dap.adapters.chrome = {
-- 	type = "executable",
-- 	command = "node",
-- 	args = {
-- 		require("mason-registry").get_package("chrome-debug-adapter"):get_install_path() .. "/out/src/chromeDebug.js",
-- 	},
-- }
--
-- dap.configurations.javascript = {
-- 	{
-- 		type = "chrome",
-- 		request = "launch",
-- 		name = "Launch Chrome",
-- 		url = "http://localhost:4200",
-- 		webRoot = "${workspaceFolder}",
-- 		sourceMaps = true,
-- 	},
-- }

dap.configurations.typescript = dap.configurations.javascript

-- debugging UI
local dapui = require("dapui")

dapui.setup({
	icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
	mappings = {
		-- Use a table to apply multiple mappings
		expand = { "<CR>", "<2-LeftMouse>" },
		open = "o",
		remove = "d",
		edit = "e",
		repl = "r",
		toggle = "t",
	},
	element_mappings = {},
	expand_lines = vim.fn.has("nvim-0.7") == 1,
	layouts = {
		{
			elements = {
				{ id = "stacks", size = 0.25 },
				{ id = "breakpoints", size = 0.25 },
				{ id = "scopes", size = 0.5 },
			},
			size = 40,
			position = "right",
		},
		{
			elements = {
				{ id = "repl", size = 1 },
			},
			size = 10,
			position = "bottom",
		},
	},
	floating = {
		max_height = nil,
		max_width = nil,
		border = "single",
		mappings = {
			close = { "q", "<Esc>" },
		},
	},
	windows = { indent = 1 },
	render = {
		max_type_length = nil,
		max_value_lines = 100,
	},
})

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end
