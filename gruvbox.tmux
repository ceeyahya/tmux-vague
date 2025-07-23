#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$CURRENT_DIR/src"

source $SCRIPTS_PATH/themes.sh

tmux set -g status-left-length 80
tmux set -g status-right-length 150

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"
# Highlight colors
tmux set -g mode-style "fg=${THEME[bgreen]},bg=${THEME[bblack]}"

tmux set -g message-style "bg=${THEME[blue]},fg=${THEME[background]}"
tmux set -g message-command-style "fg=${THEME[white]},bg=${THEME[black]}"

tmux set -g pane-border-style "fg=${THEME[bblack]}"
tmux set -g pane-active-border-style "fg=${THEME[blue]}"
tmux set -g pane-border-status off

tmux set -g status-style bg="${THEME[background]}"

TMUX_VARS="$(tmux show -g)"

default_window_id_style="digital"
default_pane_id_style="hsquare"
default_zoom_id_style="dsquare"
default_github_status="on"
default_session_bg="on"
default_window_center="off"

window_id_style="$(echo "$TMUX_VARS" | grep '@gruvbox-tmux_window_id_style' | cut -d" " -f2)"
pane_id_style="$(echo "$TMUX_VARS" | grep '@gruvbox-tmux_pane_id_style' | cut -d" " -f2)"
zoom_id_style="$(echo "$TMUX_VARS" | grep '@gruvbox-tmux_zoom_id_style' | cut -d" " -f2)"
github_status_enabled="$(echo "$TMUX_VARS" | grep '@gruvbox-tmux_github_status' | cut -d" " -f2)"
session_bg_enabled="$(echo "$TMUX_VARS" | grep '@gruvbox-tmux_session_bg' | cut -d" " -f2)"
window_center_enabled="$(echo "$TMUX_VARS" | grep '@gruvbox-tmux_window_center' | cut -d" " -f2)"
window_id_style="${window_id_style:-$default_window_id_style}"
pane_id_style="${pane_id_style:-$default_pane_id_style}"
zoom_id_style="${zoom_id_style:-$default_zoom_id_style}"
github_status_enabled="${github_status_enabled:-$default_github_status}"
session_bg_enabled="${session_bg_enabled:-$default_session_bg}"
window_center_enabled="${window_center_enabled:-$default_window_center}"

git_status="#($SCRIPTS_PATH/git-status.sh #{pane_current_path})"
if [[ "$github_status_enabled" == "on" ]]; then
    github_status="#($SCRIPTS_PATH/github-status.sh #{pane_current_path})"
else
    github_status=""
fi
window_number="#($SCRIPTS_PATH/custom-number.sh #I $window_id_style)"
custom_pane="#($SCRIPTS_PATH/custom-number.sh #P $pane_id_style)"
zoom_number="#($SCRIPTS_PATH/custom-number.sh #P $zoom_id_style)"
current_path="#($SCRIPTS_PATH/path-widget.sh #{pane_current_path})"

#+--- Bars LEFT ---+
# Session name
if [[ "$session_bg_enabled" == "on" ]]; then
    # Session name with background
    tmux set -g status-left "#[fg=${THEME[bblack]},bg=${THEME[blue]},bold] #{?client_prefix,󰠠 ,#[dim]󰤂 }#[bold,nodim]#S "
else
    # Session name without background (transparent)
    tmux set -g status-left "#[fg=${THEME[foreground]},bg=${THEME[background]},bold] #{?client_prefix,󰠠 ,#[dim] }#[bold,nodim]#S "
fi

#+--- Windows ---+
# Focus
tmux set -g window-status-current-format "$RESET#[fg=${THEME[green]},bg=${THEME[bblack]}] #{?#{==:#{pane_current_command},ssh},󰣀,} #[fg=${THEME[foreground]},bold,nodim]$window_number #W#[nobold]#{?window_zoomed_flag, $zoom_number, $custom_pane} #{?window_last_flag,,} "
# Unfocused
tmux set -g window-status-format "$RESET#[fg=${THEME[foreground]}] #{?#{==:#{pane_current_command},ssh},󰣀,}${RESET} $window_number #W#[nobold,dim]#{?window_zoomed_flag, $zoom_number, $custom_pane} #[fg=${THEME[yellow]}]#{?window_last_flag,󰁯 , } "

#+--- Bars RIGHT ---+
tmux set -g status-right "$current_path$git_status$github_status"
tmux set -g window-status-separator ""

#+--- Window Position ---+
if [[ "$window_center_enabled" == "on" ]]; then
    # Center the window list
    tmux set -g status-justify centre
else
    # Default left alignment
    tmux set -g status-justify left
fi
