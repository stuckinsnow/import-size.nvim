-- File path resolution and line counting utilities
local M = {}

-- Cache for package sizes to avoid repeated calculations
local package_size_cache = {}

function M.is_local_file(import_path)
  -- Only @/ (not @anything else) is considered a local file alias
  return string.sub(import_path, 1, 1) == '.' or string.sub(import_path, 1, 1) == '/' or string.sub(import_path, 1, 2) == '@/'
end

function M.parse_tsconfig_paths(tsconfig_path)
  local file = io.open(tsconfig_path, 'r')
  if not file then return {} end
  
  local content = file:read('*all')
  file:close()
  
  local paths = {}
  -- Simple parsing for paths section
  local paths_section = string.match(content, '"paths"%s*:%s*{([^}]+)}')
  if paths_section then
    for alias, mapping in string.gmatch(paths_section, '"([^"]+)"%s*:%s*%[%s*"([^"]+)"%s*%]') do
      paths[alias] = mapping
    end
  end
  
  return paths
end

function M.resolve_path_alias(import_path, current_dir)
  if string.sub(import_path, 1, 2) == '@/' then
    -- Look for project root and tsconfig
    local root_markers = {'tsconfig.json', 'jsconfig.json', 'package.json', '.git'}
    local project_root = current_dir
    
    -- Walk up directory tree to find project root
    while project_root ~= '/' do
      for _, marker in ipairs(root_markers) do
        local marker_path = project_root .. '/' .. marker
        if vim.fn.filereadable(marker_path) == 1 then
          if marker == 'tsconfig.json' or marker == 'jsconfig.json' then
            -- Parse the config for path mappings
            local paths = M.parse_tsconfig_paths(marker_path)
            for alias, mapping in pairs(paths) do
              if alias == '@/*' then
                -- Remove the /* suffix and map the path
                local mapped_path = string.gsub(mapping, '/%*$', '')
                local resolved_path = project_root .. '/' .. mapped_path .. '/' .. string.sub(import_path, 3)
                return resolved_path
              end
            end
          end
          -- Found project root, use default mapping
          return project_root .. '/src/' .. string.sub(import_path, 3)
        elseif vim.fn.isdirectory(marker_path) == 1 then
          -- Found project root, use default mapping  
          return project_root .. '/src/' .. string.sub(import_path, 3)
        end
      end
      project_root = vim.fn.fnamemodify(project_root, ':h')
    end
    
    -- Final fallback
    return current_dir .. '/src/' .. string.sub(import_path, 3)
  end
  
  return import_path
end

function M.resolve_file_path(import_path, current_dir)
  if not M.is_local_file(import_path) then
    return nil
  end
  
  -- Handle path aliases
  import_path = M.resolve_path_alias(import_path, current_dir)
  
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

function M.get_file_size(file_path)
  if not file_path then return 0 end
  
  local stat = vim.loop.fs_stat(file_path)
  if not stat then return 0 end
  
  return stat.size
end

function M.format_file_size(size_bytes)
  if size_bytes < 1024 then
    return tostring(size_bytes) .. 'B'
  elseif size_bytes < 1024 * 1024 then
    return string.format('%.1fKB', size_bytes / 1024)
  else
    return string.format('%.1fMB', size_bytes / (1024 * 1024))
  end
end

function M.is_npm_package(import_path)
  return not M.is_local_file(import_path)
end

function M.extract_package_name(import_path)
  if M.is_local_file(import_path) then
    return nil
  end
  
  -- Handle scoped packages like @types/node
  if string.sub(import_path, 1, 1) == '@' then
    local slash_pos = string.find(import_path, '/', 2)
    if slash_pos then
      return string.sub(import_path, 1, slash_pos - 1)
    else
      return import_path
    end
  else
    -- Handle regular packages like lodash or lodash/debounce
    local slash_pos = string.find(import_path, '/')
    if slash_pos then
      return string.sub(import_path, 1, slash_pos - 1)
    else
      return import_path
    end
  end
end

function M.find_node_modules(start_dir)
  local dir = start_dir
  while dir ~= '/' do
    local node_modules = dir .. '/node_modules'
    if vim.fn.isdirectory(node_modules) == 1 then
      return node_modules
    end
    dir = vim.fn.fnamemodify(dir, ':h')
  end
  return nil
end

function M.get_package_size(import_path, current_dir)
  local package_name = M.extract_package_name(import_path)
  if not package_name then return 0 end
  
  -- Check cache first
  local cache_key = package_name .. ':' .. current_dir
  if package_size_cache[cache_key] then
    return package_size_cache[cache_key]
  end
  
  local node_modules = M.find_node_modules(current_dir)
  if not node_modules then
    package_size_cache[cache_key] = 0
    return 0
  end
  
  local package_dir = node_modules .. '/' .. package_name
  if vim.fn.isdirectory(package_dir) == 0 then
    package_size_cache[cache_key] = 0
    return 0
  end
  
  -- Get the main file from package.json
  local package_json = package_dir .. '/package.json'
  local main_file = 'index.js' -- default
  
  if vim.fn.filereadable(package_json) == 1 then
    local file = io.open(package_json, 'r')
    if file then
      local content = file:read('*all')
      file:close()
      
      -- Simple JSON parsing for main field (also try module, browser)
      local main_match = string.match(content, '"main"%s*:%s*"([^"]+)"')
      if not main_match then
        main_match = string.match(content, '"module"%s*:%s*"([^"]+)"')
      end
      if not main_match then
        main_match = string.match(content, '"browser"%s*:%s*"([^"]+)"')
      end
      if main_match then
        main_file = main_match
      end
    end
  end
  
  local main_path = package_dir .. '/' .. main_file
  local size = M.get_file_size(main_path)
  
  -- Cache the result
  package_size_cache[cache_key] = size
  return size
end

function M.get_import_info(import_path, current_dir)
  local file_path, file_size, line_count = nil, 0, 0
  
  if M.is_npm_package(import_path) then
    file_size = M.get_package_size(import_path, current_dir)
    line_count = 0 -- Don't count lines for npm packages to avoid performance hit
  else
    file_path = M.resolve_file_path(import_path, current_dir)
    if file_path then
      file_size = M.get_file_size(file_path)
      line_count = M.count_lines(file_path)
    end
  end
  
  return {
    path = file_path,
    size = file_size,
    lines = line_count,
    is_package = M.is_npm_package(import_path)
  }
end

return M