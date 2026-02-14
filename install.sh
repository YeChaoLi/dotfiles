#!/bin/bash
# Dotfiles bootstrap: packages + Oh My Zsh + plugins + symlinks.
# Usage: ./install.sh [--no-chsh]

set -e
DOTFILES_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_ROOT"

# --- 1. 依赖包 (按发行版) ---
install_packages() {
  echo "==> Installing packages..."
  if [ -f /etc/os-release ]; then
    source /etc/os-release
  else
    echo "Cannot detect distro (no /etc/os-release). Skip packages."
    return 0
  fi

  case "$ID" in
    ubuntu|debian)
      echo "==> Updating system (apt update + full-upgrade)..."
      sudo apt-get update
      sudo apt-get full-upgrade -y
      echo "==> Installing packages..."
      sudo apt-get install -y git vim zsh tmux curl build-essential \
        fzf fd-find ripgrep
      ;;
    rocky|centos|rhel|fedora)
      sudo dnf install -y git zsh tmux curl gcc gcc-c++ \
        fzf ripgrep
      # fd-find -> fd in Fedora
      sudo dnf install -y fd-find 2>/dev/null || sudo dnf install -y fd 2>/dev/null || true
      ;;
    arch)
      sudo pacman -Sy --noconfirm git zsh tmux curl base-devel fzf fd ripgrep
      ;;
    *)
      echo "Unsupported distro: $ID. Install git/zsh/tmux/curl manually."
      ;;
  esac
}

# --- 2. Oh My Zsh ---
install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "==> Oh My Zsh already installed, skip."
    return 0
  fi
  echo "==> Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

# --- 3. Zsh 插件 (OMZ custom plugins) ---
ZSH_PLUGINS=(
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-syntax-highlighting"
  "https://github.com/zsh-users/zsh-completions"
)
install_zsh_plugins() {
  [ -z "$ZSH" ] && export ZSH="$HOME/.oh-my-zsh"
  local custom_plugins="$ZSH/custom/plugins"
  mkdir -p "$custom_plugins"

  for url in "${ZSH_PLUGINS[@]}"; do
    name="${url##*/}"
    if [ -d "$custom_plugins/$name" ]; then
      echo "  Plugin $name exists, skip."
    else
      echo "==> Installing plugin: $name"
      git clone --depth 1 "$url" "$custom_plugins/$name"
    fi
  done
}

# --- 4. 可选: zoxide (智能 cd) ---
install_zoxide() {
  if command -v zoxide &>/dev/null; then
    echo "==> zoxide already installed, skip."
    return 0
  fi
  echo "==> Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  # 安装脚本会把 binary 放到 ~/.local/bin，确保在 PATH 里
  export PATH="$HOME/.local/bin:$PATH"
}

# --- 5. 软链接 dotfiles ---
# 格式: "repo相对路径:目标路径" 或 "repo相对路径" (则目标为 ~/.同名)
LINKS=(
  "shell/.zshrc:.zshrc"
  "shell/.env.zsh:.env.zsh"
  "shell/.aliases.zsh:.aliases.zsh"
  "git/.gitconfig:.gitconfig"
)
link_dotfiles() {
  echo "==> Linking dotfiles..."
  for spec in "${LINKS[@]}"; do
    if [[ "$spec" == *:* ]]; then
      src="${spec%%:*}"
      dest="${spec#*:}"
    else
      src="$spec"
      dest="$HOME/.${spec##*/}"
    fi
    src_abs="$DOTFILES_ROOT/$src"
    [ ! -e "$src_abs" ] && { echo "  Skip (missing): $src"; continue; }
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src_abs" "$dest"
    echo "  $src -> $dest"
  done
}

# --- 6. 设置默认 shell ---
set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh 2>/dev/null)" || true
  if [ -z "$zsh_path" ]; then
    echo "==> zsh not found, skip chsh."
    return 0
  fi
  if [ "$(basename "$SHELL")" = "zsh" ]; then
    echo "==> Default shell is already zsh."
    return 0
  fi
  echo "==> Set default shell to zsh? (chsh -s $zsh_path)"
  read -r -p "Run chsh? [y/N] " ans
  case "$ans" in
    [yY]*) chsh -s "$zsh_path" ;;
    *) echo "  Skipped. Run: chsh -s \$(which zsh)" ;;
  esac
}

# --- main ---
install_packages
install_oh_my_zsh
install_zsh_plugins
install_zoxide
link_dotfiles

if [[ " $* " != *" --no-chsh "* ]]; then
  set_default_shell
fi

echo ""
echo "Done. Open a new terminal or run: exec zsh"
echo "Tip: review ~/.gitconfig for user/email and proxy."
