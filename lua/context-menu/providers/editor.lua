local M = {}
local utils = require("context-menu.utils")

function M.get_items(context)
  local items = {}
  
  -- Basic editing operations
  if context.selection then
    table.insert(items, {
      label = "Copy",
      icon = "copy",
      shortcut = "y",
      callback = function(context)
        vim.cmd('normal! "+y')
      end,
    })
    
    table.insert(items, {
      label = "Cut",
      icon = "cut",
      shortcut = "x",
      callback = function(context)
        vim.cmd('normal! "+x')
      end,
    })
  else
    table.insert(items, {
      label = "Select All",
      shortcut = "Ctrl+A",
      callback = function(context)
        vim.cmd("normal! ggVG")
      end,
    })
  end
  
  table.insert(items, {
    label = "Paste",
    icon = "paste",
    shortcut = "p",
    callback = function(context)
      vim.cmd('normal! "+p')
    end,
  })
  
  table.insert(items, { separator = true })
  
  table.insert(items, {
    label = "Undo",
    icon = "undo",
    shortcut = "u",
    command = "undo",
  })
  
  table.insert(items, {
    label = "Redo",
    icon = "redo",
    shortcut = "Ctrl+R",
    command = "redo",
  })
  
  table.insert(items, { separator = true })
  
  table.insert(items, {
    label = "Find & Replace",
    icon = "find",
    shortcut = "/",
    callback = function(context)
      vim.ui.input({
        prompt = "Find: ",
      }, function(search)
        if search then
          vim.ui.input({
            prompt = "Replace with: ",
          }, function(replace)
            if replace then
              vim.cmd("%s/" .. search .. "/" .. replace .. "/gc")
            end
          end)
        end
      end)
    end,
  })
  
  -- LSP operations (if available)
  local clients = vim.lsp.get_clients({ bufnr = context.bufnr }) -- Fixed: use get_clients instead of get_active_clients
  if #clients > 0 then
    table.insert(items, { separator = true })

    table.insert(items, {
      label = "Format",
      icon = "brush",
      callback = function(context)
        vim.lsp.buf.format({ async = true })
      end,
    })

    table.insert(items, {
      label = "Go to Definition",
      shortcut = "gd",
      callback = function(context)
        vim.lsp.buf.definition()
      end,
    })

    table.insert(items, {
      label = "Show Documentation",
      shortcut = "K",
      callback = function(context)
        vim.lsp.buf.hover()
      end,
    })

    table.insert(items, {
      label = "Find References",
      shortcut = "gr",
      callback = function(context)
        vim.lsp.buf.references()
      end,
    })

    table.insert(items, {
      label = "Rename Symbol",
      shortcut = "rn",
      callback = function(context)
        vim.lsp.buf.rename()
      end,
    })

    table.insert(items, {
      label = "Code Actions",
      shortcut = "ca",
      callback = function(context)
        vim.lsp.buf.code_action()
      end,
    })
  end

  -- Git operations (if gitsigns is available)
  local gitsigns_avail, gitsigns = pcall(require, "gitsigns")
  if gitsigns_avail and gitsigns.is_attached() then
    table.insert(items, { separator = true })
    table.insert(items, {
      label = "Git",
      icon = "git",
      items = {
        {
          label = "Stage Hunk",
          callback = function(context)
            gitsigns.stage_hunk()
          end,
        },
        {
          label = "Reset Hunk",
          callback = function(context)
            gitsigns.reset_hunk()
          end,
        },
        { separator = true },
        {
          label = "Preview Hunk",
          callback = function(context)
            gitsigns.preview_hunk()
          end,
        },
        {
          label = "Blame Line",
          callback = function(context)
            gitsigns.blame_line({ full = true })
          end,
        },
        { separator = true },
        {
          label = "Next Hunk",
          callback = function(context)
            gitsigns.next_hunk()
          end,
        },
        {
          label = "Prev Hunk",
          callback = function(context)
            gitsigns.prev_hunk()
          end,
        },
      },
    })
  end
  
  return items
end

return M
