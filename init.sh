#!/bin/bash

# Parse command line arguments
AUTO_YES=false
SHOW_HELP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -h|--help)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Show help if requested
if [ "$SHOW_HELP" = true ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Linux system initialization script"
    echo ""
    echo "OPTIONS:"
    echo "  -y, --yes    Automatically answer 'yes' to all prompts"
    echo "  -h, --help   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0           # Interactive mode (default)"
    echo "  $0 -y        # Auto-yes mode (no prompts)"
    echo ""
    exit 0
fi

# Helper: log actions
log() {
    echo "[init.sh] $1"
}
# Helper to get workspace path
WORKSPACE="$(dirname "$0")"

# Check for sudo privileges if not running as root
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo &>/dev/null; then
    SUDO="sudo"
    # Check for sudo privileges
    if ! sudo -v 2>/dev/null; then
        log "ERROR: This script requires sudo privileges for non-root users."
        exit 1
    fi
else
    log "ERROR: sudo is not installed. Please run as root or install sudo."
    exit 1
fi

# Helper: ask before running a section
ask_run() {
    local prompt="$1"
    if [ "$AUTO_YES" = true ]; then
        log "Auto-yes mode: $prompt [auto: y]"
        return 0
    fi
    read -p "$prompt [y/N]: " run_section
    [[ "$run_section" =~ ^[Yy]$ ]]
}

# Copy and backup .bashrc, .vimrc, .zshrc from workspace to home directory
if ask_run "Do you want to copy and backup shell config files (.bashrc, .vimrc, .zshrc)?"; then
    for rcfile in .bashrc .vimrc .zshrc; do
        src="$WORKSPACE/$rcfile"
        dest="$HOME/$rcfile"
        if [ -f "$src" ]; then
            if [ -f "$dest" ]; then
                # Backup existing config file with timestamp
                if mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"; then
                    log "Backed up $dest to $dest.bak.$(date +%Y%m%d%H%M%S)"
                else
                    log "Failed to backup $dest. Check permissions."
                fi
            fi
            # Copy new config file from workspace
            if cp -f "$src" "$dest"; then
                log "Copied $src to $dest (replaced if existed)"
            else
                log "Failed to copy $src! Check permissions or path."
            fi
        else
            log "$src not found in workspace, skipping copy."
        fi
    done

for rcfile in .bashrc .vimrc .zshrc; do
    dest="$HOME/$rcfile"
    if [ -f "$dest" ]; then
        chmod 600 "$dest" && log "Set permissions 600 on $dest" || log "Failed to set permissions on $dest"
    fi
done

else
    log "Skipping shell config file copy as per user request."
fi

# System update and auto-update setup (do this first for security)
if ask_run "Do you want to run system update and install packages?"; then
    if command -v apt-get &>/dev/null; then
        PKGS="tmux fzf tldr vim unattended-upgrades"
        log "Installing all packages: $PKGS"
        $SUDO apt-get update && $SUDO apt-get install -y $PKGS || log "apt-get install failed!"
        log "Running manual apt-get update/upgrade."
        $SUDO apt-get update && $SUDO apt-get upgrade -y || log "apt-get upgrade failed!"
        # Clean up package cache and remove unused packages to free disk space
        log "Cleaning up apt cache and removing unused packages."
        $SUDO apt-get autoremove -y && $SUDO apt-get clean || log "apt-get autoremove/clean failed!"
    elif command -v yum &>/dev/null; then
        PKGS="tmux fzf tldr vim yum-cron"
        log "Installing all packages: $PKGS"
        $SUDO yum install -y epel-release && $SUDO yum install -y $PKGS || log "yum install failed!"
        # Enable yum-cron for automatic updates if not already enabled
        if ! $SUDO systemctl is-enabled --quiet yum-cron; then
            $SUDO systemctl enable yum-cron && $SUDO systemctl start yum-cron
            log "Enabled and started yum-cron for automatic updates."
        fi
        log "Running manual yum update."
        $SUDO yum update -y || log "yum update failed!"
        # Clean up yum cache and remove unused packages
        log "Cleaning up yum cache."
        $SUDO yum autoremove -y && $SUDO yum clean all || log "yum autoremove/clean failed!"
    elif command -v dnf &>/dev/null; then
        PKGS="tmux fzf tldr vim dnf-automatic"
        log "Installing all packages: $PKGS"
        $SUDO dnf install -y $PKGS || log "dnf install failed!"
        # Enable dnf-automatic for automatic updates if not already enabled
        if ! $SUDO systemctl is-enabled --quiet dnf-automatic.timer; then
            $SUDO systemctl enable dnf-automatic.timer && $SUDO systemctl start dnf-automatic.timer
            log "Enabled and started dnf-automatic.timer for automatic updates."
        fi
        log "Running manual dnf upgrade."
        $SUDO dnf upgrade -y || log "dnf upgrade failed!"
        # Clean up dnf cache and remove unused packages
        log "Cleaning up dnf cache."
        $SUDO dnf autoremove -y && $SUDO dnf clean all || log "dnf autoremove/clean failed!"
    elif command -v pacman &>/dev/null; then
        PKGS="tmux fzf tldr vim pacman-contrib"
        log "Installing all packages: $PKGS"
        $SUDO pacman -Sy --noconfirm $PKGS || log "pacman install failed!"
        if ! systemctl is-enabled --quiet paccache.timer 2>/dev/null; then
            log "Enabling paccache.timer for automatic updates."
            $SUDO systemctl enable paccache.timer && $SUDO systemctl start paccache.timer
        fi
        log "Running manual pacman upgrade."
        $SUDO pacman -Syu --noconfirm || log "pacman upgrade failed!"
        # Clean up pacman cache
        log "Cleaning up pacman cache."
        $SUDO pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || log "pacman autoremove failed or no orphan packages."
        $SUDO pacman -Scc --noconfirm || log "pacman clean cache failed!"
    elif command -v brew &>/dev/null; then
        PKGS="tmux fzf tldr vim"
        log "Using Homebrew to install packages."
        brew install $PKGS || log "brew install failed!"
        # Clean up Homebrew cache
        log "Cleaning up Homebrew cache."
        brew cleanup || log "brew cleanup failed!"
    else
        log "Unsupported package manager. Please install required packages manually: tmux, fzf, tldr, vim, fail2ban, auto-update tools."
    fi
else
    log "Skipping system update and package install as per user request."
fi

# Setup tldr cache for command help
if ask_run "Do you want to update tldr cache for command help?"; then
    if command -v tldr &>/dev/null; then
        log "Updating tldr cache."
        tldr --update || log "tldr --update failed!"
    else
        log "tldr not found, skipping cache update."
    fi
else
    log "Skipping tldr cache update as per user request."
fi


# Configure fzf for bash, zsh, vim, and tmux
if ask_run "Do you want to configure fzf for bash and zsh?"; then
    # Enable fzf for bash
    for fzf_dir in \
        "/usr/share/fzf" \
        "/usr/local/share/fzf" \
        "/usr/share/doc/fzf/examples" \
        "$HOME/.fzf/shell"; do
        key_file="$fzf_dir/key-bindings.bash"
        comp_file="$fzf_dir/completion.bash"
        if [ -f "$key_file" ] && [ -f ~/.bashrc ]; then
            if ! grep -Fxq "source $key_file" ~/.bashrc; then
                echo -e "\nsource $key_file" >> ~/.bashrc
                log "Added fzf key-bindings.bash from $fzf_dir to .bashrc"
            fi
        fi
        if [ -f "$comp_file" ] && [ -f ~/.bashrc ]; then
            if ! grep -Fxq "source $comp_file" ~/.bashrc; then
                echo -e "\nsource $comp_file" >> ~/.bashrc
                log "Added fzf completion.bash from $fzf_dir to .bashrc"
            fi
        fi
    done

    # Enable fzf for zsh
    for fzf_dir in \
        "/usr/share/fzf" \
        "/usr/local/share/fzf" \
        "/usr/share/doc/fzf/examples" \
        "$HOME/.fzf/shell"; do
        key_file="$fzf_dir/key-bindings.zsh"
        comp_file="$fzf_dir/completion.zsh"
        if [ -f "$key_file" ] && [ -f ~/.zshrc ]; then
            if ! grep -Fxq "source $key_file" ~/.zshrc; then
                echo -e "\nsource $key_file" >> ~/.zshrc
                log "Added fzf key-bindings.zsh from $fzf_dir to .zshrc"
            fi
        fi
        if [ -f "$comp_file" ] && [ -f ~/.zshrc ]; then
            if ! grep -Fxq "source $comp_file" ~/.zshrc; then
                echo -e "\nsource $comp_file" >> ~/.zshrc
                log "Added fzf completion.zsh from $fzf_dir to .zshrc"
            fi
        fi
    done
else
    log "Skipping fzf configuration as per user request."
fi