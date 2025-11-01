local opt = vim.opt

opt.spell = true
opt.spelllang = { "en_us", "ru" }

opt.fixendofline = false
opt.endofline = false

opt.list = true
opt.listchars = {
  eol = "↴",
  tab = "→ ",
  trail = "·",
  extends = "»",
  precedes = "«",
  -- space = "·", -- если прям хочешь видеть пробелы
}
