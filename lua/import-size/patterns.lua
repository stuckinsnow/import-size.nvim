-- Language-specific import patterns for detecting import statements
local M = {}

M.import_patterns = {
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

function M.extract_import_path(line)
  for _, pattern in ipairs(M.import_patterns) do
    local match = string.match(line, pattern)
    if match then
      return match
    end
  end
  return nil
end

return M