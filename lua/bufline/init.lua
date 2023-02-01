local M = {}
local util = require 'bufline.util'
local fn = vim.fn
local hlexists = vim.fn.hlexists
local hl_groups = {}
local empty_hl = util.hl_tabline("")

--- @return Group
M.dirName = function(bufnr)
    local file = fn.bufname(bufnr)
    local dir = fn.fnamemodify(file, ':h')
    local dirName = fn.fnamemodify(dir, ':t')
    return {
        str = dirName,
    }
end

--- @return Group
M.title = function(bufnr, buffer_status)
    local file = vim.fn.bufname(bufnr)
    local buftype = vim.fn.getbufvar(bufnr, '&buftype')
    local filetype = vim.fn.getbufvar(bufnr, '&filetype')

    local name

    if buftype == 'help' then
        name = 'help:' .. vim.fn.fnamemodify(file, ':t:r')
    elseif buftype == 'quickfix' then
        name = 'quickfix'
    elseif filetype == 'TelescopePrompt' then
        name = 'Telescope'
    elseif filetype == 'git' then
        name = 'Git'
    elseif filetype == 'fugitive' then
        name = 'Fugitive'
    elseif file:sub(file:len() - 2, file:len()) == 'FZF' then
        name = 'FZF'
    elseif buftype == 'terminal' then
        local _, mtch = string.match(file, "term:(.*):(%a+)")
        name = mtch ~= nil and mtch or vim.fn.fnamemodify(vim.env.SHELL, ':t')
    elseif file == '' then
        name = '[No Name]'
    else
        name = vim.fn.pathshorten(vim.fn.fnamemodify(file, ':p:~:t'))
    end

    return {
        str = " " .. name .. " ",
        hl = "BufLineTitle" .. buffer_status
    }

end

M.modified = function(bufnr)
    return vim.fn.getbufvar(bufnr, '&modified') == 1 and '[+] ' or ''
end

--- @return Group
M.devicon = function(bufnr, buffer_status, isSelected)
    local icon, icon_hl
    local file = vim.fn.bufname(bufnr)
    local buftype = vim.fn.getbufvar(bufnr, '&buftype')
    local filetype = vim.fn.getbufvar(bufnr, '&filetype')
    local devicons = require 'nvim-web-devicons'

    if filetype == 'TelescopePrompt' then
        icon, icon_hl = devicons.get_icon('telescope')
    elseif filetype == 'fugitive' then
        icon, icon_hl = devicons.get_icon('git')
    elseif filetype == 'vimwiki' then
        icon, icon_hl = devicons.get_icon('markdown')
    elseif buftype == 'terminal' then
        icon, icon_hl = devicons.get_icon('zsh')
    else
        icon, icon_hl = devicons.get_icon(file, vim.fn.expand('#' .. bufnr .. ':e'), { default = true })
    end

    if icon_hl and hlexists(icon_hl .. buffer_status) < 1 then
        util.hl_buffer_icon(buffer_status, icon_hl)
        hl_groups[#hl_groups + 1] = { buffer_status = buffer_status, icon_hl = icon_hl }
    end

    return {
        str = icon,
        --hl = isSelected and util.hl_tabline(icon_hl .. buffer_status) or util.hl_tabline("BufferIconNoColor")
        hl = icon_hl .. buffer_status
    }
end

M.separator = function(index)
    return {
        str = '',
    }
end

M.cell = function(index, current)
    local isSelected = current == index
    local buffer_status = isSelected and 'Sel' or 'NoSel'

    local icon = util.check_hl_nil(M.devicon(index, buffer_status, isSelected))
    local name = util.check_hl_nil(M.title(index, buffer_status))
    local separator = util.check_hl_nil(M.separator(index))

    local empty = { str = " ", hl = empty_hl }

    local cells = {
        empty,
        icon,
        name,
        separator,
    }

    return util.groups_to_string(cells)

    --return hl .. '%T' .. ' ' ..
    --        M.devicon(index, isSelected) .. '%#TabLineSel#' ..
    --        M.title(index) .. ' ' ..
    --        M.modified(index) ..
    --        M.separator(index)

end

M.bufline = function()
    local current = fn.bufnr('%')
    local line = util.format(util.check_hl_nil(M.dirName(current)))
    for _, i in pairs(vim.api.nvim_list_bufs()) do
        if fn.bufexists(i) == 1 and fn.buflisted(i) == 1 then
            line = line .. M.cell(i, current)
        end
    end
    line = line .. '%#BufLineFill#%='
    if vim.fn.tabpagenr('$') > 1 then
        line = line .. '%#BufLine#%999XX'
    end
    return line
end

local setup = function(opts)
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
    if opts.tabline then
        M.tabline = opts.tabline
    end

    vim.opt.tabline = '%!v:lua.require\'bufline\'.show()'
    vim.cmd("set showtabline=2")
end

return {
    setup = setup,
    show = M.bufline,
}
