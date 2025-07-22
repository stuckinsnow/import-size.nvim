# import-size.nvim

A filetype-agnostic Neovim plugin that shows line counts for imported local files with color-coded highlighting. Similar to import-cost but shows line counts instead of bundle sizes.

## Features

- **Local files only**: Shows line counts only for relative imports (starting with `./` or `../`), not external libraries
- **Filetype agnostic**: Works with JavaScript/TypeScript, Python, Go, Rust, Java, C/C++, and more
- **Color-coded highlighting**: Different colors based on file size
  - Green (ImportSize100): Files with ≤100 lines
  - Yellow (ImportSize200): Files with ≤200 lines
  - Orange (ImportSize400): Files with ≤400 lines
  - Red (ImportSize500): Files with 500+ lines
- **Inline display**: Shows `(200 lines)` at the end of import statements
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
vim.api.nvim_set_hl(0, 'ImportSize100', { fg = '#22c55e' })  -- Green
vim.api.nvim_set_hl(0, 'ImportSize200', { fg = '#eab308' })  -- Yellow
vim.api.nvim_set_hl(0, 'ImportSize400', { fg = '#f97316' })  -- Orange
vim.api.nvim_set_hl(0, 'ImportSize500', { fg = '#ef4444' })  -- Red

-- Or link to existing highlight groups
vim.api.nvim_set_hl(0, 'ImportSize100', { link = 'Comment' })
vim.api.nvim_set_hl(0, 'ImportSize200', { link = 'Comment' })
vim.api.nvim_set_hl(0, 'ImportSize400', { link = 'Comment' })
vim.api.nvim_set_hl(0, 'ImportSize500', { link = 'Comment' })
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

1. Scans the current buffer for import statements using language-specific patterns
2. Filters to only process local/relative imports (starting with `./`, `../`, or `/`)
3. Resolves import paths to actual files on disk with extension detection
4. Counts lines in the imported files
5. Displays `(X lines)` as virtual text with color coding based on line count ranges

## Examples

```javascript
import { Component } from "./components/Button.js"; // (15 lines)
import utils from "./utils/helpers.js"; // (127 lines)
import config from "./config/settings.js"; // (8 lines)
import axios from "axios"; // No count shown (external library)
```

