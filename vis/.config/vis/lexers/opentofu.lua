-- *.tf/*.tofu: HCL under its own syntax name, which vis-lspc sends as the languageId tofu-ls
-- expects ('opentofu'); plain .hcl and .tfvars stay hcl, without a language server.
local lexer = lexer

return lexer.new(..., { inherit = lexer.load('hcl') })
