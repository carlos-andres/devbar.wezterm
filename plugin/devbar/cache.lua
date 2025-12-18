local M = {}

local cache = {}

---@param key string
---@param ttl number
---@return any|nil
function M.get(key, ttl)
  if type(key) ~= 'string' or type(ttl) ~= 'number' then
    return nil
  end

  local entry = cache[key]
  if not entry then
    return nil
  end

  local now = os.time()
  local age = now - entry.timestamp

  if age < ttl then
    return entry.value
  end

  cache[key] = nil
  return nil
end

---@param key string
---@param value any
function M.set(key, value)
  if type(key) ~= 'string' then
    return
  end

  cache[key] = {
    value = value,
    timestamp = os.time(),
  }
end

---@param key string
function M.clear(key)
  if type(key) == 'string' then
    cache[key] = nil
  end
end

function M.clear_all()
  cache = {}
end

---@param key string
---@param ttl number
---@param fetch_fn function
---@return any
function M.get_or_fetch(key, ttl, fetch_fn)
  local cached = M.get(key, ttl)
  if cached ~= nil then
    return cached
  end

  local value = fetch_fn()
  M.set(key, value)

  return value
end

return M
