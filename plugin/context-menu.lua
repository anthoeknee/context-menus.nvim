if vim.fn.has("nvim-0.8.0") == 0 then
  vim.notify("context-menu.nvim requires Neovim >= 0.8.0", vim.log.levels.ERROR)
  return
end

-- Prevent loading twice
if vim.g.loaded_context_menu then
  return
end
vim.g.loaded_context_menu = true

-- Create key mappings for right-click context menu
vim.api.nvim_set_keymap('n', '<RightMouse>', ':lua require("context-menu.core").show_menu()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<RightMouse>', '<Esc>:lua require("context-menu.core").show_menu()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<RightMouse>', ':lua require("context-menu.core").show_menu()<CR>', { noremap = true, silent = true })

vim.api.nvim_create_user_command("ContextMenuRegister", function(opts)
  local args = vim.split(opts.args, " ")
  if #args < 2 then
    vim.notify("Usage: ContextMenuRegister <name> <module>", vim.log.levels.ERROR)
    return
  end
  
  local name = args[1]
  local module_name = args[2]
  
  local ok, provider = pcall(require, module_name)
  if ok then
    require("context-menu").register_provider(name, provider)
  else
    vim.notify("Failed to load provider module: " .. module_name, vim.log.levels.ERROR)
  end
end, { nargs = "+" })
