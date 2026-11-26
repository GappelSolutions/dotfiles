-- PR map flows (hitch-map flow, ../lua/config/prmap.lua). A step row: loop lines, number,
-- +/~/- status, a branch's condition, glyph, the step, · detail, chips, the actor right.
-- Unchanged steps dimmed, removed ones and was rows red, focus points and slice headers bright.
local lexer = lexer
local starts_line, to_eol = lexer.starts_line, lexer.to_eol
local P, S, R = lpeg.P, lpeg.S, lpeg.R

local lex = lexer.new(..., { lex_by_line = true })
-- leading spaces mean something here (an unchanged step): only newlines are whitespace
lex:modify_rule('whitespace', lex:tag(lexer.DEFAULT, S('\r\n') ^ 1))

local star = '\239\128\133' -- nf-fa-star, as hitch-map writes it
local glyphs = P('◇') + '↗' + '■' + '↻' + '→' + '○' + star
local box = P('│') + '├' + '└' + '┌' + '─' + '┼' + '▸'
local head = (P(' ') + box) ^ 0 * (R('09') ^ 1 * ' ') ^ -1 -- loop lines, then the step number
local eol = #S('\r\n') + -P(1)

lex:add_rule('slice', lex:tag(lexer.HEADING, to_eol(starts_line('━━'))))
lex:add_rule('note', lex:tag(lexer.COMMENT, to_eol(starts_line('#'))))
lex:add_rule('focus', lex:tag(lexer.CONSTANT, to_eol(starts_line(P(' ') ^ 1 * star))))
lex:add_rule('gone', lex:tag('deletion', to_eol(starts_line(head * '-'))))
lex:add_rule('context', lex:tag(lexer.COMMENT, to_eol(starts_line(head * '  ' + (P(' ') + box) ^ 1 * -S('+~-0123456789')))))
lex:add_rule('row', lex:tag(lexer.COMMENT, starts_line(head))
	* (lex:tag('addition', P('+')) + lex:tag('change', P('~')))
	* lex:tag(lexer.DEFAULT, P(' ') ^ 1)
	* lex:tag(lexer.TYPE, (1 - glyphs - S('\r\n')) ^ 1) ^ -1)
lex:add_rule('decision', lex:tag(lexer.KEYWORD, P('◇')))
lex:add_rule('out', lex:tag(lexer.STRING, P('↗')))
lex:add_rule('stop', lex:tag(lexer.ERROR, P('■')))
lex:add_rule('jump', lex:tag(lexer.NUMBER, (P('↻') + '→') * ' ' * R('09') ^ 1))
lex:add_rule('star', lex:tag(lexer.CONSTANT, P(star) * lexer.digit ^ 1))
lex:add_rule('who', lex:tag(lexer.COMMENT, P(' ') ^ 3 * (1 - S(' \r\n')) ^ 1 * eol))
lex:add_rule('detail', lex:tag(lexer.COMMENT, '· ' * (1 - glyphs - S('\r\n') - '  ') ^ 1))
lex:add_rule('text', lex:tag(lexer.DEFAULT, (1 - glyphs - S('\r\n') - '·' - '  ') ^ 1))
lex:add_rule('other', lex:tag(lexer.DEFAULT, 1))

return lex
