-- iceberg.vim (dark) with nvim's transparent Normal background
local lexers = vis.lexers

local fg, comment, linenr = '#c6c8d1', '#6b7089', '#444b71'
local blue, cyan, green, magenta = '#84a0c6', '#89b8c2', '#b4be82', '#a093c7'
local orange, red, func = '#e2a478', '#e27878', '#a3adcb'

lexers.STYLE_DEFAULT = 'fore:' .. fg
lexers.STYLE_NOTHING = ''
lexers.STYLE_ANNOTATION = 'fore:' .. green
lexers.STYLE_ATTRIBUTE = 'fore:' .. magenta
lexers.STYLE_CLASS = 'fore:' .. blue
lexers.STYLE_COMMENT = 'fore:' .. comment
lexers.STYLE_CONSTANT = 'fore:' .. magenta
lexers.STYLE_CONSTANT_BUILTIN = 'fore:' .. magenta
lexers.STYLE_DEFINITION = 'fore:' .. orange
lexers.STYLE_EMBEDDED = 'fore:' .. green
lexers.STYLE_ERROR = 'fore:' .. red
lexers.STYLE_FUNCTION = 'fore:' .. func
lexers.STYLE_FUNCTION_BUILTIN = 'fore:' .. func
lexers.STYLE_FUNCTION_METHOD = 'fore:' .. func
lexers.STYLE_HEADING = 'fore:' .. orange
lexers.STYLE_IDENTIFIER = ''
lexers.STYLE_KEYWORD = 'fore:' .. blue
lexers.STYLE_LABEL = 'fore:' .. green
lexers.STYLE_NUMBER = 'fore:' .. magenta
lexers.STYLE_OPERATOR = 'fore:' .. fg
lexers.STYLE_PREPROCESSOR = 'fore:' .. green
lexers.STYLE_REGEX = 'fore:' .. cyan
lexers.STYLE_STRING = 'fore:' .. cyan
lexers.STYLE_TAG = 'fore:' .. fg
lexers.STYLE_TYPE = 'fore:' .. blue
lexers.STYLE_VARIABLE = ''
lexers.STYLE_VARIABLE_BUILTIN = 'fore:' .. blue
lexers.STYLE_WHITESPACE = ''

lexers.STYLE_LINENUMBER = 'fore:' .. linenr .. ',back:#1e2132'
lexers.STYLE_LINENUMBER_CURSOR = 'fore:#cdd1e6,back:#2a3158'
lexers.STYLE_CURSOR = 'fore:#eff0f4,back:#5b6389'
lexers.STYLE_CURSOR_PRIMARY = 'fore:#161821,back:' .. fg
-- styles start from STYLE_DEFAULT's foreground: keep the text's own colour
lexers.STYLE_CURSOR_LINE = 'fore:default,back:#1e2132'
lexers.STYLE_COLOR_COLUMN = 'fore:default,back:#1e2132'
lexers.STYLE_SELECTION = 'fore:default,back:#272c42'
lexers.STYLE_STATUS = 'fore:' .. comment .. ',back:#161821'
lexers.STYLE_STATUS_FOCUSED = 'fore:' .. fg .. ',back:#1e2132'
lexers.STYLE_SEPARATOR = 'fore:' .. linenr
lexers.STYLE_INFO = 'fore:' .. fg
lexers.STYLE_EOF = 'fore:#242940'

-- Diff
lexers.STYLE_ADDITION = 'fore:' .. green
lexers.STYLE_DELETION = 'fore:' .. red
lexers.STYLE_CHANGE = 'fore:' .. cyan

-- CSS
lexers.STYLE_PROPERTY = ''
lexers.STYLE_PSEUDOCLASS = 'fore:' .. green
lexers.STYLE_PSEUDOELEMENT = 'fore:' .. green

-- HTML
lexers.STYLE_TAG_UNKNOWN = lexers.STYLE_TAG
lexers.STYLE_ATTRIBUTE_UNKNOWN = lexers.STYLE_ATTRIBUTE

-- Markdown
for level = 1, 6 do
	lexers['STYLE_HEADING_H' .. level] = lexers.STYLE_HEADING
end
lexers.STYLE_BOLD = 'bold'
lexers.STYLE_ITALIC = 'italics'
lexers.STYLE_LIST = lexers.STYLE_KEYWORD
lexers.STYLE_LINK = 'fore:' .. cyan .. ',underlined'
lexers.STYLE_REFERENCE = lexers.STYLE_KEYWORD
lexers.STYLE_HR = 'fore:' .. comment

-- YAML
lexers.STYLE_ERROR_INDENT = 'back:' .. red
