local util = require('devbar.util')
local cache = require('devbar.cache')

local M = {}

---@param cwd string
---@return boolean
local function is_git_repo(cwd)
  if not cwd or cwd == '' then
    return false
  end

  local dir = cwd
  while dir and dir ~= '' and dir ~= '/' do
    if util.file_exists(dir .. '/.git') or util.file_exists(dir .. '/.git/HEAD') then
      return true
    end
    dir = dir:match('(.+)/[^/]*$')
  end

  return false
end

---@param cwd string
---@param ttl number
---@param max_len number|nil
---@return string|nil
function M.get_branch(cwd, ttl, max_len)
  if not cwd or cwd == '' then
    return nil
  end

  local cache_key = 'git:' .. cwd
  local cached = cache.get(cache_key, ttl or 5)
  if cached ~= nil then
    return cached
  end

  if not is_git_repo(cwd) then
    cache.set(cache_key, nil)
    return nil
  end

  local cmd = string.format('cd "%s" && git branch --show-current', cwd)
  local branch = util.run_command(cmd)

  if not branch or branch == '' then
    cmd = string.format('cd "%s" && git rev-parse --short HEAD', cwd)
    branch = util.run_command(cmd)
    if branch and branch ~= '' then
      branch = 'HEAD@' .. branch
    end
  end

  if branch and max_len and type(max_len) == 'number' and max_len > 0 then
    branch = util.truncate(branch, max_len)
  end

  cache.set(cache_key, branch)

  return branch
end

return M
