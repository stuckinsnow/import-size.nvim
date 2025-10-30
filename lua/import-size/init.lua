-- Main plugin entry point
local highlights = require("import-size.highlights")
local display = require("import-size.display")

local M = {}

function M.setup(opts)
	opts = opts or {}

	highlights.setup_highlights()

	-- Create user commands
	vim.api.nvim_create_user_command("ImportSizeToggle", function()
		M.toggle()
	end, {})

	vim.api.nvim_create_user_command("ImportSizeShow", function()
		M.show()
	end, {})

	vim.api.nvim_create_user_command("ImportSizeHide", function()
		M.hide()
	end, {})

	-- Auto-update on buffer events
	vim.api.nvim_create_autocmd(
		{ "BufReadPost", "BufWritePost", "BufWritePre", "TextChanged", "TextChangedI", "InsertLeave" },
		{
			callback = function()
				vim.schedule(display.update_virtual_text)
			end,
		}
	)

	-- Also update when any buffer is written (to catch changes to imported files)
	vim.api.nvim_create_autocmd("BufWritePost", {
		callback = function()
			-- Update all visible buffers since an imported file might have changed
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local buf = vim.api.nvim_win_get_buf(win)
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(buf) then
						-- Use nvim_buf_call to update the buffer without switching current buffer
						-- This avoids issues with winfixbuf
						vim.api.nvim_buf_call(buf, function()
							display.update_virtual_text(buf)
						end)
					end
				end)
			end
		end,
	})

	-- Initial update for current buffer
	vim.schedule(display.update_virtual_text)
end

function M.toggle()
	display.toggle_virtual_text()
end

function M.show()
	display.update_virtual_text()
end

function M.hide()
	display.clear_virtual_text()
end

return M

