-- System bruker lazy packet manager:
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
vim.g.lazyvim_check_order = false

vim.o.number = true

-- Lokal Vim-config
require("globalkeys")

-- Setup lazy.nvim with the plugins
require("lazy").setup("plugins")

-- Clipboard provider
vim.opt.clipboard = "unnamedplus"

--No spell check
vim.opt_local.spell = false
