# import-size.nvim

A filetype-agnostic Neovim plugin that displays file sizes and line counts for imported files with color-coded highlighting. Shows bundle sizes for npm packages and both file size + line counts for local files.

<img width="1562" height="156" alt="2025-07-22_13-45" src="https://github.com/user-attachments/assets/64dc47c5-5b6c-4d6c-807d-eac0f042baa6" />

## Features

- **Dual display modes**:
  - **Local files**: Shows both file size and line count: `(2.9KB, 205 lines)`
  - **npm packages**: Shows bundle size only: `(13.8KB)`
- **Smart path resolution**: 
  - Supports TypeScript/JavaScript path aliases (e.g., `@/components/Button`)
  - Automatically parses `tsconfig.json` and `jsconfig.json` for path mappings
  - Works with pnpm, npm, and yarn package managers
- **Filetype agnostic**: Works with JavaScript/TypeScript, Python, Go, Rust, Java, C/C++, and more
- **Color-coded highlighting**: Different colors based on line count
  - Green (ImportSize100): Files with ≤100 lines
  - Yellow (ImportSize200): Files with ≤200 lines
  - Orange (ImportSize400): Files with ≤400 lines
  - Red (ImportSize500): Files with 500+ lines
- **Performance optimized**: 
  - Caching for npm package sizes
  - No line counting for large npm packages
- **Auto-enabled**: Works immediately after setup, no manual activation needed
- **Real-time updates**: Updates when files are saved or changed

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'your-username/import-size.nvim',
  config = function()
    require('import-size').setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'your-username/import-size.nvim',
  config = function()
    require('import-size').setup()
  end
}
```

## Usage

### Commands

- `:ImportSizeToggle` - Toggle the plugin on/off
- `:ImportSizeShow` - Enable import size display
- `:ImportSizeHide` - Disable import size display

### Lua API

```lua
local import_size = require('import-size')

-- Setup the plugin
import_size.setup()

-- Toggle display
import_size.toggle()

-- Show import sizes
import_size.show()

-- Hide import sizes
import_size.hide()
```

## Configuration

The plugin works out of the box, but you can customize the highlight colors:

```lua
-- In your colorscheme or init.lua
vim.api.nvim_set_hl(0, 'ImportSize', { fg = '#6b7280' })     -- Gray for file sizes
vim.api.nvim_set_hl(0, 'ImportSize100', { fg = '#22c55e' })  -- Green for ≤100 lines
vim.api.nvim_set_hl(0, 'ImportSize200', { fg = '#eab308' })  -- Yellow for ≤200 lines  
vim.api.nvim_set_hl(0, 'ImportSize400', { fg = '#f97316' })  -- Orange for ≤400 lines
vim.api.nvim_set_hl(0, 'ImportSize500', { fg = '#ef4444' })  -- Red for >400 lines

-- Or link to existing highlight groups
vim.api.nvim_set_hl(0, 'ImportSize', { link = 'Comment' })
vim.api.nvim_set_hl(0, 'ImportSize100', { link = 'String' })
vim.api.nvim_set_hl(0, 'ImportSize200', { link = 'WarningMsg' })
vim.api.nvim_set_hl(0, 'ImportSize400', { link = 'WarningMsg' })
vim.api.nvim_set_hl(0, 'ImportSize500', { link = 'ErrorMsg' })
```

## Supported Languages

The plugin automatically detects imports in:

- **JavaScript/TypeScript**: `import`, `require()`
- **Python**: `import`, `from ... import`
- **Go**: `import`
- **Rust**: `use`
- **Java**: `import`
- **C/C++**: `#include`
- **Ruby**: `require`, `require_relative`
- **PHP**: `require`, `require_once`, `include`, `include_once`
- **Lua**: `require()`

## How It Works

1. **Import Detection**: Scans the current buffer for import statements using language-specific patterns
2. **Path Classification**: Determines if import is a local file or npm package
3. **Path Resolution**: 
   - For local files: Resolves relative paths and TypeScript aliases (e.g., `@/`) using `tsconfig.json`
   - For npm packages: Locates packages in `node_modules` and finds main entry point
4. **Size Calculation**: 
   - Local files: Gets file size and counts lines
   - npm packages: Gets main file size only (cached for performance)
5. **Display**: Shows results as virtual text with color coding based on line count

## Examples

```javascript
// Local files - shows size + lines
import { Component } from "./components/Button.js"; // (1.2KB, 25 lines)
import utils from "./utils/helpers.js"; // (3.4KB, 127 lines) 
import { Footer } from "@/globals/Footer/Component"; // (2.9KB, 205 lines)

// npm packages - shows size only
import React from "react"; // (87.2KB)
import axios from "axios"; // (13.8KB)
import lodash from "lodash"; // (531KB)

// No size shown for packages not found
import { nonExistent } from "fake-package";
```

