-- Virtual text display and buffer management
local patterns = require('import-size.patterns')
local resolver = require('import-size.resolver')
local highlights = require('import-size.highlights')

local M = {}

local ns_id = vim.api.nvim_create_namespace('import_size')

function M.update_virtual_text()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current_file = vim.api.nvim_buf_get_name(bufnr)
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  
  -- Clear existing virtual text
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  
  for i, line in ipairs(lines) do
    local import_path = patterns.extract_import_path(line)
    if import_path then
      local file_path = resolver.resolve_file_path(import_path, current_dir)
      local line_count = resolver.count_lines(file_path)
      
      if line_count > 0 then
        local hl_group = highlights.get_highlight_group(line_count)
        
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, 0, {
          virt_text = {{ ' (' .. line_count .. ' lines)', hl_group }},
          virt_text_pos = 'eol',
        })
      end
    end
  end
end

function M.clear_virtual_text()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

function M.toggle_virtual_text()
  local bufnr = vim.api.nvim_get_current_buf()
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, {})
  
  if #marks > 0 then
    M.clear_virtual_text()
  else
    M.update_virtual_text()
  end
end

return M