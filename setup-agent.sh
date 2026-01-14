#!/usr/bin/env bash
#
# setup-agent.sh - Install AGENT.md for Claude Code and Gemini CLI
#
# Creates symlinks in ~/.claude/ and ~/.gemini/ pointing to your AGENT.md file,
# enabling both CLIs to automatically load your agent instructions globally.
#
# Usage:
#   ./setup-agent.sh [OPTIONS]
#
# Options:
#   --source PATH   Path to AGENT.md (default: ./AGENT.md)
#   --uninstall     Remove installed symlinks
#   --help          Show this help message

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SOURCE_FILE="./AGENT.md"
UNINSTALL=false

# Target locations
CLAUDE_DIR="$HOME/.claude"
GEMINI_DIR="$HOME/.gemini"
CLAUDE_TARGET="$CLAUDE_DIR/CLAUDE.md"
GEMINI_TARGET="$GEMINI_DIR/GEMINI.md"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Install AGENT.md for Claude Code and Gemini CLI globally.

Options:
  --source PATH   Path to AGENT.md (default: ./AGENT.md)
  --uninstall     Remove installed symlinks
  --help          Show this help message

Examples:
  $(basename "$0")                    # Install from ./AGENT.md
  $(basename "$0") --source ~/agent/AGENT.md
  $(basename "$0") --uninstall        # Remove symlinks
EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Backup existing file if it exists and is not a symlink
backup_if_exists() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warn "Backing up existing file: $target -> $backup"
        mv "$target" "$backup"
    elif [[ -L "$target" ]]; then
        log_info "Removing existing symlink: $target"
        rm "$target"
    fi
}

# Create symlink with verification
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    # Create parent directory if needed
    local target_dir
    target_dir=$(dirname "$target")
    if [[ ! -d "$target_dir" ]]; then
        log_info "Creating directory: $target_dir"
        mkdir -p "$target_dir"
    fi

    # Backup existing file
    backup_if_exists "$target"

    # Create symlink
    ln -s "$source" "$target"

    # Verify
    if [[ -L "$target" && -r "$target" ]]; then
        log_success "$name: $target -> $source"
        return 0
    else
        log_error "Failed to create symlink for $name"
        return 1
    fi
}

# Remove symlink if it exists
remove_symlink() {
    local target="$1"
    local name="$2"

    if [[ -L "$target" ]]; then
        rm "$target"
        log_success "Removed $name symlink: $target"
    elif [[ -e "$target" ]]; then
        log_warn "$name exists but is not a symlink: $target (skipped)"
    else
        log_info "$name symlink not found: $target (nothing to remove)"
    fi
}

install() {
    local source_abs

    # Validate source file exists
    if [[ ! -f "$SOURCE_FILE" ]]; then
        log_error "Source file not found: $SOURCE_FILE"
        exit 1
    fi

    # Get absolute path
    source_abs=$(cd "$(dirname "$SOURCE_FILE")" && pwd)/$(basename "$SOURCE_FILE")
    log_info "Source: $source_abs"

    echo ""
    log_info "Installing agent instructions globally..."
    echo ""

    # Install for Claude Code
    create_symlink "$source_abs" "$CLAUDE_TARGET" "Claude Code"

    # Install for Gemini CLI
    create_symlink "$source_abs" "$GEMINI_TARGET" "Gemini CLI"

    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Your AGENT.md is now loaded by:"
    echo "  - Claude Code (claude command)"
    echo "  - Gemini CLI (gemini command)"
    echo ""
    echo "To verify, run: ls -la ~/.claude/CLAUDE.md ~/.gemini/GEMINI.md"
}

uninstall() {
    echo ""
    log_info "Removing agent symlinks..."
    echo ""

    remove_symlink "$CLAUDE_TARGET" "Claude Code"
    remove_symlink "$GEMINI_TARGET" "Gemini CLI"

    echo ""
    log_success "Uninstall complete!"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            SOURCE_FILE="$2"
            shift 2
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main
if [[ "$UNINSTALL" == true ]]; then
    uninstall
else
    install
fi
