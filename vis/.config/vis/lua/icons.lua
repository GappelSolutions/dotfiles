-- nvim-web-devicons' glyphs and colours
local M = {}

local by_extension = {
	cs = { '󰌛', '#596706' },
	csproj = { '󰪮', '#512bd4' },
	sln = { '', '#854cc7' },
	slnx = { '', '#854cc7' },
	ts = { '', '#519aba' },
	tsx = { '', '#1354bf' },
	mts = { '', '#519aba' },
	js = { '', '#cbcb41' },
	jsx = { '', '#20c2e3' },
	mjs = { '', '#f1e05a' },
	cjs = { '', '#cbcb41' },
	json = { '', '#cbcb41' },
	html = { '', '#e44d26' },
	css = { '', '#663399' },
	scss = { '', '#f55385' },
	sass = { '', '#f55385' },
	less = { '', '#563d7c' },
	md = { '', '#dddddd' },
	py = { '', '#ffbc03' },
	yaml = { '', '#6d8086' },
	yml = { '', '#6d8086' },
	toml = { '', '#9c4221' },
	ini = { '', '#6d8086' },
	conf = { '', '#6d8086' },
	config = { '', '#6d8086' },
	xml = { '󰗀', '#e37933' },
	svg = { '󰜡', '#ffb13b' },
	png = { '', '#a074c4' },
	jpg = { '', '#a074c4' },
	ico = { '', '#cbcb41' },
	woff2 = { '', '#ececec' },
	ttf = { '', '#ececec' },
	txt = { '󰈙', '#89e051' },
	log = { '󰌱', '#dddddd' },
	ps1 = { '󰨊', '#4273ca' },
	sh = { '', '#4d5a5e' },
	bash = { '', '#89e051' },
	zsh = { '', '#89e051' },
	lock = { '', '#bbbbbb' },
	docx = { '󰈬', '#185abd' },
	pdf = { '', '#b30b00' },
	nix = { '', '#7ebae4' },
	lua = { '', '#51a0cf' },
	rs = { '', '#dea584' },
	go = { '', '#00add8' },
	sql = { '', '#dad8d8' },
	typ = { '', '#0dbcc0' },
	env = { '', '#faf743' },
}
local by_name = {
	['Dockerfile'] = { '󰡨', '#458ee6' },
	['.gitignore'] = { '', '#f54d27' },
	['.editorconfig'] = { '', '#fff2f2' },
	['Makefile'] = { '', '#6d8086' },
	['LICENSE'] = { '', '#cbcb41' },
	['package.json'] = { '', '#e8274b' },
	['.npmrc'] = { '', '#e8274b' },
	['.prettierrc'] = { '', '#4285f4' },
}
-- vis's syntax names
local by_syntax = {
	html = 'html',
	typescript = 'ts',
	javascript = 'js',
	css = 'css',
	sass = 'scss',
	json = 'json',
	csharp = 'cs',
	lua = 'lua',
	markdown = 'md',
	rust = 'rs',
	nix = 'nix',
	yaml = 'yaml',
	bash = 'sh',
}
M.default = { '', '#6d8086' }

function M.path(path)
	local name = path:match('[^/]*$')
	return by_name[name] or by_extension[name:match('%.([^.]+)$') or ''] or M.default
end

function M.syntax(syntax)
	return by_extension[by_syntax[syntax] or ''] or M.default
end

return M
