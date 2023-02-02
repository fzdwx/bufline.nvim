local M = {}
local util = require("bufline.util")
local fn = vim.fn
local api = vim.api
local hlexists = vim.fn.hlexists
local hl_groups = {}
local fill_hl = "BufLineFill"
local title_hl = "BufLineTitle"
local line_hl = "BufLine"
local set_hl = vim.api.nvim_set_hl

--- @return Group
M.folder = function(count)
	local str = "📁 "
	if count > 0 then
		str = "📂 "
	end
	return {
		str = str,
		hl = "BufLineFolder",
	}
end

--- @return Group
M.dirName = function(bufnr)
	local name = api.nvim_eval("$PWD == $HOME ? '~' : substitute($PWD, '\\v(.*/)*', '', 'g')")
	return {
		str = name .. " ",
		hl = fill_hl,
	}
end

--- @return Group
M.title = function(bufnr, buffer_status)
	local file = vim.fn.bufname(bufnr)
	local buftype = vim.fn.getbufvar(bufnr, "&buftype")
	local filetype = vim.fn.getbufvar(bufnr, "&filetype")

	local name

	if buftype == "help" then
		name = "help:" .. vim.fn.fnamemodify(file, ":t:r")
	elseif buftype == "quickfix" then
		name = "quickfix"
	elseif filetype == "TelescopePrompt" then
		name = "Telescope"
	elseif filetype == "git" then
		name = "Git"
	elseif filetype == "fugitive" then
		name = "Fugitive"
	elseif file:sub(file:len() - 2, file:len()) == "FZF" then
		name = "FZF"
	elseif buftype == "terminal" then
		local _, mtch = string.match(file, "term:(.*):(%a+)")
		name = mtch ~= nil and mtch or vim.fn.fnamemodify(vim.env.SHELL, ":t")
	elseif file == "" then
		name = "[No Name]"
	else
		name = vim.fn.pathshorten(vim.fn.fnamemodify(file, ":p:~:t"))
	end

	return {
		str = " " .. name .. M.modified(bufnr) .. " ",
		hl = title_hl .. buffer_status,
	}
end

M.modified = function(bufnr)
	return vim.fn.getbufvar(bufnr, "&modified") == 1 and "[+] " or ""
end

--- @return Group
M.devicon = function(bufnr, buffer_status, isSelected)
	local icon, icon_hl
	local file = vim.fn.bufname(bufnr)
	local buftype = vim.fn.getbufvar(bufnr, "&buftype")
	local filetype = vim.fn.getbufvar(bufnr, "&filetype")
	local devicons = require("nvim-web-devicons")

	if filetype == "TelescopePrompt" then
		icon, icon_hl = devicons.get_icon("telescope")
	elseif filetype == "fugitive" then
		icon, icon_hl = devicons.get_icon("git")
	elseif filetype == "vimwiki" then
		icon, icon_hl = devicons.get_icon("markdown")
	elseif buftype == "terminal" then
		icon, icon_hl = devicons.get_icon("zsh")
	else
		icon, icon_hl = devicons.get_icon(file, vim.fn.expand("#" .. bufnr .. ":e"), { default = true })
	end

	if icon_hl and hlexists(icon_hl .. buffer_status) < 1 then
		util.hl_buffer_icon(buffer_status, icon_hl)
		hl_groups[#hl_groups + 1] = { buffer_status = buffer_status, icon_hl = icon_hl }
	end

	return {
		str = icon,
		--hl = isSelected and util.hl_tabline(icon_hl .. buffer_status) or util.hl_tabline("BufferIconNoColor")
		hl = icon_hl .. buffer_status,
	}
end

M.separator = function()
	return {
		str = "",
		hl = fill_hl,
	}
end

M.cell = function(index, current)
	local isSelected = current == index
	local buffer_status = isSelected and "Sel" or "NoSel"

	local icon = util.check_hl_nil(M.devicon(index, buffer_status, isSelected))
	local name = util.check_hl_nil(M.title(index, buffer_status))
	local separator = util.check_hl_nil(M.separator(index))

	local empty = util.check_hl_nil({ str = " ", hl = fill_hl })

	local cells = {
		empty,
		icon,
		name,
		separator,
	}

	return util.format_groups(cells)

	--return hl .. '%T' .. ' ' ..
	--        M.devicon(index, isSelected) .. '%#TabLineSel#' ..
	--        M.title(index) .. ' ' ..
	--        M.modified(index) ..
	--        M.separator(index)
end

M.bufline = function()
	local current = fn.bufnr("%")
	local last = fn.bufnr("$")
	local header = {
		util.check_hl_nil(M.folder(last)),
		util.check_hl_nil(M.dirName(current)),
		util.check_hl_nil(M.separator()),
	}
	local line = util.format_groups(header)

	--[[ 每一个buffer ]]
	for _, i in pairs(api.nvim_list_bufs()) do
		if fn.bufexists(i) == 1 and fn.buflisted(i) == 1 then
			line = line .. M.cell(i, current)
		end
	end

	line = line .. "%#" .. fill_hl .. "#%="
	-- if last > 1 then
	-- line = line .. "%#" .. line_hl .. "#%999XX"
	-- end

	return line
end

local function init(opts)
	opts = opts or {}
	if opts.title then
		M.title = opts.title
	end
	if opts.modified then
		M.modified = opts.modified
	end
	if opts.devicon then
		M.devicon = opts.devicon
	end
	if opts.separator then
		M.separator = opts.separator
	end
	if opts.cell then
		M.cell = opts.cell
	end
	if opts.bufline then
		M.bufline = opts.bufline
	end
	if opts.folder then
		M.folder = opts.folder
	end
	if opts.dirName then
		M.dirName = opts.dirName
	end
end

---@class BufLineOpts
---@field title function:Group
---@field modified function:string
---@field devicon function:Group
---@field separator function:Group
---@field cell  function string
---@field bufline function string
---@field folder function Group
---@field dirName function string

---@param opts BufLineOpts
local setup = function(opts)
	init(opts)
	set_hl(0, "BufLineFolder", { default = true, bg = "", fg = "" })
	vim.opt.tabline = "%!v:lua.require'bufline'.show()"
	vim.cmd("set showtabline=2")
end

return {
	setup = setup,
	show = M.bufline,
}
