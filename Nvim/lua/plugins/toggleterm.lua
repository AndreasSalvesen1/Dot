return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
			size = 80,
			open_mapping = [[<C-\>]],
			shade_terminals = true,
			direction = "vertical",
			close_on_exit = true,
			shell = vim.o.shell,
		})

		local Terminal = require("toggleterm.terminal").Terminal
		local lazygit = Terminal:new({
			cmd = "lazygit",
			hidden = true,
			direction = "float",
			float_opts = {
				border = "rounded", -- Improved border appearance
				width = math.floor(vim.o.columns * 0.9), -- Ensure integral width
				height = math.floor(vim.o.lines * 0.9), -- Ensure integral height
			},
		})
		function _G.toggle_lazygit()
			lazygit:toggle()
		end


	end,
}
