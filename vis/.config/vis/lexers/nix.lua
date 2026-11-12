-- Nix (vis has no nix lexer). Strings swallow their ${…} interpolations whole: an LPeg rule
-- can't resume a string after the code inside one.
local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(...)

-- Scanners return the index after what they consume, nested strings and ${…} included.
local dq, indented
-- code inside ${…}, up to its closing }
local function interpolation(input, i)
	local depth = 0
	while i <= #input do
		local c = input:sub(i, i)
		if c == '"' then
			i = dq(input, i + 1)
		elseif input:sub(i, i + 1) == "''" then
			i = indented(input, i + 2)
		elseif c == '#' then
			i = (input:find('\n', i, true) or #input) + 1
		elseif c == '{' then
			depth, i = depth + 1, i + 1
		elseif c == '}' then
			if depth == 0 then
				return i + 1
			end
			depth, i = depth - 1, i + 1
		else
			i = i + 1
		end
	end
	return i
end
function dq(input, i)
	while i <= #input do
		local c = input:sub(i, i)
		if c == '\\' then
			i = i + 2
		elseif input:sub(i, i + 1) == '${' then
			i = interpolation(input, i + 2)
		elseif c == '"' then
			return i + 1
		else
			i = i + 1
		end
	end
	return i
end
-- '' escapes: ''$ ''' ''\x
function indented(input, i)
	while i <= #input do
		if input:sub(i, i + 1) == "''" then
			local next = input:sub(i + 2, i + 2)
			if next == '$' or next == "'" then
				i = i + 3
			elseif next == '\\' then
				i = i + 4
			else
				return i + 2
			end
		elseif input:sub(i, i + 1) == '${' then
			i = interpolation(input, i + 2)
		else
			i = i + 1
		end
	end
	return i
end
-- Shell in '' strings, by context like nvim-treesitter's nix injections: /* bash */ '', shell
-- attributes (script, *Phase, preStart, shellHook, …), text of writeShellApplication and
-- activationScripts, writeShellScript(Bin) "n" '', writeText "x.sh" '', runCommand "n" {…} ''.
local shell_attrs = {
	script = true, shellHook = true, buildCommand = true, extraCommands = true, extraSetup = true,
	preStart = true, postStart = true, preStop = true, postStop = true, reload = true,
}
-- position of the { enclosing pos, or nil
local function open_brace(input, pos)
	local depth = 0
	for i = pos, math.max(1, pos - 8000), -1 do
		local c = input:sub(i, i)
		if c == '}' then
			depth = depth + 1
		elseif c == '{' then
			if depth == 0 then
				return i
			end
			depth = depth - 1
		end
	end
end
local function is_shell(input, index)
	-- last character before the '' (and an opening paren)
	local last = index - 1
	while last > 0 and input:sub(last, last):find('[%s(]') do
		last = last - 1
	end
	local before = input:sub(math.max(1, last - 400), last)
	if before:find('/%*%s*b?a?sh%s*%*/$') then
		return true
	end
	local line = before:match('[^\n]*$')
	local attr = line:match("([%w_'-]+)%s*=$")
	if attr then
		if shell_attrs[attr] or attr:find('Phase$') or attr:find('^pre%u') or attr:find('^post%u') then
			return true
		end
		local brace = attr == 'text' and open_brace(input, last)
		local owner = brace and input:sub(math.max(1, brace - 200), brace - 1):gsub('%s*$', '')
		return owner and (owner:find('writeShellApplication$') or owner:find('activationScripts[%w_.%-"]*%s*=$')) and true
	end
	if line:find('writeShellScript%w*%s+%S+$') or line:find('writeText%s+"[^"]*%.sh"$') then
		return true
	end
	-- runCommand "n" { … } '': the attrset may span lines
	local brace = before:sub(-1) == '}' and open_brace(input, last - 1)
	local owner = brace and input:sub(math.max(1, brace - 200), brace - 1):match('[^\n]*$')
	return owner and owner:find('runCommand%w*%s+%S+%s*$') and true
end
local bash = lexer.load('bash')
-- rules the bash lexer tries first: Nix's ${…} (not ''${, which is bash's) and '' escapes
local function prepend(id, rule)
	bash:add_rule(id, rule)
	table.insert(bash._rules, 1, table.remove(bash._rules))
end
prepend('nix_escape', bash:tag(lexer.OPERATOR, "''" * (#P('$') + "'" + '\\' * P(1))))
prepend('nix_interpolation', bash:tag(lexer.EMBEDDED, -B("''") * '${' * P(function(input, index)
	return interpolation(input, index)
end)))
lex:embed(bash, lex:tag(lexer.STRING, "''" * P(function(input, index)
	return is_shell(input, index - 2) and index
end)), lex:tag(lexer.STRING, "''" * -S("$'\\")))

lex:add_rule('string', lex:tag(lexer.STRING, '"' * P(dq) + "''" * P(indented)))

lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.to_eol('#') + lexer.range('/*', '*/')))

-- identifiers may hold - and ' (import', foo-bar): not keywords
local function words(list)
	return lexer.word_match(list) * -S("-'")
end
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, words('let in with rec inherit if then else assert or')))
lex:add_rule('constant', lex:tag(lexer.CONSTANT_BUILTIN, words('true false null')))
lex:add_rule('builtin', lex:tag(lexer.FUNCTION_BUILTIN, words(
	'builtins import throw abort map toString derivation baseNameOf dirOf isNull removeAttrs'
)))

-- paths and URLs before identifiers and operators: ./x, ../x, ~/x, /x, <nixpkgs>, https://…
-- (`a // b` is the update operator, not a path)
local path_char = lexer.alnum + S('._-+/')
local path = (P('.') * P('.') ^ -1 + '~') * '/' * path_char ^ 1
	+ B(S(' \t\n([=:')) * '/' * (path_char - '/') * path_char ^ 0
local search_path = '<' * (lexer.alnum + S('._-/')) ^ 1 * '>'
local url = lexer.alpha * (lexer.alnum + S('+-.')) ^ 0 * ':' * (lexer.alnum + S("%/?:@&=+$,-_.!~*'")) ^ 1
lex:add_rule('path', lex:tag(lexer.LINK, path + search_path + url))

-- attribute names on the left of = (a.b.c = …)
local ident = (lexer.alpha + '_') * (lexer.alnum + S("_-'")) ^ 0
local attr = ident * ('.' * ident) ^ 0
lex:add_rule('attribute', lex:tag(lexer.VARIABLE, attr) * #(S(' \t') ^ 0 * '=' * -P('=')))
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, ident))

lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.float + lexer.integer))
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('=!<>+-*/&|?:;,.@{}[]()$')))

lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.OPERATOR, '[', ']')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')

lexer.property['scintillua.comment'] = '#'

return lex
