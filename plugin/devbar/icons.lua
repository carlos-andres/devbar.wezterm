local wezterm = require('wezterm')

local M = {}

local icons = {
  workspace = {
    nerd = wezterm.nerdfonts.md_view_dashboard,
    ascii = '[W]',
  },
  mode_copy = {
    nerd = wezterm.nerdfonts.md_content_copy,
    ascii = '[COPY]',
  },
  mode_search = {
    nerd = wezterm.nerdfonts.md_magnify,
    ascii = '[SEARCH]',
  },
  mode_leader = {
    nerd = wezterm.nerdfonts.oct_rocket,
    ascii = '[*]',
  },
  zoom = {
    nerd = wezterm.nerdfonts.md_arrow_expand_all,
    ascii = '[Z]',
  },
  git = {
    nerd = wezterm.nerdfonts.dev_git_branch,
    ascii = '<>',
  },
  nodejs = {
    nerd = wezterm.nerdfonts.md_nodejs,
    ascii = '[node]',
  },
  php = {
    nerd = wezterm.nerdfonts.md_language_php,
    ascii = '[php]',
  },
  python = {
    nerd = wezterm.nerdfonts.md_language_python,
    ascii = '[py]',
  },
  go = {
    nerd = wezterm.nerdfonts.md_language_go,
    ascii = '[go]',
  },
  clock = {
    nerd = wezterm.nerdfonts.md_clock_outline,
    ascii = '[T]',
  },
  ssh = {
    nerd = wezterm.nerdfonts.md_server,
    ascii = '[SSH]',
  },
}

---@param name string
---@param use_ascii boolean
---@return string
function M.get(name, use_ascii)
  local icon = icons[name]

  if not icon then
    return ''
  end

  if use_ascii then
    return icon.ascii or ''
  end

  return icon.nerd or icon.ascii or ''
end

---@return table
function M.list()
  local names = {}
  for name, _ in pairs(icons) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

return M
