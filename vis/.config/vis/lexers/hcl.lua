-- HCL (vis has none): OpenBao policies, *.tfvars; opentofu.lua inherits it. Strings and
-- heredocs swallow their ${…}/%{…} templates whole, as in nix.lua.
local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

local dq_str = '"' * P(function(input, index)
	local depth, i = 0, index
	while i <= #input do
		local c, two = input:sub(i, i), input:sub(i, i + 1)
		if depth == 0 and c == '\\' then
			i = i + 2
		elseif two == '${' or two == '%{' then
			depth, i = depth + 1, i + 2
		elseif depth > 0 and c == '}' then
			depth, i = depth - 1, i + 1
		elseif depth == 0 and (c == '"' or c == '\n') then
			return i + 1
		else
			i = i + 1
		end
	end
	return #input + 1
end)
-- <<EOF / <<-EOF (indented end marker) up to the marker alone on its line
local heredoc = '<<' * P(function(input, index)
	local _, e, delimiter = input:find('^%-?([%w_]+)[^\n]*\n', index)
	if not delimiter then
		return nil
	end
	_, e = input:find('\n[ \t]*' .. delimiter .. '%f[^%w_]', e - 1)
	return e and e + 1 or #input + 1
end)
lex:add_rule('string', lex:tag(lexer.STRING, dq_str + heredoc))

lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.to_eol(P('#') + '//') + lexer.range('/*', '*/')))

lex:add_rule('constant', lex:tag(lexer.CONSTANT_BUILTIN, lexer.word_match('true false null')))
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lexer.word_match('for in if')))

local ident = (lexer.alpha + '_') * (lexer.alnum + S('_-')) ^ 0
local space = S(' \t') ^ 0
-- a block's type at the start of its line: `resource "a" "b" {`, `path "x" {`, `lifecycle {`
local block = lexer.starts_line(lex:tag(lexer.KEYWORD, ident), true) * #(space * S('"{') + space * ident * space * S('"{'))
lex:add_rule('block', block)
lex:add_rule('attribute', lex:tag(lexer.VARIABLE, ident) * #(space * '=' * -P('=')))
lex:add_rule('function', lex:tag(lexer.FUNCTION, ident) * #P('('))
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, ident))

lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.float + lexer.integer))
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('=!<>+-*/%&|?:,.{}[]()') + '...'))

lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.OPERATOR, '[', ']')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')

lexer.property['scintillua.comment'] = '#'

return lex
