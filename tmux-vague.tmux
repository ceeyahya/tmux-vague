#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$CURRENT_DIR/src"

source $SCRIPTS_PATH/themes.sh

tmux set -g status-left-length 80
tmux set -g status-right-length 150

RESET="#[fg=${THEME_foreground},bg=${THEME_background},nobold,noitalics,nounderscore,nodim]"
# Highlight colors
tmux set -g mode-style "fg=${THEME_bgreen},bg=${THEME_bblack}"
tmux set -g message-style "bg=${THEME_blue},fg=${THEME_background}"
tmux set -g message-command-style "fg=${THEME_white},bg=${THEME_black}"
tmux set -g pane-border-style "fg=${THEME_bblack}"
tmux set -g pane-active-border-style "fg=${THEME_blue}"
tmux set -g pane-border-status off
tmux set -g status-style bg="${THEME_background}"

TMUX_VARS="$(tmux show -g)"

default_window_id_style="none"
default_pane_id_style="hsquare"
default_zoom_id_style="dsquare"
default_github_status="on"

window_id_style="$(echo "$TMUX_VARS" | grep '@tmux-vague_window_id_style' | cut -d" " -f2)"
pane_id_style="$(echo "$TMUX_VARS" | grep '@tmux-vague_pane_id_style' | cut -d" " -f2)"
zoom_id_style="$(echo "$TMUX_VARS" | grep '@tmux-vague_zoom_id_style' | cut -d" " -f2)"
github_status_enabled="$(echo "$TMUX_VARS" | grep '@tmux-vague_github_status' | cut -d" " -f2)"
session_bg_enabled="$(echo "$TMUX_VARS" | grep '@tmux-vague_session_bg' | cut -d" " -f2)"
window_center_enabled="$(echo "$TMUX_VARS" | grep '@tmux-vague_window_center' | cut -d" " -f2)"
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
tmux set -g status-left "#[fg=${THEME_background},bg=${THEME_green},bold] #{?client_prefix,󰠠 ,#[dim]󰤂 }#[bold,nodim]#S "

#+--- Windows ---+
# Focus
tmux set -g window-status-current-format "$RESET#[fg=${THEME_background},bg=${THEME_green}] #{?#{==:#{pane_current_command},ssh},󰣀,} #[fg=${THEME_background},bold,nodim]$window_number #W#[nobold]#{?window_zoomed_flag, $zoom_number, $custom_pane} #{?window_last_flag,,} "
# Unfocused
tmux set -g window-status-format "$RESET#[fg=${THEME_foreground}] #{?#{==:#{pane_current_command},ssh},󰣀,}${RESET} $window_number #W#[nobold,dim]#{?window_zoomed_flag, $zoom_number, $custom_pane} #[fg=${THEME_yellow}]#{?window_last_flag,󰁯 , } "

#+--- Bars RIGHT ---+
tmux set -g status-right "$current_path$git_status$github_status"
tmux set -g window-status-separator ""
tmux set -g status-justify left
