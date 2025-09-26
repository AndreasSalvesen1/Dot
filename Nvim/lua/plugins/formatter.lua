return {
	-- Auto-format on save with smart per-language defaults
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre", "BufReadPost" },
		cmd = { "ConformInfo", "Format", "FormatDisable", "FormatEnable" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				desc = "Format buffer",
			},
		},
		opts = {
			-- Choose formatters per filetype. First available is used.
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_format", "black" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				cmake = { "cmake_format" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt" },
				fish = { "fish_indent" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				html = { "prettier" },
				markdown = { "prettier" },
				yaml = { "prettier" },
				toml = { "taplo" },
				go = { "gofumpt" },
				rust = { "rustfmt" }, -- via rustup
				tex = { "latexindent" }, -- LaTeX formatter
				["*"] = { "trim_whitespace" },
			},
			-- Stop once a formatter succeeds
			format_on_save = function(bufnr)
				-- Skip huge files
				local ok, api = pcall(vim.api.nvim_buf_line_count, bufnr)
				if ok and api > 10000 then
					return nil
				end
				return { lsp_fallback = true, timeout_ms = 3000 }
			end,
			notify_on_error = false,
			default_format_opts = { lsp_format = "fallback" },
			stop_after_first = true,
			formatters = {
				prettier = { prefer_local = "node_modules/.bin" },
				shfmt = { prepend_args = { "-i", "2", "-ci" } },
				clang_format = { prepend_args = { "--style", "file" } },
				black = { prepend_args = { "--fast" } },
			},
		},
	},

	-- Ensure the formatters are installed automatically
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		event = "VeryLazy",
		opts = {
			ensure_installed = {
				-- Lua
				"stylua",
				-- Python
				"ruff",
				"black",
				-- C/C++
				"clang-format",
				-- Shell
				"shfmt",
				-- JS/TS/HTML/CSS/MD/YAML/JSON
				"prettier",
				-- TOML
				"taplo",
				-- Go
				"gofumpt",
				-- CMake
				"cmakelang",
				-- Fish
				"fish_indent",
			},
			auto_update = false,
			run_on_start = true,
			start_delay = 0,
			debounce_hours = 24,
		},
	},
}
