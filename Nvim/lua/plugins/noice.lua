return {
  -- keep your Noice config
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "rcarriga/nvim-notify",
        lazy = true,
        config = function()
          vim.notify = require("notify")
        end,
      },
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
    },
    config = function(_, opts)
      require("noice").setup(opts)
    end,
  },

  -- disable LazyVim's “Welcome/News” popup
  { "LazyVim/LazyVim",  opts = { news = { lazyvim = false } } },

}
