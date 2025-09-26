vim.g.mapleader = " "
vim.g.maplocalleader = "\\" -- Bootstrap lazy.nvim

-- Keybindings to exit terminal mode
vim.keymap.set("t", "<Esc>", [[<C-\><C-n><CR>]], { noremap = true, silent = true })

-- Keybindings for specific terminals
vim.keymap.set("n", "<leader>t1", "<cmd>ToggleTerm 1<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>T1", "<cmd>ToggleTerm 1<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>t2", "<cmd>ToggleTerm 2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>T2", "<cmd>ToggleTerm 2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>t3", "<cmd>ToggleTerm 3<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>T3", "<cmd>ToggleTerm 3<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>t4", "<cmd>ToggleTerm 4<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>T4", "<cmd>ToggleTerm 4<CR>", { noremap = true, silent = true })

-- Keybindings for LazyGit floating terminal
vim.keymap.set("n", "<leader>lg", "<cmd>lua toggle_lazygit()<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>LG", "<cmd>lua toggle_lazygit()<CR>", { noremap = true, silent = true })

-- Keybindings for Gitsigns
vim.keymap.set("n", "<leader>g", ":Gitsigns preview_hunk<CR>", {})
vim.keymap.set("n", "<leader>b", ":Gitsigns toggle_current_line_blame", {})

-- Keybindings for LSP
vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})

-- Keybinding to toggle Neo-tree
vim.keymap.set("n", "<C-D>", ":Neotree filesystem reveal toggle<CR>", {})
--   vim.keymap.set('n', '<C-N>', ':Neotree filesystem reveal top<CR>', {})

-- Keybindings for saving
vim.keymap.set("n", "<C-S", ":wa<CR>", {})
vim.keymap.set("n", "<C-s>", ":wa<CR>", {})

-- Keybindings for quitting
vim.keymap.set("n", "<C-Q>", ":q<CR>", {})
vim.keymap.set("n", "<C-q>", ":q<CR>", {})

-- Keybindings for moving lines up or down, in normal and visual mode
vim.keymap.set("n", "<A-Up>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.keymap.set("n", "<A-Down>", ":m .+1<CR>==", { noremap = true, silent = true })
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })

--Keybindings to select lines up or down, in normal and visual mode
vim.keymap.set("n", "<S-Up>", "v<Up>", { noremap = true })
vim.keymap.set("n", "<S-Down>", "v<Down>", { noremap = true })
vim.keymap.set("n", "<S-Left>", "v<Left>", { noremap = true })
vim.keymap.set("n", "<S-Right>", "v<Right>", { noremap = true })

vim.keymap.set("x", "<S-Up>", "<Up>", { noremap = true })
vim.keymap.set("x", "<S-Down>", "<Down>", { noremap = true })
vim.keymap.set("x", "<S-Left>", "<Left>", { noremap = true })
vim.keymap.set("x", "<S-Right>", "<Right>", { noremap = true })
