local M = {}

M.config = {
  -- Global configuration
  border = "rounded",
  max_width = 30,
  keymaps = {
    execute = "<CR>",
    cancel = "<Esc>",  -- Changed: single string instead of table
    up = { "k", "<Up>" },
    down = { "j", "<Down>" },
  },
  icons = {
    file = "󰈔",
    folder = "󰉋",
    copy = "󰆏",
    cut = "󰆐",
    paste = "󰆒",
    delete = "󰆴",
    rename = "󰏫",
    undo = "󰕌",
    redo = "󰑎",
    find = "󰍉",
  },
  providers = {},
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Load core functionality
  require("context-menu.core").setup(M.config)
  
  -- Load default providers
  require("context-menu.providers").load_defaults()
  
  -- Set up autocommands
  M._setup_autocommands()
end

function M._setup_autocommands()
  local group = vim.api.nvim_create_augroup("ContextMenu", { clear = true })
  
  -- Override default right-click behavior
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    pattern = "*",
    callback = function()
      vim.keymap.set("n", "<RightMouse>", function()
        require("context-menu.core").show_menu()
      end, { buffer = true, silent = true })
    end,
  })
end

-- Public API for registering custom providers
function M.register_provider(name, provider)
  require("context-menu.providers").register(name, provider)
end

return M
