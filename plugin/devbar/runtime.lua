-- Only runs in git repositories
local util = require('devbar.util')
local cache = require('devbar.cache')
local icons = require('devbar.icons')
local direnv = require('devbar.direnv_helper')

local M = {}

---@param cwd string
---@return boolean
local function is_git_repo(cwd)
  if not cwd or cwd == '' then
    return false
  end
  local dir = cwd
  while dir and dir ~= '' and dir ~= '/' do
    if util.file_exists(dir .. '/.git') then
      return true
    end
    dir = dir:match('(.+)/[^/]*$')
  end
  return false
end

---@param cwd string
---@param use_ascii boolean
---@return table|nil
local function detect_node(cwd, use_ascii)
  local wezterm = require('wezterm')

  if not util.file_exists(cwd .. '/package.json') then
    return nil
  end

  local node_path = direnv.which_tool('node', cwd)
  if not node_path then
    return nil
  end

  local version = direnv.run_with_direnv('node --version', cwd)
  if not version then
    wezterm.log_warn('devbar.runtime: node installed but version command failed for:', cwd)
    return nil
  end

  version = version:match('^v?(%d+%.%d+)')
  if version then
    version = 'v' .. version
  end

  return {
    icon = icons.get('nodejs', use_ascii),
    version = version or 'node',
  }
end

---@param cwd string
---@param use_ascii boolean
---@return table|nil
local function detect_php(cwd, use_ascii)
  if not util.file_exists(cwd .. '/composer.json') then
    return nil
  end

  local php_path = direnv.which_tool('php', cwd)
  if not php_path then
    return nil
  end

  local output = direnv.run_with_direnv('php -v', cwd)
  if not output then
    return nil
  end

  local version = output:match('PHP (%d+%.%d+%.%d+)')
  if version then
    version = 'v' .. version:match('^(%d+%.%d+)')
  end

  return {
    icon = icons.get('php', use_ascii),
    version = version or 'php',
  }
end

---@param cwd string
---@param use_ascii boolean
---@return table|nil
local function detect_python(cwd, use_ascii)
  local has_marker = util.file_exists(cwd .. '/requirements.txt')
    or util.file_exists(cwd .. '/pyproject.toml')
    or util.file_exists(cwd .. '/setup.py')
    or util.file_exists(cwd .. '/Pipfile')

  if not has_marker then
    return nil
  end

  local version = util.run_command('command -v python3 >/dev/null && python3 --version')
  if not version then
    version = util.run_command('command -v python >/dev/null && python --version')
  end

  if not version then
    return nil
  end

  local ver = version:match('Python (%d+%.%d+)')
  if ver then
    version = 'v' .. ver
  end

  return {
    icon = icons.get('python', use_ascii),
    version = version or 'py',
  }
end

---@param cwd string
---@param use_ascii boolean
---@return table|nil
local function detect_go(cwd, use_ascii)
  if not util.file_exists(cwd .. '/go.mod') then
    return nil
  end

  local has_go = util.run_command('command -v go')
  if not has_go then
    return nil
  end

  local output = util.run_command('go version')
  if not output then
    return nil
  end

  local version = output:match('go(%d+%.%d+)')
  if version then
    version = 'v' .. version
  end

  return {
    icon = icons.get('go', use_ascii),
    version = version or 'go',
  }
end

---@param cwd string
---@param ttl number
---@param use_ascii boolean
---@return table
function M.detect_runtimes(cwd, ttl, use_ascii)
  if not cwd or cwd == '' then
    return {}
  end

  if not is_git_repo(cwd) then
    return {}
  end

  local cache_key = 'runtime:' .. cwd
  local cached = cache.get(cache_key, ttl or 5)
  if cached ~= nil then
    return cached
  end

  local runtimes = {}

  local node = detect_node(cwd, use_ascii)
  if node then
    table.insert(runtimes, node)
  end

  local php = detect_php(cwd, use_ascii)
  if php then
    table.insert(runtimes, php)
  end

  local python = detect_python(cwd, use_ascii)
  if python then
    table.insert(runtimes, python)
  end

  local go = detect_go(cwd, use_ascii)
  if go then
    table.insert(runtimes, go)
  end

  cache.set(cache_key, runtimes)

  return runtimes
end

return M
