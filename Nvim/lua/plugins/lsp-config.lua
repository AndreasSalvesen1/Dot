return {

	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},

	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"pylyzer",
					"texlab",
				},
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local lspconfig = require("lspconfig")

			lspconfig.lua_ls.setup({
				capabilities = capabilities,
			})
			lspconfig.ts_ls.setup({
				capabilities = capabilities,
			})

			lspconfig.texlab.setup({
				capabilities = capabilities,
			})

			--	lspconfig.pylyzer.setup({
			--
			--				on_attach = function(bufnr)
			--					vim.lsp.buf.format({
			--						timeout_ms = 5000, -- Increase to 5 seconds
			--						bufnr = bufnr,
			--					})
			--				end,

			--			})
		end,
	},
}
