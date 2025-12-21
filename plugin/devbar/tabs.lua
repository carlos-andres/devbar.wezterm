local util = require('devbar.util')
local icons = require('devbar.icons')
local cache = require('devbar.cache')

local M = {}

local function join_parts(separator, parts)
  local result = ''
  for i, part in ipairs(parts) do
    if i > 1 then
      result = result .. separator
    end
    result = result .. part
  end
  return result
end

---@param tab table
---@param config table
---@param palette table
---@return table
function M.format_tab(tab, config, palette)
  local tab_index = tab.tab_index + 1

  local domain_name = tab.active_pane and tab.active_pane.domain_name or 'local'
  local is_ssh = util.is_ssh(domain_name)

  local display_name

  if is_ssh then
    local ssh_alias = util.get_hostname(domain_name)
    local user = tab.active_pane and tab.active_pane.user_vars and tab.active_pane.user_vars.USER or 'user'

    if ssh_alias then
      local cache_key = 'ssh_config:' .. ssh_alias
      local ssh_config = cache.get_or_fetch(cache_key, config.ssh_cache_ttl or 60, function()
        return util.get_ssh_config(ssh_alias)
      end)

      if ssh_config and ssh_config.hostname and ssh_config.user then
        display_name = ssh_config.user .. '@' .. ssh_config.hostname
      else
        display_name = user .. '@' .. ssh_alias
      end
    else
      local process = tab.active_pane and tab.active_pane.foreground_process_name or ''
      local process_name = util.basename(process)
      display_name = process_name ~= '' and process_name or 'ssh'
    end
  else
    local cwd = tab.active_pane and util.get_cwd(tab.active_pane) or ''
    display_name = util.basename(cwd)
    if display_name == '' then
      display_name = '~'
    end
  end

  if config.truncate and config.truncate.cwd then
    display_name = util.truncate(display_name, config.truncate.cwd)
  end

  local is_zoomed = false
  if tab.panes then
    for _, pane in ipairs(tab.panes) do
      if pane.is_zoomed then
        is_zoomed = true
        break
      end
    end
  end

  local title_parts = { tostring(tab_index) }

  if is_ssh then
    local ssh_icon = icons.get('ssh', config.use_ascii_icons)
    if ssh_icon ~= '' then
      table.insert(title_parts, ssh_icon)
    end
  end

  table.insert(title_parts, display_name)

  if is_zoomed and config.segments and config.segments.zoom and config.segments.zoom.enabled then
    local zoom_icon = icons.get('zoom', config.use_ascii_icons)
    if zoom_icon ~= '' then
      table.insert(title_parts, zoom_icon)
    end
  end

  local title = join_parts(' ', title_parts)

  if config.truncate and config.truncate.tab then
    title = util.truncate(title, config.truncate.tab)
  end

  local fg_color = tab.is_active and palette.active_tab_fg or palette.inactive_tab_fg
  local bg_color = palette.tab_bg

  return {
    { Background = { Color = bg_color } },
    { Foreground = { Color = fg_color } },
    { Text = util.space(title, 1, 1) },
  }
end

return M
