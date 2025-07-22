local M = {}

local ns_id = vim.api.nvim_create_namespace('import_size')

local import_patterns = {
  -- JavaScript/TypeScript
  "^%s*import%s+.-from%s+[\"']([^\"']+)[\"']",
  "^%s*import%s+[\"']([^\"']+)[\"']",
  "^%s*const%s+.-=%s*require%s*%([\"']([^\"']+)[\"']%)",
  "^%s*let%s+.-=%s*require%s*%([\"']([^\"']+)[\"']%)",
  "^%s*var%s+.-=%s*require%s*%([\"']([^\"']+)[\"']%)",
  
  -- Python
  "^%s*from%s+([%w_.]+)%s+import",
  
  -- Go
  "^%s*import%s+[\"']([^\"']+)[\"']",
  
  -- Rust  
  "^%s*use%s+[%w_:]*::([%w_]+)",
  
  -- C/C++
  "^%s*#include%s+[<\"]([^>\"]+)[>\"]"
}

local function extract_import_path(line)
  for _, pattern in ipairs(import_patterns) do
    local match = string.match(line, pattern)
    if match then
      return match
    end
  end
  return nil
end

local function is_local_file(import_path)
  return string.sub(import_path, 1, 1) == '.' or string.sub(import_path, 1, 1) == '/'
end

local function resolve_file_path(import_path, current_dir)
  if not is_local_file(import_path) then
    return nil
  end
  
  local base_path
  if string.sub(import_path, 1, 1) == '.' then
    base_path = current_dir .. '/' .. import_path
  else
    base_path = import_path
  end
  
  base_path = vim.fn.resolve(base_path)
  
  -- Try exact path first
  if vim.fn.filereadable(base_path) == 1 then
    return base_path
  end
  
  -- Try common extensions
  local extensions = {'.js', '.ts', '.jsx', '.tsx', '.py', '.go', '.rs', '.c', '.cpp', '.h'}
  for _, ext in ipairs(extensions) do
    local path_with_ext = base_path .. ext
    if vim.fn.filereadable(path_with_ext) == 1 then
      return path_with_ext
    end
  end
  
  -- Try index files
  if vim.fn.isdirectory(base_path) == 1 then
    for _, ext in ipairs(extensions) do
      local index_path = base_path .. '/index' .. ext
      if vim.fn.filereadable(index_path) == 1 then
        return index_path
      end
    end
  end
  
  return nil
end

local function count_lines(file_path)
  if not file_path then return 0 end
  
  local file = io.open(file_path, 'r')
  if not file then return 0 end
  
  local count = 0
  for _ in file:lines() do
    count = count + 1
  end
  file:close()
  
  return count
end

local function get_highlight_group(line_count)
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

local function update_virtual_text()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current_file = vim.api.nvim_buf_get_name(bufnr)
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  
  -- Clear existing virtual text
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  
  for i, line in ipairs(lines) do
    local import_path = extract_import_path(line)
    if import_path then
      local file_path = resolve_file_path(import_path, current_dir)
      local line_count = count_lines(file_path)
      
      if line_count > 0 then
        local hl_group = get_highlight_group(line_count)
        
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, 0, {
          virt_text = {{ ' (' .. line_count .. ' lines)', hl_group }},
          virt_text_pos = 'eol',
        })
      end
    end
  end
end

local function setup_highlights()
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

function M.setup(opts)
  opts = opts or {}
  
  setup_highlights()
  
  -- Auto-update on buffer events
  vim.api.nvim_create_autocmd({'BufReadPost', 'BufWritePost', 'BufWritePre', 'TextChanged', 'TextChangedI', 'InsertLeave'}, {
    callback = function()
      vim.schedule(update_virtual_text)
    end,
  })
  
  -- Also update when any buffer is written (to catch changes to imported files)
  vim.api.nvim_create_autocmd('BufWritePost', {
    callback = function()
      -- Update all visible buffers since an imported file might have changed
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            local current_buf = vim.api.nvim_get_current_buf()
            vim.api.nvim_set_current_buf(buf)
            update_virtual_text()
            vim.api.nvim_set_current_buf(current_buf)
          end
        end)
      end
    end,
  })
  
  -- Initial update for current buffer
  vim.schedule(update_virtual_text)
end

function M.toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, {})
  
  if #marks > 0 then
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  else
    update_virtual_text()
  end
end

function M.show()
  update_virtual_text()
end

function M.hide()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

return M