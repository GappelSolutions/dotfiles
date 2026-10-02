-- Rainbow CSV/TSV (vis has no csv lexer): each column in the next of six colours. The separator
-- is per line: tab if the line has one, else ';' (Excel's where ',' is the decimal mark), else ','.
local lexer = require('lexer')
local token = lexer.token
local P, S = lpeg.P, lpeg.S

local lex = lexer.new('csv')

local colours = { lexer.KEYWORD, lexer.STRING, lexer.LABEL, lexer.HEADING, lexer.CONSTANT, lexer.IDENTIFIER }

local function line(sep)
	-- quoted fields may hold separators, doubled quotes and newlines
	local field = P('"') * (P('""') + (1 - P('"')))^0 * P('"')^-1 + (1 - S(sep .. '\r\n'))^1
	local s = token(lexer.OPERATOR, sep)
	local function col(i) return token(colours[(i - 1) % #colours + 1], field)^-1 end
	-- one round of colours over columns 2 to #colours + 1, repeated for the rest of the line
	local round = col(#colours + 1)
	for i = #colours, 2, -1 do round = col(i) * (s * round)^-1 end
	-- starts with what it consumes (lexer rules must): the first column, or the separator after
	-- an empty one
	return (token(colours[1], field) + s * round) * (s * round)^0
end

local function has(sep) return #((1 - S(sep .. '\n'))^0 * sep) end

lex:add_rule('line', has('\t') * line('\t') + has(';') * line(';') + line(','))
lex:add_rule('newline', token(lexer.WHITESPACE, S('\r\n')^1))

return lex
