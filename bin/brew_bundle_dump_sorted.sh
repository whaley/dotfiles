#!/usr/bin/env bash

# Original credit to https://github.com/Homebrew/homebrew-bundle/issues/1263#issuecomment-1808716156
# I just copied/pasted/tweaked

BREW_TYPES=(
    tap
    brew
    cask
    mas
)

TMP_FILE=$(mktemp)
SCRIPT_DIR=$(dirname "$0")
BREW_FILE="${SCRIPT_DIR}/../Brewfile"

# update homebrew list
brew bundle dump --force --file $TMP_FILE

# sort the final output
## clear current contents
> $BREW_FILE
for type in ${BREW_TYPES[@]}; do
    ## extract lines starting with "type" and sort them
    grep "^${type}" $TMP_FILE | sort >> $BREW_FILE
done
