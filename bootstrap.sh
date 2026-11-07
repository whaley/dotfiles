#!/usr/bin/env bash

# Exit on any failure (including inside pipelines and functions) and report what failed
set -eE -o pipefail
trap 'rc=$?; echo "Error: command failed (exit ${rc}) at line ${LINENO}: ${BASH_COMMAND}" >&2; exit ${rc}' ERR

###############################################################################
# Get sudo up front so brew casks don't stall mid-run on a password prompt
###############################################################################
echo "==> Requesting sudo (some brew casks need it)"
printf '\a'
sudo -v

# Keep the sudo timestamp fresh until this script exits
while true; do
    sudo -n true || exit
    sleep 60
    kill -0 "$$" 2> /dev/null || exit
done &
SUDO_KEEPALIVE_PID=$!
trap 'kill "${SUDO_KEEPALIVE_PID}" 2> /dev/null' EXIT

###############################################################################
# Base all paths from where the script exists
###############################################################################
pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null
SCRIPT_DIR="$(pwd)"
popd > /dev/null


###############################################################################
# Install stuff from Brew
###############################################################################
echo "==> Installing packages from Brewfile"
if ! command -v brew &> /dev/null; then
    echo "Error: brew not found on PATH."
else
    brew bundle install --file "${SCRIPT_DIR}/Brewfile"
fi

###############################################################################
# Execute macos_defaults
###############################################################################
echo "==> Applying macOS defaults"
${SCRIPT_DIR}/macos_defaults.sh


###############################################################################
# Symlink to $HOME
###############################################################################
echo "==> Symlinking dotfiles into ${HOME}"
for file in ${SCRIPT_DIR}/home/*; do
    fileName=$(basename $file)
    # config/ is handled below, per-directory, so we don't clobber ~/.config
    [ "$fileName" = "config" ] && continue
    echo "    ${HOME}/.${fileName} -> ${file}"
    ln -nsf "${file}" "${HOME}/.${fileName}"
done

###############################################################################
# Symlink to $XDG_CONFIG_HOME (~/.config)
###############################################################################
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
echo "==> Symlinking config directories into ${CONFIG_DIR}"
mkdir -p "${CONFIG_DIR}"

for dir in "${SCRIPT_DIR}/home/config"/*; do
    dirName=$(basename "$dir")
    target="${CONFIG_DIR}/${dirName}"

    # Move an existing real directory out of the way before linking
    if [ -d "$target" ] && [ ! -L "$target" ]; then
        backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        echo "    Backing up existing ${target} to ${backup}"
        mv "$target" "$backup"
    fi
    echo "    ${target} -> ${dir}"
    ln -nsf "$dir" "$target"
done

###############################################################################
# Symlink the scripts to $HOME/.local/bin
#
# Note: XDG defines no variable for the user bin dir (only XDG_DATA_HOME etc.),
# so XDG_BIN_HOME is a convention, not spec. Falls back to the standard path.
###############################################################################
TARGET_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
echo "==> Symlinking scripts into ${TARGET_DIR}"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Symlink all files in the script's directory to the target directory
for file in "${SCRIPT_DIR}/bin"/*; do
    if [ -f "$file" ]; then
        echo "    ${TARGET_DIR}/$(basename "$file") -> ${file}"
        ln -nsf "$file" "$TARGET_DIR/$(basename "$file")"
    fi
done

echo "==> Bootstrap complete"
