
#!/usr/bin/env bash

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null
SCRIPT_DIR="$(pwd)"
popd > /dev/null


###############################################################################
# Install stuff from Brew
###############################################################################
if ! command -v brew &> /dev/null; then
    echo "Error: brew not found on PATH."
else
    brew bundle install --file "${SCRIPT_DIR}/Brewfile"
fi

###############################################################################
# Execute macos_defaults
###############################################################################
${SCRIPT_DIR}/macos_defaults.sh


###############################################################################
# Symlink to $HOME
###############################################################################
for file in ${SCRIPT_DIR}/home/*; do
    fileName=$(basename $file)
    # config/ is handled below, per-directory, so we don't clobber ~/.config
    [ "$fileName" = "config" ] && continue
    ln -nsf "${file}" "${HOME}/.${fileName}"
done

###############################################################################
# Symlink to $XDG_CONFIG_HOME (~/.config)
###############################################################################
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "${CONFIG_DIR}"

for dir in "${SCRIPT_DIR}/home/config"/*; do
    dirName=$(basename "$dir")
    target="${CONFIG_DIR}/${dirName}"

    # Move an existing real directory out of the way before linking
    if [ -d "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "${target}.bak.$(date +%Y%m%d%H%M%S)"
    fi
    ln -nsf "$dir" "$target"
done

###############################################################################
# Symlink the scripts to $HOME/.local/bin
#
# Note: XDG defines no variable for the user bin dir (only XDG_DATA_HOME etc.),
# so XDG_BIN_HOME is a convention, not spec. Falls back to the standard path.
###############################################################################
TARGET_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Symlink all files in the script's directory to the target directory
for file in "${SCRIPT_DIR}/bin"/*; do
    if [ -f "$file" ]; then
        ln -nsf "$file" "$TARGET_DIR/$(basename "$file")"
    fi
done
