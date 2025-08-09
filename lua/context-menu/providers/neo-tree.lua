local M = {}

function M.get_items(context)
  if not context.neo_tree then
    return {}
  end

  local node = context.neo_tree.node
  if not node then
    return {}
  end

  local items = {}
  -- Lazily require commands for performance
  local commands = require("neo-tree.sources.filesystem.commands")
  local state = context.neo_tree.state

  -- Section 1: Creation
  table.insert(items, {
    label = "New file",
    icon = " ", -- Nerd Font: nf-fa-plus_square
    shortcut = "a",
    callback = function(context)
      commands.add(state)
    end,
  })
  table.insert(items, {
    label = "New folder",
    icon = " ", -- Nerd Font: nf-fa-plus_square
    shortcut = "A",
    callback = function(context)
      commands.add_directory(state)
    end,
  })
  table.insert(items, { separator = true })

  -- Section 2: Opening (only for files or collapsed directories)
  if node.type ~= "directory" or not node:is_expanded() then
    table.insert(items, {
      label = "Open in window",
      icon = " ", -- Nerd Font: nf-dev-plain_box
      shortcut = "o",
      callback = function(context)
        commands.open(state)
      end,
    })
    table.insert(items, {
      label = "Open in vertical split",
      icon = " ", -- Nerd Font: nf-mdi-view_split_vertical
      shortcut = "v",
      callback = function(context)
        commands.open_vsplit(state)
      end,
    })
    table.insert(items, {
      label = "Open in horizontal split",
      icon = " ", -- Nerd Font: nf-mdi-view_split_horizontal
      shortcut = "s",
      callback = function(context)
        commands.open_hsplit(state)
      end,
    })
    table.insert(items, {
      label = "Open in new tab",
      icon = "󰓪 ", -- Nerd Font: nf-mdi-tab_plus
      shortcut = "t",
      callback = function(context)
        commands.open_tabnew(state)
      end,
    })
    table.insert(items, { separator = true })
  end

  -- Section 3: Clipboard & Path
  table.insert(items, {
    label = "Cut",
    icon = " ", -- Nerd Font: nf-fa-scissors
    shortcut = "x",
    callback = function(context)
      commands.cut_to_clipboard(state)
    end,
  })
  table.insert(items, {
    label = "Paste",
    icon = " ", -- Nerd Font: nf-fa-clipboard
    shortcut = "p",
    callback = function(context)
      commands.paste_from_clipboard(state)
    end,
  })
  table.insert(items, {
    label = "Copy",
    icon = " ", -- Nerd Font: nf-fa-clipboard
    shortcut = "c",
    callback = function(context)
      commands.copy_to_clipboard(state)
    end,
  })
  table.insert(items, {
    label = "Copy absolute path",
    icon = " ", -- Nerd Font: nf-fa-link
    shortcut = "gy",
    callback = function(context)
      local path = node:get_id()
      vim.fn.setreg("+", path)
      vim.notify("Copied absolute path: " .. path)
    end,
  })
  table.insert(items, {
    label = "Copy relative path",
    icon = "./",
    shortcut = "Y",
    callback = function(context)
      local absolute_path = node:get_id()
      local relative_path = vim.fn.fnamemodify(absolute_path, ":.")
      vim.fn.setreg("+", relative_path)
      vim.notify("Copied relative path: " .. relative_path)
    end,
  })
  table.insert(items, { separator = true })

  -- Section 4: System Integration
  table.insert(items, {
    label = "Open in terminal",
    icon = " ", -- Nerd Font: nf-fae-terminal
    callback = function(context)
      commands.open_in_terminal(state)
    end,
  })
  table.insert(items, { separator = true })

  -- Section 5: Modification & Deletion
  table.insert(items, {
    label = "Duplicate",
    icon = " ", -- Nerd Font: nf-fa-clone
    callback = function(context)
      local path = node:get_id()
      local basename = vim.fn.fnamemodify(path, ":t")
      vim.ui.input({ prompt = "New name for " .. basename, default = basename .. "_copy" }, function(new_name)
        if not new_name or new_name == "" then
          return
        end
        local new_path = vim.fn.fnamemodify(path, ":h") .. "/" .. new_name
        if vim.loop.fs_access(new_path, "r") then
          vim.notify("Error: Destination already exists", vim.log.levels.ERROR)
          return
        end

        local ok, err = pcall(vim.fs.cp, path, new_path)

        if ok then
          vim.notify("Duplicated to " .. new_path)
          if commands.refresh then
            commands.refresh(state)
          end
        else
          vim.notify("Error: Failed to duplicate: " .. err, vim.log.levels.ERROR)
        end
      end)
    end,
  })
  table.insert(items, {
    label = "Rename",
    icon = "󰑕 ", -- Nerd Font: nf-mdi-rename_box
    shortcut = "r",
    callback = function(context)
      commands.rename(state)
    end,
  })
  table.insert(items, {
    label = "Trash",
    icon = " ", -- Nerd Font: nf-fa-trash_o
    shortcut = "D",
    callback = function(context)
      commands.move_to_trash(state)
    end,
  })
  table.insert(items, {
    label = "Delete",
    icon = " ", -- Nerd Font: nf-fa-times_circle
    shortcut = "d",
    callback = function(context)
      commands.delete(state)
    end,
  })

  return items
end

return M
