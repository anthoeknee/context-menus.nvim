local M = {}
local ui = require("context-menu.ui")
local providers = require("context-menu.providers")
local utils = require("context-menu.utils")

M.config = {}
M.current_menu = nil

function M.setup(config)
  M.config = config
end

function M.show_menu()
  -- Get current context
  local context = M._get_context()
  -- Get menu items from providers
  local items = providers.get_items(context)

  if #items == 0 then
    return
  end

  -- Get mouse position
  local mouse_pos = vim.fn.getmousepos()
  local row = mouse_pos.screenrow
  local col = mouse_pos.screencol

  -- Show the menu
  M.current_menu = ui.create_menu({
    items = items,
    position = { row = row, col = col },
    config = M.config,
    on_select = function(item)
      M._execute_item(item, context)
    end,
  })
end

function M._get_context()
  local mouse_pos = vim.fn.getmousepos()
  local context = {
    mouse_pos = mouse_pos,
    mode = vim.fn.mode(),
    type = "unknown",
  }

  local winid = mouse_pos.winid
  local line = mouse_pos.line
  local wincol = mouse_pos.wincol

  if winid == 0 then
    if line == 0 then
      -- It's either a tabline or a statusline of a non-current window
      if mouse_pos.screenrow == 1 and vim.o.showtabline > 0 then
        context.type = "tabline"
      else
        -- It's a statusline of a non-current window or a cmdline
        local is_statusline = false
        for _, w in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(w) then
            local pos = vim.fn.win_screenpos(w)
            if pos and pos.row > 0 then
              local height = vim.api.nvim_win_get_height(w)
              if pos.row + height == mouse_pos.screenrow then
                context.type = "statusline"
                context.winnr = w
                context.winid = w
                context.bufnr = vim.api.nvim_win_get_buf(w)
                is_statusline = true
                break
              end
            end
          end
        end
        if not is_statusline then
          if mouse_pos.screenrow >= vim.o.lines - vim.o.cmdheight then
            context.type = "cmdline"
          end
        end
      end
    else
      context.type = "separator"
    end
  else
    -- Click is inside a window
    context.winnr = winid
    context.winid = winid
    context.bufnr = vim.api.nvim_win_get_buf(winid)
    context.filetype = vim.bo[context.bufnr].filetype
    context.cursor = { line, mouse_pos.column > 0 and mouse_pos.column - 1 or 0 }

    if line == 0 then
      context.type = "statusline"
    elseif wincol == 0 then
      context.type = "gutter"
    else
      context.type = "editor"
    end
  end

  -- Add buffer-specific context
  if context.bufnr then
    -- Neo-tree support
    local ok, neo_tree = pcall(require, "neo-tree.sources.manager")
    if ok and context.winnr then
      local state = neo_tree.get_state_for_window(context.winnr)
      if state then
        context.type = "neo-tree"
        local node
        pcall(function()
          node = state.tree:get_node_at_line(line)
        end)
        if not node and line > 0 then -- Fallback for older neo-tree or other issues
          local original_cursor = vim.api.nvim_win_get_cursor(context.winnr)
          vim.api.nvim_win_set_cursor(context.winnr, { line, 0 })
          node = state.tree:get_node()
          vim.api.nvim_win_set_cursor(context.winnr, original_cursor)
        end
        context.neo_tree = { state = state, node = node }
      end
    end

    -- Get word under cursor
    if context.type == "editor" and context.cursor and context.cursor[1] > 0 then
      local original_win = vim.api.nvim_get_current_win()
      local original_cursor = vim.api.nvim_win_get_cursor(original_win)

      vim.api.nvim_set_current_win(context.winnr)
      vim.api.nvim_win_set_cursor(context.winnr, context.cursor)
      context.word = vim.fn.expand("<cword>")

      vim.api.nvim_set_current_win(original_win)
      vim.api.nvim_win_set_cursor(original_win, original_cursor)
    end
  end

  -- Visual selection
  if vim.fn.mode():match("[vV]") then
    context.selection = utils.get_visual_selection()
  end

  return context
end

function M._execute_item(item, context)
  if item.action then
    -- The action is a closure that already has the context it needs.
    local ok, err = pcall(item.action)
    if not ok then
      vim.notify("Error executing menu item: " .. err, vim.log.levels.ERROR)
    end
  elseif item.command then
    -- Execute vim command
    vim.cmd(item.command)
  elseif item.callback then
    -- Execute callback
    item.callback(context)
  end
end

return M
