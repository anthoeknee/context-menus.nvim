local M = {}

function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  local start_line = start_pos[2]
  local start_col = start_pos[3]
  local end_line = end_pos[2]
  local end_col = end_pos[3]
  
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  if #lines == 0 then
    return nil
  end
  
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    lines[1] = string.sub(lines[1], start_col)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  end
  
  return {
    text = table.concat(lines, "\n"),
    start_line = start_line,
    start_col = start_col,
    end_line = end_line,
    end_col = end_col,
  }
end

function M.get_word_bounds()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Find word start
  local start_col = col
  while start_col > 0 and line:sub(start_col, start_col):match("%w") do
    start_col = start_col - 1
  end
  start_col = start_col + 1
  
  -- Find word end
  local end_col = col + 1
  while end_col <= #line and line:sub(end_col, end_col):match("%w") do
    end_col = end_col + 1
  end
  
  return start_col, end_col - 1
end

return M
