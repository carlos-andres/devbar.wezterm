#!/bin/bash
echo "🔍 DevBar WezTerm Plugin - Pre-Load Checklist"
echo "================================================"
echo ""

# Check 1: Git repo
if [ -d ".git" ]; then
  echo "✅ Git repository: $(git branch --show-current)"
  echo "   Commit: $(git log --oneline -1)"
else
  echo "❌ Git repository: NOT FOUND"
  exit 1
fi

# Check 2: Plugin files
echo ""
echo "📁 Plugin files:"
required_files=(
  "plugin/init.lua"
  "plugin/devbar/config.lua"
  "plugin/devbar/theme.lua"
  "plugin/devbar/tabs.lua"
  "plugin/devbar/util.lua"
  "plugin/devbar/icons.lua"
  "plugin/devbar/git.lua"
  "plugin/devbar/runtime.lua"
  "plugin/devbar/cache.lua"
)

all_good=true
for file in "${required_files[@]}"; do
  if [ -f "$file" ]; then
    echo "   ✅ $file"
  else
    echo "   ❌ $file (MISSING)"
    all_good=false
  fi
done

# Check 3: Error handling in init.lua
echo ""
echo "🛡️ Error handling:"
if grep -q "safe_init()" plugin/init.lua; then
  echo "   ✅ safe_init() function present"
else
  echo "   ❌ safe_init() function missing"
  all_good=false
fi

if grep -q "pcall(require" plugin/init.lua; then
  echo "   ✅ Module loading protected with pcall"
else
  echo "   ❌ Module loading not protected"
  all_good=false
fi

if grep -q "wezterm.log_error" plugin/init.lua; then
  echo "   ✅ Error logging present"
else
  echo "   ❌ Error logging missing"
  all_good=false
fi

# Check 4: WezTerm config
echo ""
echo "⚙️  WezTerm configuration:"
if [ -f "$HOME/.wezterm.lua" ]; then
  if grep -q "devbar.wezterm" "$HOME/.wezterm.lua"; then
    echo "   ✅ Plugin loading configured"
  else
    echo "   ⚠️  Plugin loading not found in .wezterm.lua"
    echo "      (searched for 'devbar.wezterm')"
  fi
else
  echo "   ❌ ~/.wezterm.lua not found"
  all_good=false
fi

# Check 5: Lua syntax
echo ""
echo "📝 Lua syntax check:"
syntax_errors=0
for file in plugin/**/*.lua plugin/*.lua; do
  if [ -f "$file" ]; then
    if ! luac -p "$file" 2>/dev/null; then
      echo "   ❌ Syntax error in: $file"
      syntax_errors=$((syntax_errors + 1))
      all_good=false
    fi
  fi
done
if [ $syntax_errors -eq 0 ]; then
  echo "   ✅ All Lua files have valid syntax"
fi

# Final verdict
echo ""
echo "================================================"
if [ "$all_good" = true ]; then
  echo "🎉 ALL CHECKS PASSED!"
  echo ""
  echo "Ready to load in WezTerm:"
  echo "  1. Press: Cmd+Shift+R (reload config)"
  echo "  2. Press: Cmd+Shift+L (open Debug Overlay)"
  echo "  3. Look for INFO logs showing successful loading"
  echo ""
  echo "Expected result: Styled tab bar at bottom with status info"
else
  echo "⚠️  SOME CHECKS FAILED"
  echo ""
  echo "Please fix the issues above before loading"
fi
