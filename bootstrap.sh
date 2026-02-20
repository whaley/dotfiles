
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
    ln -nsf "${file}" "${HOME}/.${fileName}"
done

###############################################################################
# Symlink the scripts to $HOME/.local/bin
###############################################################################
TARGET_DIR="$HOME/.local/bin"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Symlink all files in the script's directory to the target directory
for file in "${SCRIPT_DIR}/bin"/*; do
    if [ -f "$file" ]; then
        ln -nsf "$file" "$TARGET_DIR/$(basename "$file")"
    fi
done
