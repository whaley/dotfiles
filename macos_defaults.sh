#!/usr/bin/env bash

########################################
# Window Management
########################################
# Click and drag from any border on the window -OR- Ctrl+Alt+Cmd+Click
defaults write -g NSWindowShouldDragOnGesture -bool true

# Disable automatic window opening animations
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false


########################################
# Finder
########################################
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Use list view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"


