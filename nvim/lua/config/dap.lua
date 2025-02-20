local dap = require("dap")

require("mason-nvim-dap").setup({
	ensure_installed = { "coreclr", "node2", "js", "chrome" },
})

dap.adapters.coreclr = {
	type = "executable",
	command = "C:\\Users\\aiche\\netcoredbg\\netcoredbg.exe",
	args = { "--interpreter=vscode" },
}

dap.configurations.cs = {
	{
		type = "coreclr",
		name = "launch - WebApi",
		request = "launch",
		program = "C:/dev/CustomerPortal.WebAPI/Repower.CustomerPortal.WebAPI/bin/Debug/net8.0/Repower.CustomerPortal.WebAPI.dll",
		cwd = "C:/dev/CustomerPortal.WebAPI/Repower.CustomerPortal.WebAPI",
		console = "integratedTerminal",
		env = {
			ASPNETCORE_ENVIRONMENT = "christiangappel",
			ASPNETCORE_URLS = "http://localhost:44356",
		},
		args = { "--launch-profile", "Christian Gappel" },
		serverReadyAction = {
			action = "openExternally",
			pattern = "Now listening on:\\s+(https?://\\S+)",
			uriFormat = "%s",
		},
		ports = { 44356 },
	},
}

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
			size = RightScreenSpace,
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
