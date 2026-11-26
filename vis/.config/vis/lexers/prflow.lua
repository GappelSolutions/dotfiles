-- PR map flows (hitch-map flow, ../lua/config/prmap.lua): a +/~/- gutter per step, the
-- tree dimmed, unchanged steps dimmed, gone ones red, focus points and slice headers bright.
local lexer = lexer
local starts_line, to_eol = lexer.starts_line, lexer.to_eol
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(..., { lex_by_line = true })
-- leading spaces mean something here (an unchanged step): only newlines are whitespace
lex:modify_rule('whitespace', lex:tag(lexer.DEFAULT, S('\r\n') ^ 1))

local tree = P('├') + '└' + '│'
local star = '\239\128\133' -- nf-fa-star, as hitch-map writes it
local glyphs = P('◇') + '⇢' + '■' + '↻' + '→' + '○' + star

lex:add_rule('slice', lex:tag(lexer.HEADING, to_eol(starts_line('━━'))))
lex:add_rule('note', lex:tag(lexer.COMMENT, to_eol(starts_line('#'))))
lex:add_rule('focus', lex:tag(lexer.CONSTANT, to_eol(starts_line(P(' ') ^ 1 * star))))
lex:add_rule('gone', lex:tag('deletion', to_eol(starts_line('-'))))
lex:add_rule('context', lex:tag(lexer.COMMENT, to_eol(starts_line('    '))))
lex:add_rule('new', lex:tag('addition', starts_line('+')))
lex:add_rule('changed', lex:tag('change', starts_line('~')))
lex:add_rule('tree', lex:tag(lexer.COMMENT, tree ^ 1))
lex:add_rule('decision', lex:tag(lexer.KEYWORD, P('◇')))
lex:add_rule('out', lex:tag(lexer.STRING, P('⇢')))
lex:add_rule('stop', lex:tag(lexer.ERROR, P('■')))
lex:add_rule('loop', lex:tag(lexer.NUMBER, P('↻') + '→'))
lex:add_rule('star', lex:tag(lexer.CONSTANT, P(star) * lexer.digit ^ 1))
lex:add_rule('text', lex:tag(lexer.DEFAULT, (1 - (tree + glyphs + '\n')) ^ 1))
lex:add_rule('other', lex:tag(lexer.DEFAULT, 1))

return lex
