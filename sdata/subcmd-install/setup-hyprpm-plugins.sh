#!/usr/bin/env bash
# This script sets up hyprpm plugins for Hyprland
# Note: Actual plugin setup happens via first-run script on first Hyprland start

# Source common functions and variables (REPO_ROOT is set by the main setup script)
source "${REPO_ROOT}/sdata/lib/functions.sh"

setup_hyprpm_plugins() {
  printf "${STY_CYAN}[$0]: hyprpm plugin setup...${STY_RST}\n"
  
  # Check if hyprpm is available
  if ! command -v hyprpm > /dev/null 2>&1; then
    printf "${STY_YELLOW}[$0]: hyprpm not found. Skipping.${STY_RST}\n"
    return 0
  fi
  
  # Update headers (requires sudo, handled by keepalive)
  # This works even if Hyprland is not running (it fetches headers for the installed hyprland binary)
  printf "${STY_CYAN}[$0]: Installing Hyprland headers (hyprpm update)...${STY_RST}\n"
  hyprpm update 2>/dev/null || true
  
  # Check if Hyprland is running
  if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    printf "${STY_BLUE}[$0]: Hyprland is not running. Plugin installation deferred to first startup.${STY_RST}\n"
    printf "${STY_BLUE}[$0]: (Headers have been installed to speed up the first run.)${STY_RST}\n"
    return 0
  fi

  # If Hyprland IS running, we can proceed with full setup
  printf "${STY_CYAN}[$0]: Hyprland is running. Proceeding with plugin setup...${STY_RST}\n"

  # Add the plugin repository
  printf "${STY_CYAN}[$0]: Adding hyprland-plugins repo...${STY_RST}\n"
  hyprpm add https://github.com/hyprwm/hyprland-plugins 2>/dev/null || true

  # Build the plugins
  printf "${STY_CYAN}[$0]: compiling plugins (hyprpm update)...${STY_RST}\n"
  hyprpm update 2>/dev/null || true
  
  # Enable plugins
  printf "${STY_CYAN}[$0]: Enabling plugins...${STY_RST}\n"
  if hyprpm enable hyprbars 2>/dev/null; then
    printf "${STY_GREEN}[$0]: ✓ Hyprbars enabled!${STY_RST}\n"
    hyprpm reload -n 2>/dev/null || true
  fi
    
  # Mark as complete
  mkdir -p "$HOME/.config/illogical-impulse"
  touch "$HOME/.config/illogical-impulse/hyprpm_setup_done"
  
  return 0
}

# Run the setup function (don't use v/x to avoid sudo prompts)
showfun setup_hyprpm_plugins
setup_hyprpm_plugins
