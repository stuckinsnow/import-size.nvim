-- File path resolution and line counting utilities
local M = {}

function M.is_local_file(import_path)
  return string.sub(import_path, 1, 1) == '.' or string.sub(import_path, 1, 1) == '/'
end

function M.resolve_file_path(import_path, current_dir)
  if not M.is_local_file(import_path) then
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

function M.count_lines(file_path)
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

return M