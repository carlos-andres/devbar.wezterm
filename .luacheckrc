std = "lua54"
codes = true
max_line_length = 120
max_comment_line_length = 120

-- Ignore WezTerm globals
globals = {
  "wezterm",
}

-- Allow defining module pattern at top level
allow_defined_top = true

-- Ignore unused self parameter
self = false

-- Ignore unused loop variables (common pattern: for _, item in ipairs)
unused_args = false
