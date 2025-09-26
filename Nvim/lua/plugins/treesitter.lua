return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",

	config = function()
		local ts = require("nvim-treesitter.configs")
		ts.setup({
			ensure_installed = {
				"markdown",
				"markdown_inline",
				"lua",
				"python",
				"bash",
				"json",
				"latex",
				"yaml",
			},
			auto_install = true,
			highlight = {
				enable = true,
				disable = { "latex", "tex" }, -- conceal workaround
			},
			indent = { enable = true },
		})

		-- put normal Lua here, AFTER setup()
		local grp = vim.api.nvim_create_augroup("NoSpellAlways", { clear = true })
		vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
			group = grp,
			callback = function()
				vim.opt_local.spell = false
			end,
		})
	end,
}
