# Tmux + Starship Integration

Modern tmux configuration with intelligent status bar powered by Starship-inspired design.

## Features

### Core Features
- **Responsive status bar** with git/language info that adapts to terminal width
- **Context awareness** (SSH, Docker, K8s, virtual envs)
- **Intelligent caching** for performance (5-second cache for git/language detection)
- **True color support** and mouse support
- **Enhanced plugins** (fzf, yank, resurrect, continuum)

### Status Bar Components
- Git branch and status (clean/dirty indicators)
- Programming language versions (Node.js, Python, Ruby, Go, Rust, Java)
- Virtual environment indicators (venv, conda)
- Container context (Docker, Kubernetes)
- SSH session indicator
- Current directory path (responsive to terminal width)

## Keybindings

### Prefix Key
- **Prefix**: `Ctrl-a` (instead of default `Ctrl-b`)

### Enhanced Navigation
- `prefix + f`: Fuzzy find sessions (tmux-fzf)
- `prefix + F`: Fuzzy find windows (tmux-fzf)
- `prefix + u`: Find and open URLs from pane content

### Status Bar Controls
- `prefix + t`: Toggle status detail level (150 ↔ 50 chars)
- `prefix + T`: Toggle status bar completely on/off
- `prefix + r`: Refresh config and clear cache

### Standard Bindings
- `prefix + h/j/k/l`: Navigate panes (vim-style)
- `prefix + |`: Split horizontally
- `prefix + -`: Split vertically
- `prefix + c`: New window
- `prefix + R`: Reload config

## Status Bar Behavior

The status bar intelligently adapts to your terminal width:

### Wide Terminals (>120 columns)
- Full directory path
- Full version numbers
- All status indicators
- Maximum detail

### Medium Terminals (80-120 columns)
- Shortened directory path
- Abbreviated version numbers
- Primary status indicators
- Balanced information

### Narrow Terminals (<80 columns)
- Git status only
- Minimal information
- Maximum space for content

## Scripts

### Main Scripts
- `~/.tmux/scripts/responsive-status.sh`: Main status generator
  - Detects terminal width
  - Orchestrates other scripts
  - Formats output for tmux

- `~/.tmux/scripts/context-detect.sh`: Context awareness
  - Detects SSH sessions
  - Identifies container environments (Docker, K8s)
  - Recognizes virtual environments
  - Provides contextual status icons

- `~/.tmux/scripts/cache-manager.sh`: Performance caching
  - 5-second cache for expensive operations
  - Separate cache per pane/directory
  - Automatic cache invalidation
  - Improves responsiveness

### Helper Scripts
- `~/.tmux/scripts/install-plugins.sh`: Plugin installation helper
  - Installs TPM if missing
  - Provides plugin management guidance

## Installation

### Initial Setup
```bash
# Install TPM and plugins
~/.tmux/scripts/install-plugins.sh

# Start tmux
tmux

# Install plugins (in tmux)
# Press: Ctrl-a + Shift-I
```

### Update Plugins
```bash
# In tmux, press:
# Ctrl-a + Shift-U
```

## Configuration Files

### Main Configuration
- `~/dotfiles/tmux.conf`: Main tmux configuration

### Theme Files
- `~/.tmux/themes/starship-colors.conf`: Color scheme (Starship-inspired)

### Script Directory
- `~/.tmux/scripts/`: All status bar and utility scripts

### Cache Directory
- `~/.tmux/cache/`: Performance cache files (auto-managed)

## Plugins

### Configured Plugins
- **tmux-sensible**: Basic tmux settings everyone can agree on
- **tmux-resurrect**: Restore tmux environment after system restart
- **tmux-continuum**: Automatic tmux environment save/restore
- **tmux-yank**: Copy to system clipboard
- **tmux-fzf**: Fuzzy finder for tmux sessions/windows
- **tmux-copycat**: Enhanced search and copy

### Plugin Settings
- Auto-restore on tmux start (continuum)
- Vim/Neovim session strategy (resurrect)
- System clipboard integration (yank)

## Performance

### Caching Strategy
- **Git status**: Cached for 5 seconds per directory
- **Language versions**: Cached for 5 seconds per directory
- **Context detection**: Cached for 5 seconds per pane

### Cache Management
- Automatic cache validation
- Manual cache clear: `prefix + r`
- Cache files: `~/.tmux/cache/*.cache`

## Troubleshooting

### Status bar not showing
```bash
# Check if scripts are executable
ls -la ~/.tmux/scripts/

# Reload config
tmux source-file ~/.tmux.conf
```

### Plugins not working
```bash
# Reinstall plugins
~/.tmux/scripts/install-plugins.sh

# In tmux, press: Ctrl-a + Shift-I
```

### Performance issues
```bash
# Clear cache
find ~/.tmux/cache -type f -delete

# Reload config
tmux source-file ~/.tmux.conf
```

### Colors not displaying correctly
```bash
# Check terminal capabilities
echo $TERM
# Should be: tmux-256color (inside tmux) or xterm-256color (outside)

# Test true color support
curl -s https://raw.githubusercontent.com/JohnMorales/dotfiles/master/colors/24-bit-color.sh | bash
```

## Customization

### Modify Status Refresh Interval
Edit `tmux.conf`:
```bash
set -g status-interval 5  # Change from 5 to your preferred seconds
```

### Adjust Cache Duration
Edit cache scripts and modify:
```bash
CACHE_DURATION=5  # Change from 5 to your preferred seconds
```

### Customize Status Components
Edit `~/.tmux/scripts/responsive-status.sh` to add/remove status components.

### Change Color Theme
Edit `~/.tmux/themes/starship-colors.conf` to customize colors.

## License

Part of personal dotfiles configuration.

## Credits

- Inspired by [Starship prompt](https://starship.rs/)
- Built on [TPM (Tmux Plugin Manager)](https://github.com/tmux-plugins/tpm)
- Community plugins from [tmux-plugins](https://github.com/tmux-plugins)
