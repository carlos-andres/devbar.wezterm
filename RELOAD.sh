#!/bin/bash
# Force reload WezTerm plugin after changes
# Useful when plugin updates don't apply or during development

set -e

echo "🔄 Reloading devbar.wezterm plugin..."

# Clear WezTerm's plugin cache
PLUGIN_CACHE_DIR="$HOME/Library/Application Support/wezterm/plugins"
if [ -d "$PLUGIN_CACHE_DIR" ]; then
    echo "📁 Clearing plugin cache..."
    find "$PLUGIN_CACHE_DIR" -type d -name "*devbar*" -exec rm -rf {} + 2>/dev/null || true
    echo "✅ Cache cleared successfully"
else
    echo "ℹ️  No plugin cache found (first installation?)"
fi

# Show reload instructions
echo ""
echo "📋 Next steps:"
echo "1. Press Cmd+Shift+R (macOS) or Ctrl+Shift+R (Linux) in WezTerm to reload"
echo "2. Or run in Debug Overlay (Cmd/Ctrl+Shift+L):"
echo "   > wezterm.plugin.update_all()"
echo ""
echo "✨ Plugin cache cleared! Your changes should now be visible."
echo ""
