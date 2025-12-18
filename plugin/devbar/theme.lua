local M = {}

-- Molokai fallback palette when user theme colors cannot be detected
local molokai = {
  bg = '#1B1D1E',
  fg = '#F8F8F2',
  ansi = {
    '#403D3D', -- black
    '#F92672', -- red
    '#A6E22E', -- green
    '#E6DB74', -- yellow
    '#66D9EF', -- blue
    '#FD5FF0', -- magenta
    '#A1EFE4', -- cyan
    '#F8F8F2', -- white
  },
  brights = {
    '#727072', -- bright black
    '#FD5FF0', -- bright red
    '#A6E22E', -- bright green
    '#FEED6C', -- bright yellow
    '#66D9EF', -- bright blue
    '#FD5FF0', -- bright magenta
    '#A1EFE4', -- bright cyan
    '#F8F8F0', -- bright white
  },
}

---@param wezterm_config table
---@param user_colors table|nil
---@return table
function M.get_colors(wezterm_config, user_colors)
  local palette = {}

  local resolved_palette = nil
  if wezterm_config then
    local success, config = pcall(function()
      return wezterm_config.resolved_palette
    end)
    if success and config then
      resolved_palette = config
    end
  end

  local base_palette = resolved_palette or molokai

  palette.bg = base_palette.bg or molokai.bg
  palette.fg = base_palette.fg or molokai.fg

  local ansi = base_palette.ansi or molokai.ansi
  local brights = base_palette.brights or molokai.brights

  palette.active_tab_fg = ansi[6] or molokai.ansi[6]
  palette.inactive_tab_fg = ansi[8] or molokai.ansi[8]
  palette.tab_bg = 'transparent'

  palette.workspace = ansi[7] or molokai.ansi[7]
  palette.mode_normal = ansi[7] or molokai.ansi[7]
  palette.mode_active = ansi[2] or molokai.ansi[2]
  palette.zoom = ansi[4] or molokai.ansi[4]

  palette.git = ansi[3] or molokai.ansi[3]
  palette.runtime = ansi[5] or molokai.ansi[5]
  palette.datetime = ansi[4] or molokai.ansi[4]
  palette.ssh = ansi[2] or molokai.ansi[2]

  palette.divider = brights[1] or molokai.brights[1]

  if user_colors and type(user_colors) == 'table' then
    for k, v in pairs(user_colors) do
      palette[k] = v
    end
  end

  return palette
end

---@param wezterm_config table
---@param palette table
function M.apply_to_config(wezterm_config, palette)
  if not wezterm_config then
    return
  end

  wezterm_config.colors = wezterm_config.colors or {}
  wezterm_config.colors.tab_bar = wezterm_config.colors.tab_bar or {}

  wezterm_config.colors.tab_bar.background = palette.tab_bg
  wezterm_config.colors.tab_bar.active_tab = {
    bg_color = palette.tab_bg,
    fg_color = palette.active_tab_fg,
  }
  wezterm_config.colors.tab_bar.inactive_tab = {
    bg_color = palette.tab_bg,
    fg_color = palette.inactive_tab_fg,
  }
  wezterm_config.colors.tab_bar.inactive_tab_hover = {
    bg_color = palette.tab_bg,
    fg_color = palette.active_tab_fg,
  }
  wezterm_config.colors.tab_bar.new_tab = {
    bg_color = palette.tab_bg,
    fg_color = palette.inactive_tab_fg,
  }
  wezterm_config.colors.tab_bar.new_tab_hover = {
    bg_color = palette.tab_bg,
    fg_color = palette.active_tab_fg,
  }
end

return M
