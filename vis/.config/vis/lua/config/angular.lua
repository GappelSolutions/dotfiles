-- Angular templates, coloured like nvim's angular tree-sitter parser: the html lexer only
-- knows `name=` attributes, so bindings, bare attributes and @if/@for stay plain
local function angular(html)
	local lexers, P, S = vis.lexers, vis.lpeg.P, vis.lpeg.S
	local space = lexers.space ^ 0
	local name = P('[') ^ -1 * P('(') ^ -1 * S('*#@') ^ -1 * (lexers.alnum + S('-_.:@$')) ^ 1
		* P(')') ^ -1 * P(']') ^ -1
	local link = P(false)
	for _, q in ipairs({ '"', "'" }) do
		link = link + html:tag(lexers.STRING, q) * html:tag(lexers.LINK, (1 - P(q)) ^ 1) ^ -1
			* html:tag(lexers.STRING, q)
	end
	local value = html:tag(lexers.STRING, lexers.range('"', false, false) + lexers.range("'", false, false)
		+ (1 - S(' \t\r\n"\'=<>`')) ^ 1)
	-- style= stays with the html lexer, which embeds css in its value
	local attribute = -(P('style') * space * '=') * (
		html:tag(lexers.ATTRIBUTE, (P('src') + 'href') * space * '=') * space * link
		+ html:tag(lexers.ATTRIBUTE, name * space * '=') * space * value
		+ html:tag(lexers.ATTRIBUTE, name))
	html:modify_rule('tag', html:get_rule('tag') * (html:get_rule('whitespace') * attribute) ^ 0)
	-- attributes after a style= one, which ends the tag rule
	html:modify_rule('attribute', html:tag(lexers.ATTRIBUTE, name * space * '='))
	html:add_rule('control_flow', html:tag(lexers.KEYWORD, '@' * lexers.word_match(
		'if else for empty switch case default defer placeholder loading error let')))
end

local load_lexer = vis.lexers.load
vis.lexers.load = function(name, alt_name, cache)
	local lexer = load_lexer(name, alt_name, cache)
	if name == 'html' and lexer and not lexer._angular then
		lexer._angular = true
		angular(lexer)
	end
	return lexer
end
