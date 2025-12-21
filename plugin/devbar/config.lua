local util = require('devbar.util')

local M = {}

M.defaults = {
  position = 'bottom',
  use_ascii_icons = false,
  divider = ' | ',
  truncate = {
    branch = 20,
    cwd = 30,
    tab = 32,
  },
  cache_ttl = 5,
  ssh_cache_ttl = 60,
  segments = {
    workspace = {
      enabled = true,
    },
    mode = {
      enabled = true,
    },
    zoom = {
      enabled = true,
    },
    git = {
      enabled = true,
    },
    runtimes = {
      enabled = true,
    },
    datetime = {
      enabled = true,
      format = '%H:%M',
    },
    ssh = {
      enabled = true,
    },
  },
  colors = nil,
  padding = {
    left = 1,
    right = 1,
  },
}

M.options = {}

---@param user_opts table|nil
---@return table
function M.setup(user_opts)
  user_opts = user_opts or {}
  M.options = util.merge(M.defaults, user_opts)
  return M.options
end

---@return table
function M.get()
  return M.options
end

return M
