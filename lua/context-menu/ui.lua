local M = {}

local current_menu = nil

function M.create_menu(opts)
  if current_menu then
    M.close_menu(current_menu)
  end

  local Menu = {}
  Menu.items = opts.items
  Menu.config = opts.config
  Menu.on_select = opts.on_select
  Menu.selected = 1
  Menu.augroup = vim.api.nvim_create_augroup("ContextMenu", { clear = true })

  -- Calculate dimensions
  local max_width = 0
  local lines = {}

  for _, item in ipairs(Menu.items) do
    if item.separator then
      table.insert(lines, string.rep("─", Menu.config.max_width))
    else
      local icon = item.icon and (Menu.config.icons[item.icon] or item.icon) or ""
      local label = item.label or ""
      local shortcut = item.shortcut or ""

      local line = string.format(" %s %s", icon, label)
      if shortcut ~= "" then
        local padding = Menu.config.max_width - #line - #shortcut - 2
        if padding > 0 then
          line = line .. string.rep(" ", padding) .. shortcut
        end
      end

      table.insert(lines, line)
      max_width = math.max(max_width, #line)
    end
  end

  -- Create buffer
  Menu.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(Menu.bufnr, 0, -1, false, lines)
  vim.bo[Menu.bufnr].modifiable = false
  vim.bo[Menu.bufnr].buftype = "nofile"

  -- Calculate window position
  local win_height = #lines
  local win_width = math.min(max_width + 2, Menu.config.max_width)

  local row = opts.position.row
  local col = opts.position.col

  -- Adjust position to keep menu on screen
  local screen_height = vim.o.lines
  local screen_width = vim.o.columns

  if win_height > screen_height then
    win_height = screen_height
  end

  if win_width > screen_width then
    win_width = screen_width
  end

  if row + win_height > screen_height then
    row = screen_height - win_height
  end

  if col + win_width > screen_width then
    col = screen_width - win_width
  end

  -- Create window
  Menu.winnr = vim.api.nvim_open_win(Menu.bufnr, true, {
    relative = "editor",
    row = row,
    col = col,
    width = win_width,
    height = win_height,
    style = "minimal",
    border = Menu.config.border,
    focusable = true,
  })

  -- Set up highlights and keymaps
  M._setup_highlights(Menu)
  M._setup_keymaps(Menu)

  -- Initial highlight
  M._update_highlight(Menu)

  -- Auto-close on focus lost or entering another window
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    group = Menu.augroup,
    buffer = Menu.bufnr,
    callback = function()
      M.close_menu(Menu)
    end,
  })

  -- This handles clicking outside the menu window
  vim.api.nvim_create_autocmd("WinEnter", {
    group = Menu.augroup,
    callback = function(event)
      if event.win ~= Menu.winnr then
        M.close_menu(Menu)
      end
    end,
  })

  current_menu = Menu
  return Menu
end

function M._setup_keymaps(menu)
  local function move_selection(direction)
    local new_pos = menu.selected
    repeat
      new_pos = new_pos + direction
      if new_pos < 1 then
        new_pos = #menu.items
      elseif new_pos > #menu.items then
        new_pos = 1
      end
    until not menu.items[new_pos].separator
    menu.selected = new_pos
    M._update_highlight(menu)
  end

  local function execute_selection()
    local item = menu.items[menu.selected]
    if item and not item.separator then
      M.close_menu(menu)
      menu.on_select(item)
    end
  end

  local function set_keymap(keys, callback)
    local opts = { buffer = menu.bufnr, silent = true, nowait = true }
    if type(keys) == "string" then
      vim.keymap.set("n", keys, callback, opts)
    elseif type(keys) == "table" then
      for _, key in ipairs(keys) do
        vim.keymap.set("n", key, callback, opts)
      end
    end
  end

  set_keymap(menu.config.keymaps.down, function() move_selection(1) end)
  set_keymap(menu.config.keymaps.up, function() move_selection(-1) end)
  set_keymap(menu.config.keymaps.execute, execute_selection)
  set_keymap(menu.config.keymaps.cancel, function() M.close_menu(menu) end)

  -- Mouse hover support
  vim.keymap.set("n", "<MouseMove>", function()
    local mouse_pos = vim.fn.getmousepos()
    if mouse_pos.winid ~= menu.winnr then return end

    local line = mouse_pos.line
    if line > 0 and line <= #menu.items and not menu.items[line].separator then
      if menu.selected ~= line then
        menu.selected = line
        M._update_highlight(menu)
      end
    end
  end, { buffer = menu.bufnr, silent = true })

  -- Mouse click support
  vim.keymap.set("n", "<LeftMouse>", function()
    local mouse_pos = vim.fn.getmousepos()
    if mouse_pos.winid == menu.winnr then
      local line = mouse_pos.line
      if line > 0 and line <= #menu.items and not menu.items[line].separator then
        menu.selected = line
        execute_selection()
      end
    else
      -- This case should be handled by WinEnter/WinLeave autocmds
      M.close_menu(menu)
    end
  end, { buffer = menu.bufnr, silent = true })

  vim.keymap.set("n", "<RightMouse>", function()
    M.close_menu(menu)
  end, { buffer = menu.bufnr, silent = true })
end

function M._setup_highlights(menu)
  vim.api.nvim_set_hl(0, "ContextMenuSelected", { link = "PmenuSel" })
  vim.api.nvim_set_hl(0, "ContextMenuNormal", { link = "Pmenu" })
  vim.api.nvim_set_hl(0, "ContextMenuBorder", { link = "FloatBorder" })
  vim.api.nvim_set_hl(0, "ContextMenuSeparator", { link = "Comment" })
end

function M._update_highlight(menu)
  if not vim.api.nvim_buf_is_valid(menu.bufnr) then return end
  vim.api.nvim_buf_clear_namespace(menu.bufnr, -1, 0, -1)

  for i, item in ipairs(menu.items) do
    if item.separator then
      vim.api.nvim_buf_add_highlight(menu.bufnr, -1, "ContextMenuSeparator", i - 1, 0, -1)
    elseif i == menu.selected then
      vim.api.nvim_buf_add_highlight(menu.bufnr, -1, "ContextMenuSelected", i - 1, 0, -1)
    end
  end
end

function M.close_menu(menu)
  if menu == nil or menu ~= current_menu then
    return
  end

  if vim.api.nvim_win_is_valid(menu.winnr) then
    vim.api.nvim_win_close(menu.winnr, true)
  end
  if vim.api.nvim_buf_is_valid(menu.bufnr) then
    vim.api.nvim_buf_delete(menu.bufnr, { force = true })
  end

  pcall(vim.api.nvim_del_augroup_by_id, menu.augroup)
  current_menu = nil
end

return M
