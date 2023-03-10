--[[ via https://github.com/romgrk/barbar.nvim/blob/065c6d792a2a3aaf67a754ccd46800c8d1964812/lua/bufferline/render.lua ]]

local M = {}

local fnamemodify = vim.fn.fnamemodify
local get_hl_by_name = vim.api.nvim_get_hl_by_name
local list_slice = vim.list_slice
local set_hl = vim.api.nvim_set_hl
local hlexists = vim.fn.hlexists

--- Generate a color.
--- @param groups string[] the groups to source the color from.
--- @param attribute string where to look for the color.
--- @param default integer|string a color name (`string`), GUI hex (`string`), or cterm color code (`integer`).
--- @param guicolors boolean if `true`, look for GUI values. Else, look for `cterm`.
--- @return integer|string color
local function attribute_or_default(groups, attribute, default, guicolors)
    for _, group in ipairs(groups) do
        if hlexists(group) > 0 then
            local hl = get_hl_by_name(group, guicolors)
            if hl[attribute] then
                return guicolors and ('#%06x'):format(hl[attribute]) or hl[attribute]
            end
        end
    end

    return default
end

--- Return the index of element `n` in `list.
--- @generic T
--- @param list T[]
--- @param t T
--- @return nil|integer index
local function index_of(list, t)
    for i, value in ipairs(list) do
        if value == t then
            return i
        end
    end
    return nil
end

--- @param path string
--- @return string relative_path
local function relative(path)
    return fnamemodify(path, ':~:.')
end

_m = {
    --- @param path string
    --- @param hide_extension? boolean if `true`, exclude the extension of the file in the basename
    --- @return string basename
    basename = function(path, hide_extension)
        local modifier = ':t'

        if hide_extension then
            modifier = modifier .. ':r'
        end

        return fnamemodify(path, modifier)
    end,

    --- Return whether element `n` is in a `list.
    --- @generic T
    --- @param list T[]
    --- @param t T
    --- @return boolean
    has = function(list, t)
        return index_of(list, t) ~= nil
    end,

    --- utilities for working with highlight groups.
    --- @class bufline.utils.hl
    hl = {
        --- @class barbar.utils.hl.group
        --- @field cterm integer|string
        --- @field gui string

        --- Generate a background color.
        --- @param groups string[] the groups to source the background color from.
        --- @param default string the background color to use if no `groups` have a valid background color.
        --- @param default_cterm? integer|string the color to use if no `groups` have a valid color and `termguicolors == false`.
        --- @return barbar.utils.hl.group color
        bg_or_default = function(groups, default, default_cterm)
            return {
                cterm = attribute_or_default(groups, 'background', default_cterm or default, false),
                gui = attribute_or_default(groups, 'background', default, true),
            }
        end,

        --- Generate a foreground color.
        --- @param groups string[] the groups to source the foreground color from.
        --- @param default string the foreground color to use if no `groups` have a valid foreground color.
        --- @param default_cterm? integer|string the color to use if no `groups` have a valid color and `termguicolors == false`.
        --- @return barbar.utils.hl.group color
        fg_or_default = function(groups, default, default_cterm)
            return {
                cterm = attribute_or_default(groups, 'foreground', default_cterm or default, false),
                gui = attribute_or_default(groups, 'foreground', default, true),
            }
        end,

        --- Set some highlight `group`'s default definition with respect to `&termguicolors`
        --- @param group string the name of the highlight group to set
        --- @param bg barbar.utils.hl.group
        --- @param fg barbar.utils.hl.group
        --- @param bold? boolean whether the highlight group should be bolded
        set = function(group, bg, fg, bold)
            set_hl(0, group, {
                bold = bold,

                bg = bg.gui,
                fg = fg.gui,

                ctermbg = bg.cterm,
                ctermfg = fg.cterm,
            })
        end,

        --- Set the default highlight `group_name` as a link to `link_name`
        --- @param group_name string the name of the group to by-default be linked to `link_name`
        --- @param link_name string the name of the group to by-default link `group_name` to
        set_default_link = function(group_name, link_name)
            set_hl(0, group_name, { default = true, link = link_name })
        end,
    },

    index_of = index_of,

    --- @param path string
    --- @return boolean is_relative `true` if `path` is relative to the CWD
    is_relative_path = function(path)
        return relative(path) == path
    end,

    --- Run `vim.list_slice` on some `list`, `index`ed from the end of the list.
    --- @generic T
    --- @param list T[]
    --- @param index_from_end number
    --- @return T[] sliced
    list_slice_from_end = function(list, index_from_end)
        return list_slice(list, #list - index_from_end + 1)
    end,

    relative = relative,

    --- Reverse the order of elements in some `list`.
    --- @generic T
    --- @param list T[]
    --- @return T[] reversed
    reverse = function(list)
        local reversed = {}
        while #reversed < #list do
            reversed[#reversed + 1] = list[#list - #reversed]
        end
        return reversed
    end,
}

function M.hl_buffer_icon(buffer_status, icon_hl)
    _m.hl.set(
            icon_hl .. buffer_status,
            _m.hl.bg_or_default({ 'BufLineFill' }, 'none'),
            _m.hl.fg_or_default({ icon_hl }, 'none')
    )
end

--- Create valid `&tabline` syntax which highlights the next item in the tabline with the highlight `group` specified.
--- @param group string
--- @return string syntax
function M.hl_tabline(group)
    return '%#' .. group .. '#'
end

--- @class Group
--- @field hl string
--- @field str string

--- format group
--- @param group Group
function M.format(group)
    return group.hl .. group.str:gsub('%%', '%%%%')
end

--- @param groups Group[]
function M.format_groups(groups)
    local result = ''

    for _, group in ipairs(groups) do
        -- NOTE: We have to escape the text in case it contains '%', which is a special character to the
        --       tabline.
        --       To escape '%', we make it '%%'. It just so happens that '%' is also a special character
        --       in Lua, so we have write '%%' to mean '%'.
        result = result .. M.format(group)
    end

    return result
end

function M.check_hl_nil(group)
    if group.hl == nil then
        group.hl = ''
    end
    group.hl = M.hl_tabline(group.hl)
    return group
end

M.hl = _m.hl

return M