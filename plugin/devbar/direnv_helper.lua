local util = require('devbar.util')
local cache = require('devbar.cache')

local M = {}

---@return boolean
local function has_direnv()
  local cached = cache.get('direnv:installed', 86400)
  if cached ~= nil then
    return cached
  end

  local result = util.run_command('command -v direnv')
  local installed = result ~= nil and result ~= ''
  cache.set('direnv:installed', installed, 86400)
  return installed
end

---@param cwd string
---@return boolean
local function has_envrc(cwd)
  if not cwd or cwd == '' then
    return false
  end
  return util.file_exists(cwd .. '/.envrc')
end

---@param cwd string
---@param ttl number
---@return string|nil
local function get_direnv_exports(cwd, ttl)
  ttl = ttl or 30

  local cache_key = 'direnv:' .. cwd
  local cached = cache.get(cache_key, ttl)
  if cached ~= nil then
    return cached ~= false and cached or nil
  end

  if not has_direnv() then
    cache.set(cache_key, false, ttl)
    return nil
  end

  if not has_envrc(cwd) then
    cache.set(cache_key, false, ttl)
    return nil
  end

  -- EXPENSIVE ~100ms: direnv export resolves environment for project
  local cmd = string.format('cd "%s" && direnv export bash 2>/dev/null', cwd)
  local exports = util.run_command(cmd)

  if exports and exports ~= '' then
    local export_cmd = 'eval "' .. exports:gsub('"', '\\"') .. '"'
    cache.set(cache_key, export_cmd, ttl)
    return export_cmd
  end

  cache.set(cache_key, false, ttl)
  return nil
end

---@param cmd string
---@param cwd string
---@param ttl number|nil
---@return string|nil
function M.run_with_direnv(cmd, cwd, ttl)
  local direnv_exports = get_direnv_exports(cwd, ttl)

  if direnv_exports then
    local full_cmd = string.format('cd "%s" && %s && %s', cwd, direnv_exports, cmd)
    return util.run_command(full_cmd)
  else
    local full_cmd = string.format('cd "%s" && %s', cwd, cmd)
    return util.run_command(full_cmd)
  end
end

---@param tool_name string
---@param cwd string
---@param ttl number|nil
---@return string|nil
function M.which_tool(tool_name, cwd, ttl)
  return M.run_with_direnv('which ' .. tool_name, cwd, ttl)
end

---@param cwd string
---@return boolean
function M.is_direnv_active(cwd)
  return has_direnv() and has_envrc(cwd)
end

return M
