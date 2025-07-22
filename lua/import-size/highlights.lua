-- Highlight group management for import size display
local M = {}

function M.get_highlight_group(line_count)
  if line_count <= 100 then
    return 'ImportSize100'
  elseif line_count <= 200 then
    return 'ImportSize200'
  elseif line_count <= 400 then
    return 'ImportSize400'
  else
    return 'ImportSize500'
  end
end

function M.setup_highlights()
  -- Only set defaults if the highlight groups don't already exist
  local existing_groups = {'ImportSize100', 'ImportSize200', 'ImportSize400', 'ImportSize500'}
  for _, group in ipairs(existing_groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group })
    if vim.tbl_isempty(hl) then
      -- Set default colors only if not already defined
      if group == 'ImportSize100' then
        vim.api.nvim_set_hl(0, group, { fg = '#22c55e', italic = true })
      elseif group == 'ImportSize200' then
        vim.api.nvim_set_hl(0, group, { fg = '#eab308', italic = true })
      elseif group == 'ImportSize400' then
        vim.api.nvim_set_hl(0, group, { fg = '#f97316', italic = true })
      elseif group == 'ImportSize500' then
        vim.api.nvim_set_hl(0, group, { fg = '#ef4444', italic = true })
      end
    end
  end
end

return M