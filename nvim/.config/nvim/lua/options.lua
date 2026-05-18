vim.opt.shell = vim.env.SHELL or "/bin/sh"
vim.opt.shellcmdflag = "-lc"

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

-- general
vim.opt.clipboard = "unnamedplus"
if vim.env.SSH_TTY ~= nil then
	local function bridge_available()
		return vim.fn.executable("curl") == 1
			and vim.fn.system({ "curl", "-fsS", "--max-time", "0.2", "http://127.0.0.1:19777/health" }) ~= nil
			and vim.v.shell_error == 0
	end

	local function bridge_copy(lines)
		local text = table.concat(lines, "\n")
		if bridge_available() then
			vim.fn.system({ "curl", "-fsS", "-X", "POST", "--data-binary", "@-", "http://127.0.0.1:19777/copy" }, text)
			if vim.v.shell_error == 0 then
				return
			end
		end
		io.stdout:write("\027]52;c;" .. vim.base64.encode(text) .. "\007")
		io.stdout:flush()
	end

	local function bridge_paste()
		if bridge_available() then
			local text = vim.fn.system({ "curl", "-fsS", "--max-time", "1", "http://127.0.0.1:19777/paste" })
			if vim.v.shell_error == 0 then
				return vim.split(text, "\n", { plain = true }), "v"
			end
		end
		return {}
	end

	vim.g.clipboard = {
		name = "dev-clipboard",
		copy = {
			["+"] = bridge_copy,
			["*"] = bridge_copy,
		},
		paste = {
			["+"] = bridge_paste,
			["*"] = bridge_paste,
		},
		cache_enabled = true,
	}
end
vim.opt.backspace = "indent,eol,start"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.wrap = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath("state") .. "/undo"
vim.opt.undofile = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"
vim.opt.whichwrap:append("h,l")
vim.opt.cursorline = true
vim.o.termguicolors = true

vim.cmd([[
augroup Indentation
  autocmd!
  autocmd FileType javascript,typescript,html setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2
  autocmd FileType csharp,json setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4
augroup END
]])
