local M = {}

M.providers = {}

function M.register(name, provider)
  if type(provider) == "table" and provider.get_items then
    M.providers[name] = provider
  else
    error("Provider must have a get_items function")
  end
end

function M.load_defaults()
  -- Load built-in providers
  M.register("neo-tree", require("context-menu.providers.neo-tree"))
  M.register("editor", require("context-menu.providers.editor"))
end

function M.get_items(context)
  local all_items = {}
  
  -- Check Neo-tree first (higher priority)
  if context.neo_tree and M.providers["neo-tree"] then
    local items = M.providers["neo-tree"].get_items(context)
    if #items > 0 then
      return items
    end
  end
  
  -- Default to editor context
  if M.providers["editor"] then
    all_items = M.providers["editor"].get_items(context)
  end
  
  -- Let other providers add items
  for name, provider in pairs(M.providers) do
    if name ~= "neo-tree" and name ~= "editor" then
      local ok, items = pcall(provider.get_items, context)
      if ok and items then
        for _, item in ipairs(items) do
          table.insert(all_items, item)
        end
      end
    end
  end
  
  return all_items
end

return M
