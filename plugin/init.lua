local wezterm = require('wezterm')

local M = {}

local function safe_init()
  local separator = package.config:sub(1, 1) == '\\' and '\\' or '/'

  local plugin_list = wezterm.plugin.list()
  if not plugin_list or #plugin_list == 0 then
    wezterm.log_error('devbar: wezterm.plugin.list() returned empty')
    return nil, 'No plugins found'
  end

  local plugin_dir = plugin_list[1].plugin_dir
  local lua_path = plugin_dir .. separator .. 'plugin' .. separator .. '?.lua'

  package.path = package.path .. ';' .. lua_path

  local modules = {}
  local module_names = { 'config', 'theme', 'tabs', 'util', 'icons', 'git', 'direnv_helper', 'runtime' }

  for _, name in ipairs(module_names) do
    local full_name = 'devbar.' .. name
    local success, result = pcall(require, full_name)
    if success then
      modules[name] = result
    else
      wezterm.log_error('devbar: failed to load module:', full_name, ':', result)
      return nil, 'Failed to load module: ' .. full_name .. '\n' .. tostring(result)
    end
  end

  return modules, nil
end

local modules, init_error = safe_init()

local opts = {}
local palette = {}

---@param wezterm_config table
---@param user_opts table|nil
function M.apply_to_config(wezterm_config, user_opts)
  if init_error then
    wezterm.log_error('devbar: Initialization failed, continuing without devbar -', init_error)
    return
  end

  if not modules then
    wezterm.log_error('devbar: Modules not loaded, cannot apply config')
    return
  end

  local success, err = pcall(function()
    opts = modules.config.setup(user_opts)
    palette = modules.theme.get_colors(wezterm_config, opts.colors)
    modules.theme.apply_to_config(wezterm_config, palette)

    wezterm_config.use_fancy_tab_bar = false
    wezterm_config.tab_bar_at_bottom = (opts.position == 'bottom')
    wezterm_config.tab_max_width = opts.truncate.tab
  end)

  if not success then
    wezterm.log_error('devbar: Configuration failed, using default tab bar -', err)
  end
end

if modules then
  wezterm.on('format-tab-title', function(tab)
    local success, result = pcall(function()
      return modules.tabs.format_tab(tab, opts, palette)
    end)

    if not success then
      wezterm.log_error('devbar: format-tab-title failed:', result)
      return tostring(tab.tab_index + 1)
    end

    return result
  end)

  wezterm.on('update-status', function(window, pane)
    local success, err = pcall(function()
      local config_opts = opts
      local colors = palette

      local cwd = modules.util.get_cwd(pane)

      local left_cells = {
        { Background = { Color = colors.bg or 'transparent' } },
      }

      table.insert(left_cells, { Text = string.rep(' ', config_opts.padding.left) })

      if config_opts.segments.workspace.enabled then
        local workspace_icon = modules.icons.get('workspace', config_opts.use_ascii_icons)
        local workspace_name = window:active_workspace()

        table.insert(left_cells, { Foreground = { Color = colors.workspace } })
        table.insert(left_cells, { Text = workspace_icon .. ' ' .. workspace_name })
      end

      if config_opts.segments.mode.enabled then
        local mode_text = nil
        local mode_color = colors.mode_normal

        local key_table = window:active_key_table()
        if key_table then
          if key_table == 'copy_mode' then
            mode_text = 'COPY'
            mode_color = colors.mode_active
          elseif key_table == 'search_mode' then
            mode_text = 'SEARCH'
            mode_color = colors.mode_active
          else
            mode_text = key_table:match('^(%w+)'):upper()
            mode_color = colors.mode_active
          end
        end

        if window:leader_is_active() then
          local leader_icon = modules.icons.get('mode_leader', config_opts.use_ascii_icons)
          mode_text = leader_icon
          mode_color = colors.mode_active
        end

        if mode_text then
          table.insert(left_cells, { Text = config_opts.divider })
          table.insert(left_cells, { Foreground = { Color = mode_color } })
          table.insert(left_cells, { Text = mode_text })
        end
      end

      window:set_left_status(wezterm.format(left_cells))

      local right_cells = {
        { Background = { Color = colors.bg or 'transparent' } },
      }

      local segments = {}

      if config_opts.segments.git.enabled and cwd ~= '' then
        local branch = modules.git.get_branch(cwd, config_opts.cache_ttl, config_opts.truncate.branch)
        if branch then
          local git_icon = modules.icons.get('git', config_opts.use_ascii_icons)
          table.insert(segments, {
            text = git_icon .. ' ' .. branch,
            color = colors.git,
          })
        end
      end

      if config_opts.segments.runtimes.enabled and cwd ~= '' then
        local runtimes = modules.runtime.detect_runtimes(cwd, config_opts.cache_ttl, config_opts.use_ascii_icons)
        for _, rt in ipairs(runtimes) do
          table.insert(segments, {
            text = rt.icon .. ' ' .. rt.version,
            color = colors.runtime,
          })
        end
      end

      if config_opts.segments.datetime.enabled then
        local time_icon = modules.icons.get('clock', config_opts.use_ascii_icons)
        local time_str = wezterm.time.now():format(config_opts.segments.datetime.format)
        table.insert(segments, {
          text = time_icon .. ' ' .. time_str,
          color = colors.datetime,
        })
      end

      if config_opts.segments.ssh.enabled then
        local domain_name = pane:get_domain_name()
        if modules.util.is_ssh(domain_name) then
          local hostname = modules.util.get_hostname(domain_name)
          if hostname then
            local ssh_icon = modules.icons.get('ssh', config_opts.use_ascii_icons)
            table.insert(segments, {
              text = ssh_icon .. ' ' .. hostname,
              color = colors.ssh,
            })
          end
        end
      end

      for i, segment in ipairs(segments) do
        if i > 1 then
          table.insert(right_cells, { Foreground = { Color = colors.divider } })
          table.insert(right_cells, { Text = config_opts.divider })
        end
        table.insert(right_cells, { Foreground = { Color = segment.color } })
        table.insert(right_cells, { Text = segment.text })
      end

      table.insert(right_cells, { Text = string.rep(' ', config_opts.padding.right) })

      window:set_right_status(wezterm.format(right_cells))
    end)

    if not success then
      wezterm.log_error('devbar: update-status failed:', err)
    end
  end)
else
  wezterm.log_error('devbar: Modules failed to load, event handlers not registered -', init_error or 'Unknown error')
end

return M
