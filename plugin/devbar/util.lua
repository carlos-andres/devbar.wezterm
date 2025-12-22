local M = {}

---@param s string
---@return string
function M.trim(s)
  if type(s) ~= 'string' then
    return ''
  end
  return s:match('^%s*(.-)%s*$') or ''
end

---@param path string
---@return string
function M.basename(path)
  if type(path) ~= 'string' or path == '' then
    return ''
  end
  local name = path:match('[^/\\]*$')
  if name and name ~= '' then
    return name
  end
  return path
end

---@param s string
---@param max_len number
---@return string
function M.truncate(s, max_len)
  if type(s) ~= 'string' then
    return ''
  end
  if type(max_len) ~= 'number' or max_len < 1 then
    return s
  end
  if #s <= max_len then
    return s
  end
  return s:sub(1, max_len - 1) .. '…'
end

---Smart two-tier truncation: show full name if <=max_full, else show last max_short chars
---@param s string
---@param max_full number Maximum length to show full string (default 24)
---@param max_short number Maximum length for shortened version (default 8)
---@return string
function M.smart_truncate(s, max_full, max_short)
  if type(s) ~= 'string' then
    return ''
  end
  if type(max_full) ~= 'number' or max_full < 1 then
    max_full = 24
  end
  if type(max_short) ~= 'number' or max_short < 3 then
    max_short = 8
  end

  local len = #s

  -- If fits in full display, show it all
  if len <= max_full then
    return s
  end

  -- Otherwise, show last N characters with ellipsis
  if len <= max_short then
    return s
  end

  return '…' .. s:sub(-(max_short - 1))
end

---Smart directory name with parent context
---Shows parent/current if fits, otherwise just current, with ellipsis if needed
---@param path string Full path to directory
---@param max_width number Maximum width available (default 24)
---@return string Formatted directory name
function M.get_smart_dirname(path, max_width)
  if type(path) ~= 'string' or path == '' then
    return '~'
  end

  if type(max_width) ~= 'number' or max_width < 1 then
    max_width = 24
  end

  -- Remove trailing slash
  path = path:gsub('/$', '')

  -- Handle root path
  if path == '' or path == '/' then
    return '/'
  end

  -- Split path into parts
  local parts = {}
  for part in path:gmatch('[^/]+') do
    table.insert(parts, part)
  end

  local num_parts = #parts
  if num_parts == 0 then
    return '~'
  end

  local current = parts[num_parts]
  local parent = num_parts > 1 and parts[num_parts - 1] or nil

  -- Strategy 1: Try parent/current if we have a parent
  if parent then
    local combined = parent .. '/' .. current
    if #combined <= max_width then
      return combined
    end
  end

  -- Strategy 2: Just current directory
  if #current <= max_width then
    return current
  end

  -- Strategy 3: Current directory with ellipsis
  return current:sub(1, max_width - 1) .. '…'
end

---@param s string
---@param left_pad number
---@param right_pad number|nil
---@return string
function M.space(s, left_pad, right_pad)
  if type(s) ~= 'string' then
    return ''
  end
  if type(left_pad) ~= 'number' or left_pad < 0 then
    left_pad = 0
  end
  if type(right_pad) ~= 'number' or right_pad < 0 then
    right_pad = left_pad
  end

  local left_spaces = string.rep(' ', left_pad)
  local right_spaces = string.rep(' ', right_pad)

  return left_spaces .. s .. right_spaces
end

---@param t1 table
---@param t2 table
---@return table
function M.merge(t1, t2)
  local result = {}

  for k, v in pairs(t1) do
    if type(v) == 'table' then
      result[k] = M.merge(v, {})
    else
      result[k] = v
    end
  end

  for k, v in pairs(t2) do
    if type(v) == 'table' and type(result[k]) == 'table' then
      result[k] = M.merge(result[k], v)
    else
      result[k] = v
    end
  end

  return result
end

---@param domain_name string
---@return boolean
function M.is_ssh(domain_name)
  if type(domain_name) ~= 'string' then
    return false
  end

  local lower = domain_name:lower()

  if lower:match('^ssh:') or lower:match('^sshmux:') then
    return true
  end

  if lower == 'local' then
    return false
  end

  return lower:match(':') or lower:match('%.')
end

-- Gets current working directory using WezTerm's built-in Url.file_path
-- Relies on WezTerm's proper percent-decoding for professional implementation
---@param pane table
---@return string
function M.get_cwd(pane)
  local wezterm = require('wezterm')
  
  if not pane then
    return ''
  end
  
  local cwd_url = nil
  
  -- Handle two different types of pane objects:
  -- 1. Real pane object (from update-status event) - has methods like :get_current_working_dir()
  -- 2. Pane data table (from format-tab-title event's tab.active_pane) - has .current_working_dir field
  
  -- First, check if this is a pane data table with .current_working_dir field
  if type(pane) == 'table' and pane.current_working_dir then
    cwd_url = pane.current_working_dir
  else
    -- Otherwise, try calling the method (real pane object)
    local success, result = pcall(function()
      return pane:get_current_working_dir()
    end)
    
    if not success then
      wezterm.log_error('devbar.util: get_cwd() failed to get working directory:', result)
      return ''
    end
    
    cwd_url = result
  end

  -- No URL returned (pane not initialized yet)
  if not cwd_url then
    return ''
  end

  -- Modern WezTerm returns Url userdata/table object with .file_path field
  -- This handles all percent-decoding and path normalization correctly
  if type(cwd_url) == 'userdata' or type(cwd_url) == 'table' then
    -- Try file_path first (includes percent-decoding)
    if cwd_url.file_path and type(cwd_url.file_path) == 'string' and cwd_url.file_path ~= '' then
      return cwd_url.file_path
    end
    -- Fallback to .path if file_path is nil (happens for some URL formats)
    if cwd_url.path and type(cwd_url.path) == 'string' and cwd_url.path ~= '' then
      return cwd_url.path
    end
    -- If it's a table, might be old format - fall through to string handling
    if type(cwd_url) == 'userdata' then
      -- Last resort for userdata: convert to string
      return tostring(cwd_url)
    end
  end

  -- Fallback for legacy string format (rare in modern WezTerm)
  -- Use WezTerm's url.parse for proper percent-decoding
  if type(cwd_url) == 'string' then
    -- Try to parse as URL using WezTerm's built-in function
    local parse_success, parsed_url = pcall(function()
      return wezterm.url.parse(cwd_url)
    end)
    
    -- Check if parse succeeded and has file_path (userdata in real WezTerm, table in tests)
    if parse_success and parsed_url and parsed_url.file_path then
      return parsed_url.file_path
    end
    
    -- Last resort: basic string cleanup (maintains backward compatibility)
    return cwd_url:gsub('^file://', '')
  end

  return ''
end

---@param domain_name string
---@return string|nil
function M.get_hostname(domain_name)
  if type(domain_name) ~= 'string' or domain_name == '' then
    return nil
  end

  if domain_name:lower() == 'local' then
    return nil
  end

  local _, hostname = domain_name:match('^([^:]+):(.*)$')

  if hostname and hostname ~= '' then
    return hostname
  end

  return domain_name
end

---@param filepath string
---@return boolean
function M.file_exists(filepath)
  if type(filepath) ~= 'string' or filepath == '' then
    return false
  end

  local f = io.open(filepath, 'r')
  if f then
    f:close()
    return true
  end
  return false
end

-- Uses /bin/sh -lc for cross-platform compatibility
---@param cmd string
---@return string|nil
function M.run_command(cmd)
  if type(cmd) ~= 'string' or cmd == '' then
    return nil
  end

  local escaped_cmd = cmd:gsub('"', '\\"')
  local full_cmd = string.format('/bin/sh -lc "%s" 2>/dev/null', escaped_cmd)

  local success, handle = pcall(io.popen, full_cmd)
  if not success or not handle then
    local wezterm = require('wezterm')
    wezterm.log_warn('devbar.util: command failed to execute:', cmd)
    return nil
  end

  local result = handle:read('*a')
  handle:close()

  if result and result ~= '' then
    return M.trim(result)
  end

  return nil
end

-- Uses ssh -G to resolve config (handles includes, wildcards, etc.)
---@param ssh_alias string
---@return table|nil
function M.get_ssh_config(ssh_alias)
  if type(ssh_alias) ~= 'string' or ssh_alias == '' then
    return nil
  end

  local cmd = string.format('ssh -G "%s" 2>/dev/null | grep -E "^(hostname|user) " | head -2', ssh_alias)
  local result = M.run_command(cmd)

  if not result then
    local wezterm = require('wezterm')
    wezterm.log_warn('devbar.util: ssh -G failed for:', ssh_alias, '(using fallback user@alias format)')
    return nil
  end

  local config = {}

  for line in result:gmatch('[^\r\n]+') do
    local key, value = line:match('^(%w+)%s+(.+)$')
    if key and value then
      if key == 'hostname' then
        config.hostname = M.trim(value)
      elseif key == 'user' then
        config.user = M.trim(value)
      end
    end
  end

  if not config.hostname or not config.user then
    local wezterm = require('wezterm')
    wezterm.log_warn('devbar.util: Incomplete SSH config for', ssh_alias)
    return nil
  end

  return config
end

return M
