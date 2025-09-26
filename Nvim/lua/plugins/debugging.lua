return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui", -- UI for nvim-dap
		"mfussenegger/nvim-dap-python", -- Python-specific adapter
		"nvim-neotest/nvim-nio", -- For testing integration (if needed)
		"williamboman/mason.nvim", -- Manage external tools
		{
			"jay-babu/mason-nvim-dap.nvim", -- Bridge between mason and nvim-dap
			dependencies = { "williamboman/mason.nvim", "mfussenegger/nvim-dap" },
			config = function()
				require("mason-nvim-dap").setup({
					ensure_installed = { "codelldb", "lua" }, -- Automatically install codelldb
					automatic_setup = true, -- Auto-configure installed adapters
				})

				require("mason-nvim-dap").setup({
					ensure_installed = { "codelldb", "lua" },
					automatic_setup = true,
				})

				require("mason-nvim-dap").default_setup("codelldb")
				--				require("mason-nvim-dap").default_setup("lua")
			end,
		},
	},

	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		dapui.setup()

		-- Python Configuration
		local python_path = "/home/andreas/.neovim-venv/bin/python3"
		require("dap-python").setup(python_path)

		-- Lua configuration
		--		dap.adapters.lua = {
		--			type = "executable",
		--			command = "lua-debug-adapter",
		--			args = {},
		--		}
		--
		--		dap.configurations.lua = {
		--			{
		--				type = "lua",
		--				request = "launch",
		--				name = "Launch file",
		--				program = function()
		--					return vim.fn.input("Path to file: ", vim.fn.getcwd() .. "/", "file")
		--				end,
		--				cwd = "${workspaceFolder}",
		--				stopOnEntry = false,
		--				console = "integratedTerminal",
		--			},
		--		}

		-- C++ Configuration with LLDB

		require("dap").adapters.lldb = {
			type = "server",
			port = 2088, -- The default port for codelldb
			executable = {
				command = "codelldb", -- The codelldb command installed via mason
				args = { "--port", "2088" },
			},
		}

		require("dap").configurations.cpp = {
			{
				name = "Launch File",
				type = "lldb", -- Use the lldb adapter
				request = "launch",
				program = function()
					if vim.bo.filetype == "cpp" then
						vim.cmd("lcd " .. vim.fn.expand("%:p:h")) -- Change working directory to the file's directory
					end
					return vim.fn.expand("${workspaceFolder}/main") -- Path to compiled executable
				end,
				cwd = "${workspaceFolder}",
				stopAtEntry = true, -- Pause at the entry point of the program
				runInTerminal = true, -- Run in an integrated terminal
			},
		}

		-- Optional: Use the same configuration for C files
		dap.configurations.c = dap.configurations.cpp

		-- Automatically Open/Close dap-ui
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end
		
		-- Keybindings for Debugging with local variables loaded
		vim.keymap.set("n", "<C-b>", dap.toggle_breakpoint, {})
        	vim.keymap.set("n", "<C-c>", dap.continue, {})
		vim.keymap.set("n", "<C-o>", dap.step_over, {})
		vim.keymap.set("n", "<C-i>", dap.step_into, {})
		vim.keymap.set("n", "<C-u>", dap.step_out, {})
	end,
}
