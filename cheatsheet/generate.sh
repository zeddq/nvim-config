#!/usr/bin/env bash
# Neovim Config Cheatsheet Generator
# Generates an HTML cheatsheet with workflow documentation.
# If vhs is installed, also records animated WebP/GIF demos from .tape files.
#
# Usage:
#   ./cheatsheet/generate.sh              # Generate HTML + record tapes (if vhs available)
#   ./cheatsheet/generate.sh --html-only  # Generate HTML cheatsheet only
#   ./cheatsheet/generate.sh --record     # Record tapes only (requires vhs)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
WORKFLOWS_DIR="$SCRIPT_DIR/workflows"
TAPES_DIR="$SCRIPT_DIR/tapes"
OUTPUT_HTML="$SCRIPT_DIR/index.html"

mkdir -p "$WORKFLOWS_DIR"

# ── Parse arguments ──────────────────────────────────────────────────────────

HTML_ONLY=false
RECORD_ONLY=false

case "${1:-}" in
  --html-only) HTML_ONLY=true ;;
  --record)    RECORD_ONLY=true ;;
esac

# ── Extract keymaps from plugin files ────────────────────────────────────────

extract_keymaps() {
  local file="$1"
  local plugin_name="$2"

  # Extract vim.keymap.set and keys = { ... } patterns
  grep -oE '"<[^"]*>"' "$file" 2>/dev/null | sort -u | while read -r key; do
    # Find the desc for this keymap
    local desc
    desc=$(grep -A2 "$key" "$file" | grep -oP 'desc\s*=\s*"\K[^"]+' | head -1)
    if [ -n "$desc" ]; then
      echo "  <tr><td><kbd>${key//\"/}</kbd></td><td>$desc</td><td>$plugin_name</td></tr>"
    fi
  done
}

# ── Collect workflow media ───────────────────────────────────────────────────

collect_workflow_media() {
  local html=""
  local found_media=false

  for media_file in "$WORKFLOWS_DIR"/*.webp "$WORKFLOWS_DIR"/*.gif; do
    [ -f "$media_file" ] || continue
    found_media=true
    local basename
    basename=$(basename "$media_file")
    local title="${basename%.*}"
    title="${title//-/ }"
    title="${title#[0-9][0-9] }"
    title="${title#[0-9][0-9]-}"

    html+="<div class=\"workflow-card\">"
    html+="<h3>${title}</h3>"
    if [[ "$media_file" == *.webp ]]; then
      html+="<img src=\"workflows/$basename\" alt=\"$title\" loading=\"lazy\">"
    else
      html+="<img src=\"workflows/$basename\" alt=\"$title\" loading=\"lazy\">"
    fi
    html+="</div>"
  done

  if [ "$found_media" = false ]; then
    html+="<p class=\"note\">No workflow recordings found. Install <a href=\"https://github.com/charmbracelet/vhs\">vhs</a> and run <code>./cheatsheet/generate.sh --record</code> to generate animated demos.</p>"
  fi

  echo "$html"
}

# ── Record VHS tapes ─────────────────────────────────────────────────────────

record_tapes() {
  if ! command -v vhs &>/dev/null; then
    echo "vhs not found — install via: brew install vhs"
    echo "Skipping tape recording."
    return 1
  fi

  local count=0
  for tape in "$TAPES_DIR"/*.tape; do
    [ -f "$tape" ] || continue
    local basename
    basename=$(basename "$tape" .tape)
    echo "Recording: $basename"
    (cd "$REPO_DIR" && vhs "$tape") || {
      echo "Warning: failed to record $basename"
      continue
    }
    count=$((count + 1))
  done

  echo "Recorded $count workflow(s)."
}

# ── Generate HTML cheatsheet ─────────────────────────────────────────────────

generate_html() {
  local workflow_media
  workflow_media=$(collect_workflow_media)

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M')

  local git_hash
  git_hash=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")

  cat > "$OUTPUT_HTML" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Neovim Config Cheatsheet</title>
<style>
  :root {
    --bg: #1a1b26; --bg-dark: #16161e; --bg-highlight: #292e42;
    --fg: #c0caf5; --fg-dark: #a9b1d6; --fg-gutter: #3b4261;
    --blue: #7aa2f7; --cyan: #7dcfff; --green: #9ece6a;
    --magenta: #bb9af7; --red: #f7768e; --yellow: #e0af68;
    --orange: #ff9e64; --teal: #1abc9c;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: 'JetBrains Mono', 'Fira Code', 'SF Mono', monospace;
    background: var(--bg); color: var(--fg);
    line-height: 1.6; padding: 2rem; max-width: 1400px; margin: 0 auto;
  }
  h1 { color: var(--blue); margin-bottom: 0.5rem; font-size: 1.8rem; }
  h2 { color: var(--magenta); margin: 2rem 0 1rem; border-bottom: 1px solid var(--fg-gutter); padding-bottom: 0.5rem; }
  h3 { color: var(--cyan); margin: 1rem 0 0.5rem; }
  .meta { color: var(--fg-dark); font-size: 0.85rem; margin-bottom: 2rem; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(600px, 1fr)); gap: 1.5rem; }
  .section {
    background: var(--bg-dark); border: 1px solid var(--fg-gutter);
    border-radius: 8px; padding: 1.5rem; overflow: hidden;
  }
  table { width: 100%; border-collapse: collapse; font-size: 0.9rem; }
  th { text-align: left; color: var(--yellow); padding: 0.5rem; border-bottom: 1px solid var(--fg-gutter); }
  td { padding: 0.4rem 0.5rem; border-bottom: 1px solid var(--bg-highlight); }
  kbd {
    background: var(--bg-highlight); color: var(--green); padding: 2px 6px;
    border-radius: 3px; font-size: 0.85rem; white-space: nowrap;
    border: 1px solid var(--fg-gutter);
  }
  .workflow-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); gap: 1.5rem; margin: 1rem 0; }
  .workflow-card {
    background: var(--bg-dark); border: 1px solid var(--fg-gutter);
    border-radius: 8px; padding: 1rem; text-align: center;
  }
  .workflow-card img { max-width: 100%; border-radius: 4px; margin-top: 0.5rem; }
  .note { color: var(--fg-dark); font-style: italic; padding: 1rem; }
  a { color: var(--blue); }
  .leader { color: var(--orange); }
  .tag {
    display: inline-block; padding: 1px 6px; border-radius: 3px;
    font-size: 0.75rem; margin-left: 0.5rem;
  }
  .tag-git { background: var(--red); color: var(--bg); }
  .tag-jj { background: var(--teal); color: var(--bg); }
  .tag-both { background: var(--green); color: var(--bg); }
  @media (max-width: 700px) {
    .grid, .workflow-grid { grid-template-columns: 1fr; }
    body { padding: 1rem; }
  }
</style>
</head>
<body>
HTMLEOF

  cat >> "$OUTPUT_HTML" << EOF
<h1>Neovim Config Cheatsheet</h1>
<p class="meta">Generated: $timestamp | Commit: $git_hash | Leader: <kbd>&lt;Space&gt;</kbd> | Local Leader: <kbd>\\</kbd></p>
EOF

  # ── Workflow Recordings Section ──
  cat >> "$OUTPUT_HTML" << EOF
<h2>Workflow Demos</h2>
<div class="workflow-grid">
$workflow_media
</div>
EOF

  # ── VCS Keymaps ──
  cat >> "$OUTPUT_HTML" << 'EOF'
<h2>Keybinding Reference</h2>
<div class="grid">

<div class="section">
<h3>VCS Operations <span class="tag tag-both">git + jj</span></h3>
<table>
<tr><th>Key</th><th>Action</th><th>Git</th><th>Jujutsu</th></tr>
<tr><td><kbd>&lt;leader&gt;gs</kbd></td><td>Status</td><td>git status</td><td>J status</td></tr>
<tr><td><kbd>&lt;leader&gt;gl</kbd></td><td>Log</td><td>git log --graph</td><td>J log</td></tr>
<tr><td><kbd>&lt;leader&gt;gd</kbd></td><td>Diff</td><td>git diff</td><td>J diff</td></tr>
<tr><td><kbd>&lt;leader&gt;gb</kbd></td><td>Blame</td><td>git blame</td><td>git blame (fallback)</td></tr>
<tr><td><kbd>&lt;leader&gt;gc</kbd></td><td>Commit/Describe</td><td>git commit</td><td>J describe</td></tr>
<tr><td><kbd>&lt;leader&gt;gC</kbd></td><td>Amend/Redescribe</td><td>git commit --amend</td><td>J describe</td></tr>
<tr><td><kbd>&lt;leader&gt;gB</kbd></td><td>Create Branch/Bookmark</td><td>git checkout -b</td><td>jj bookmark create</td></tr>
<tr><td><kbd>&lt;leader&gt;gL</kbd></td><td>List Branches/Bookmarks</td><td>git branch -avv</td><td>jj bookmark list</td></tr>
<tr><td><kbd>&lt;leader&gt;gp</kbd></td><td>Push</td><td>git push</td><td>jj git push</td></tr>
<tr><td><kbd>&lt;leader&gt;gP</kbd></td><td>Pull/Fetch</td><td>git pull</td><td>jj git fetch</td></tr>
<tr><td><kbd>&lt;leader&gt;gR</kbd></td><td>Refresh VCS Cache</td><td colspan="2">Clears detection cache</td></tr>
<tr><td><kbd>&lt;leader&gt;g?</kbd></td><td>VCS Info</td><td colspan="2">Shows type, root, cache stats</td></tr>
</table>

<h3>Jujutsu-Only <span class="tag tag-jj">jj</span></h3>
<table>
<tr><th>Key</th><th>Action</th></tr>
<tr><td><kbd>&lt;leader&gt;gn</kbd></td><td>New change (jj new)</td></tr>
<tr><td><kbd>&lt;leader&gt;gS</kbd></td><td>Squash (jj squash)</td></tr>
<tr><td><kbd>&lt;leader&gt;ge</kbd></td><td>Edit change (jj edit)</td></tr>
<tr><td><kbd>&lt;leader&gt;gj</kbd></td><td>JJ Picker: Status</td></tr>
<tr><td><kbd>&lt;leader&gt;gh</kbd></td><td>File History</td></tr>
</table>
</div>

<div class="section">
<h3>LSP</h3>
<table>
<tr><th>Key</th><th>Action</th></tr>
<tr><td><kbd>gd</kbd> / <kbd>Ctrl-]</kbd></td><td>Go to definition</td></tr>
<tr><td><kbd>gD</kbd></td><td>Go to declaration</td></tr>
<tr><td><kbd>gi</kbd></td><td>Go to implementation</td></tr>
<tr><td><kbd>gr</kbd></td><td>Show references</td></tr>
<tr><td><kbd>K</kbd></td><td>Hover documentation</td></tr>
<tr><td><kbd>Ctrl-k</kbd></td><td>Signature help</td></tr>
<tr><td><kbd>&lt;leader&gt;rn</kbd></td><td>Rename symbol</td></tr>
<tr><td><kbd>&lt;leader&gt;ca</kbd></td><td>Code action</td></tr>
<tr><td><kbd>&lt;leader&gt;cf</kbd></td><td>Fix all (Ruff)</td></tr>
<tr><td><kbd>&lt;leader&gt;co</kbd></td><td>Organize imports</td></tr>
<tr><td><kbd>&lt;leader&gt;cr</kbd></td><td>Refactor</td></tr>
<tr><td><kbd>&lt;leader&gt;ce</kbd></td><td>Extract (visual)</td></tr>
<tr><td><kbd>&lt;leader&gt;cq</kbd></td><td>Quick fix (line)</td></tr>
<tr><td><kbd>&lt;leader&gt;f</kbd></td><td>Format document</td></tr>
<tr><td><kbd>&lt;leader&gt;wa</kbd></td><td>Add workspace folder</td></tr>
<tr><td><kbd>&lt;leader&gt;wr</kbd></td><td>Remove workspace folder</td></tr>
</table>
</div>

<div class="section">
<h3>Debug (DAP)</h3>
<table>
<tr><th>Key</th><th>Action</th></tr>
<tr><td><kbd>F5</kbd></td><td>Start / Continue</td></tr>
<tr><td><kbd>F10</kbd></td><td>Step Over</td></tr>
<tr><td><kbd>F11</kbd></td><td>Step Into</td></tr>
<tr><td><kbd>F12</kbd></td><td>Step Out</td></tr>
<tr><td><kbd>&lt;leader&gt;b</kbd></td><td>Toggle Breakpoint</td></tr>
<tr><td><kbd>&lt;leader&gt;B</kbd></td><td>Conditional Breakpoint</td></tr>
<tr><td><kbd>&lt;leader&gt;dr</kbd></td><td>Open REPL</td></tr>
<tr><td><kbd>&lt;leader&gt;dl</kbd></td><td>Run Last</td></tr>
<tr><td><kbd>&lt;leader&gt;du</kbd></td><td>Toggle DAP UI</td></tr>
</table>

<h3>Navigation (Flash)</h3>
<table>
<tr><th>Key</th><th>Action</th><th>Modes</th></tr>
<tr><td><kbd>s</kbd></td><td>Flash jump</td><td>n, x, o</td></tr>
<tr><td><kbd>S</kbd></td><td>Flash treesitter</td><td>n, x, o</td></tr>
<tr><td><kbd>r</kbd></td><td>Remote Flash</td><td>o</td></tr>
<tr><td><kbd>R</kbd></td><td>Treesitter Search</td><td>o, x</td></tr>
</table>
</div>

<div class="section">
<h3>Snacks / UI</h3>
<table>
<tr><th>Key</th><th>Action</th></tr>
<tr><td><kbd>Ctrl-/</kbd></td><td>Toggle Terminal (Snacks)</td></tr>
<tr><td><kbd>Ctrl-\</kbd></td><td>Toggle Terminal (Toggleterm, float)</td></tr>
<tr><td><kbd>&lt;leader&gt;e</kbd></td><td>Toggle File Explorer (Neo-tree)</td></tr>
<tr><td><kbd>&lt;leader&gt;sd</kbd></td><td>Dashboard</td></tr>
<tr><td><kbd>&lt;leader&gt;ss</kbd></td><td>Scratch Buffer</td></tr>
<tr><td><kbd>&lt;leader&gt;sS</kbd></td><td>Select Scratch Buffer</td></tr>
<tr><td><kbd>&lt;leader&gt;sn</kbd></td><td>Notification History</td></tr>
<tr><td><kbd>&lt;leader&gt;snd</kbd></td><td>Dismiss Notifications</td></tr>
<tr><td><kbd>&lt;leader&gt;gB</kbd></td><td>Git Browse (Snacks)</td></tr>
</table>

<h3>Completion (nvim-cmp)</h3>
<table>
<tr><th>Key</th><th>Action</th></tr>
<tr><td><kbd>Ctrl-Space</kbd></td><td>Trigger completion</td></tr>
<tr><td><kbd>Tab</kbd> / <kbd>S-Tab</kbd></td><td>Navigate items / jump snippets</td></tr>
<tr><td><kbd>Enter</kbd></td><td>Confirm selection</td></tr>
<tr><td><kbd>Ctrl-e</kbd></td><td>Abort completion</td></tr>
<tr><td><kbd>Ctrl-b</kbd> / <kbd>Ctrl-f</kbd></td><td>Scroll docs</td></tr>
</table>
</div>

</div>

<h2>LSP Server Architecture</h2>
<div class="section">
<table>
<tr><th>Server</th><th>Languages</th><th>Responsibilities</th></tr>
<tr><td><kbd>basedpyright</kbd></td><td>Python</td><td>Type checking, hover, completions, go-to-def, auto-imports</td></tr>
<tr><td><kbd>ruff</kbd></td><td>Python</td><td>Code actions (fix all, organize imports), formatting</td></tr>
<tr><td><kbd>pylsp</kbd></td><td>Python</td><td>Refactoring via rope only (other capabilities disabled)</td></tr>
<tr><td><kbd>lua_ls</kbd></td><td>Lua</td><td>Full LSP + lazydev.nvim workspace management</td></tr>
<tr><td><kbd>bashls</kbd></td><td>sh/zsh/bash</td><td>Full LSP</td></tr>
<tr><td><kbd>jdtls</kbd></td><td>Java</td><td>Full LSP (JBR 21 runtime)</td></tr>
<tr><td><kbd>taplo</kbd></td><td>TOML</td><td>Full LSP + jj config schema association</td></tr>
</table>
</div>

EOF

  cat >> "$OUTPUT_HTML" << 'EOF'
<h2>Plugin Overview</h2>
<div class="section">
<table>
<tr><th>Plugin</th><th>Purpose</th><th>Load</th></tr>
<tr><td>folke/snacks.nvim</td><td>Dashboard, notifications, indent, statuscolumn, terminal, scope</td><td>priority 1000</td></tr>
<tr><td>nicolasgb/jj.nvim</td><td>Jujutsu VCS integration</td><td>always</td></tr>
<tr><td>nvim-neo-tree/neo-tree.nvim</td><td>File explorer (jj-aware)</td><td>always</td></tr>
<tr><td>folke/lazydev.nvim</td><td>Neovim Lua API + luvit-meta</td><td>ft=lua</td></tr>
<tr><td>neovim/nvim-lspconfig</td><td>LSP configuration</td><td>always</td></tr>
<tr><td>hrsh7th/nvim-cmp</td><td>Autocompletion</td><td>always</td></tr>
<tr><td>stevearc/conform.nvim</td><td>Formatting (ruff, stylua, prettier, shfmt)</td><td>BufWritePre</td></tr>
<tr><td>nvimtools/none-ls.nvim</td><td>Custom LSP sources (AppleScript, markdownlint)</td><td>always</td></tr>
<tr><td>folke/flash.nvim</td><td>Enhanced navigation</td><td>VeryLazy</td></tr>
<tr><td>mfussenegger/nvim-dap</td><td>Debug (Python, Lua, Bash/Zsh)</td><td>on-keypress</td></tr>
<tr><td>akinsho/toggleterm.nvim</td><td>Floating terminal</td><td>always</td></tr>
<tr><td>javiorfo/nvim-soil</td><td>PlantUML preview</td><td>ft=plantuml</td></tr>
<tr><td>rafikdraoui/jj-diffconflicts</td><td>JJ merge conflict viewer</td><td>on-command</td></tr>
<tr><td>folke/tokyonight.nvim</td><td>Color scheme</td><td>always</td></tr>
<tr><td>lewis6991/gitsigns.nvim</td><td>Git signs (disabled in jj repos)</td><td>conditional</td></tr>
<tr><td>greggh/claude-code.nvim</td><td>Claude Code AI assistant</td><td>always</td></tr>
</table>
</div>

<footer style="margin-top:2rem;color:var(--fg-gutter);font-size:0.8rem;text-align:center;">
  Auto-generated by cheatsheet/generate.sh
</footer>
</body>
</html>
EOF

  echo "Generated: $OUTPUT_HTML"
}

# ── Main ─────────────────────────────────────────────────────────────────────

if [ "$RECORD_ONLY" = true ]; then
  record_tapes
elif [ "$HTML_ONLY" = true ]; then
  generate_html
else
  # Default: record tapes (if vhs available), then generate HTML
  record_tapes || true
  generate_html
fi
