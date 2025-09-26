return {
  {
    'nvim-telescope/telescope.nvim', 
    tag = '0.1.5', 
    dependencies = { 'nvim-lua/plenary.nvim' },
    
    -- Telescope configuration
    config = function()
      local telescope = require('telescope')
      local builtin = require('telescope.builtin')
      
      telescope.setup {
        defaults = {
          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
--          '--hidden', -- Include hidden files (dotfiles)
--            '--no-ignore' -- Ignore .gitignore and .rgignore
          }
        }
      }
      
      -- Keybindings for Telescope with local variables loaded
      vim.keymap.set('n', '<C-f>', builtin.find_files, {})
      vim.keymap.set('n', '<C-g>', builtin.live_grep, {})
    end
  },
  
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require('telescope').setup {
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown({})
          }
        }
      }
      require('telescope').load_extension('ui-select')
    end
  }


}

