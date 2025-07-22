" import-size.nvim - Show line counts for imported files
" Maintainer: Your Name

if exists('g:loaded_import_size')
  finish
endif
let g:loaded_import_size = 1

command! ImportSizeToggle lua require('import-size').toggle()
command! ImportSizeShow lua require('import-size').show()
command! ImportSizeHide lua require('import-size').hide()