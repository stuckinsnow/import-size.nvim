-- Virtual text display and buffer management
local patterns = require("import-size.patterns")
local resolver = require("import-size.resolver")
local highlights = require("import-size.highlights")

local M = {}

local ns_id = vim.api.nvim_create_namespace("import_size")

function M.update_virtual_text(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local current_file = vim.api.nvim_buf_get_name(bufnr)
	local current_dir = vim.fn.fnamemodify(current_file, ":h")

	-- Clear existing virtual text
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	for i, line in ipairs(lines) do
		local import_path = patterns.extract_import_path(line)
		if import_path then
			local info = resolver.get_import_info(import_path, current_dir)

			if info.size > 0 or info.lines > 0 then
				local virt_text_parts = {}

				if info.size > 0 then
					if info.lines > 0 then
						-- Local file: (size, lines)
						table.insert(virt_text_parts, { " (", "ImportSize" })
						table.insert(virt_text_parts, { resolver.format_file_size(info.size), "ImportSize" })
						table.insert(virt_text_parts, { ", ", "ImportSize" })
						table.insert(
							virt_text_parts,
							{ info.lines .. " lines", highlights.get_highlight_group(info.lines) }
						)
						table.insert(virt_text_parts, { ")", "ImportSize" })
					else
						-- npm package: (size)
						table.insert(virt_text_parts, { " (", "ImportSize" })
						table.insert(virt_text_parts, { resolver.format_file_size(info.size), "ImportSize" })
						table.insert(virt_text_parts, { ")", "ImportSize" })
					end
				elseif info.lines > 0 then
					-- Only line count: (lines)
					local hl_group = highlights.get_highlight_group(info.lines)
					table.insert(virt_text_parts, { " (", hl_group })
					table.insert(virt_text_parts, { info.lines .. " lines", hl_group })
					table.insert(virt_text_parts, { ")", hl_group })
				end

				vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, 0, {
					virt_text = virt_text_parts,
					virt_text_pos = "eol",
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

