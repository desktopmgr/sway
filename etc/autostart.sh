#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202304262254-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.com
# @@License          :  WTFPL
# @@ReadME           :  autostart.sh --help
# @@Copyright        :  Copyright: (c) 2023 Jason Hempstead, Casjays Developments
# @@Created          :  Wednesday, Apr 26, 2023 22:54 EDT
# @@File             :  autostart.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/autostart
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC2317
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="$(basename "$0" 2>/dev/null)"
VERSION="202304262254-git"
HOME="${USER_HOME:-$HOME}"
USER="${SUDO_USER:-$USER}"
RUN_USER="${SUDO_USER:-$USER}"
SCRIPT_SRC_DIR="${BASH_SOURCE%/*}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# bash options
set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set functions
__is_running() { __get_pid "$1" &>/dev/null && return 0 || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__is_stopped() { __get_pid "$1" &>/dev/null && return 1 || return 0; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__get_pid() { ps -ux | grep " $1" | grep -v 'grep ' | awk '{print $2}' | grep '^[0-9].*[0-9]' || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# kill running
__silent_kill() {
  if [ $# -gt 1 ]; then
    eval "$*" &>/dev/null
    exitCode=$?
    sleep .5
  else
    __is_running "$1" && kill -9 "$(__get_pid "$1")" >/dev/null 2>&1
    exitCode=$?
    sleep 1
  fi
  return ${exitCode:-0}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check if command exists
__does_cmd_exist() {
  unalias "$1" >/dev/null 2>&1
  for cmd in "$@"; do
    command -v "$1" >/dev/null 2>&1 && true || false
  done
  return $?
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start command
__silent_start() {
  local CMD="$1" && shift 1
  local ARGS="$*" && shift $#
  sleep .2
  eval $CMD $ARGS &>/dev/null &
  disown
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# test if session matches
__desktop_name() {
  [ "$DESKTOP_SESSION_LOAD_PANEL" = "no" ] || return 0
  for desktops in "$@"; do
    [ "$DESKTOP_SESSION" = "$desktops" ] && return 0 || false
  done
  return 1
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# show help
if [ "$1" = "help" ] || [ "$1" = "-help" ] || [ "$1" = "--help" ]; then
  printf "\n%s\n" "Usage: $PROG" "Starts applications for sway window manager"
  exit
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# exit if not Linux or no display
[ "$(uname -s)" = "Linux" ] || [ -n "$DISPLAY" ] || exit 0
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# force the loading of a custom panel
DESKTOP_SESSION_LOAD_PANEL="no"
DESKTOP_SESSION_PANEL_NAME=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set desktop session
DESKTOP_SESSION="${DESKTOP_SESSION:-sway}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set config dir
DESKTOP_SESSION_CONFDIR="$HOME/.config/$DESKTOP_SESSION"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set auto start directory
DESKTOP_SESSION_START_DIR="$DESKTOP_SESSION_CONFDIR/autostart.d"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# vmware tools
if __does_cmd_exist vmware-user-suid-wrapper && __is_stopped vmware-user-suid-wrapper; then
  __silent_kill vmware-user-suid-wrapper
  __silent_start vmware-user-suid-wrapper
fi
if __does_cmd_exist vmware-user && __is_stopped vmware-user; then
  __silent_kill vmware-user
  __silent_start vmware-user
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set resolution
if __does_cmd_exist xrandr && [ -n "$DISPLAY" ]; then
  RESOLUTION="$(xrandr --current | grep -F '*' | uniq | awk '{print $1}')"
  PRIMARY_SCREEN="$(xrandr --listmonitors | grep -F '*' | awk '{print $NF}')"
  if [ -x "$HOME/.config/screenlayout/$RESOLUTION.sh" ]; then
    . "$HOME/.config/screenlayout/$RESOLUTION.sh"
  elif [ -x "$HOME/.config/screenlayout/default.sh" ]; then
    . "$HOME/.config/screenlayout/default.sh"
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# export setting
export SUDO_ASKPASS DESKTOP_SESSION DESKTOP_SESSION_CONFDIR RESOLUTION
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# sudo password using dmenu
#__does_cmd_exist ask_for_password && SUDO_ASKPASS="/usr/local/bin/ask_for_password"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# test for an existing dbus daemon, just to be safe
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  if __does_cmd_exist dbus-launch; then
    dbus_args="--sh-syntax --exit-with-session "
    case "$DESKTOP_SESSION" in
    awesome) dbus_args+="awesome " ;;
    bspwm) dbus_args+="bspwm " ;;
    i3 | i3wm) dbus_args+="i3 --shmlog-size 0 " ;;
    dwm) dbus_args+="dwm " ;;
    jwm) dbus_args+="jwm " ;;
    lxde) dbus_args+="startlxde " ;;
    lxqt) dbus_args+="lxqt-session " ;;
    openbox) dbus_args+="openbox-session " ;;
    sway) dbus_args+="sway " ;;
    xfce) dbus_args+="xfce4-session " ;;
    xmonad) dbus_args+="xmonad " ;;
    *) dbus_args+="$DEFAULT_SESSION" ;;
    esac
    __silent_kill dbus-launch
    __silent_start dbus-launch "${dbus_args[*]}"
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start window compositor
if __does_cmd_exist picom; then
  __silent_kill picom
  __silent_start picom -b --config "$DESKTOP_SESSION_CONFDIR/compton.conf"
elif __does_cmd_exist compton; then
  __silent_kill compton
  __silent_start compton -b --config "$DESKTOP_SESSION_CONFDIR/compton.conf"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# key bindings via sxhkd
if __does_cmd_exist sxhkd run_sxhkd; then
  __silent_kill sxhkd
  __silent_start run_sxhkd --start
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Panel - not needed for awesome i3 qtile sway xmonad
if ! __desktop_name "awesome" "i3" "qtile" "sway" "xmonad"; then
  if [ -n "$DESKTOP_SESSION_PANEL_NAME" ] && __does_cmd_exist "$DESKTOP_SESSION_PANEL_NAME"; then
    __silent_kill "$DESKTOP_SESSION_PANEL_NAME"
    __silent_start "$DESKTOP_SESSION_PANEL_NAME"
  elif __is_stopped xfce4-panel; then
    if __does_cmd_exist polybar; then
      __silent_kill polybar
      __silent_start "$HOME/.config/polybar/launch.sh"
    elif __does_cmd_exist tint2; then
      __silent_kill tint2
      __silent_start tint2 -c "$HOME/.config/tint2/tint2rc"
    elif __does_cmd_exist lemonbar; then
      __silent_kill lemonbar
      __silent_start "$HOME/.config/lemonbar/lemonbar.sh"
    else
      PANEL="none"
    fi
    if [ "$PANEL" = "none" ] && __does_cmd_exist xfce4-session xfce4-panel; then
      __silent_kill xfce4-panel
      __silent_start xfce4-panel
    fi
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Plank
if __does_cmd_exist plank && __is_stopped plank; then
  __silent_kill plank
  __silent_start plank
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# setup keyboard
if __does_cmd_exist ibus-daemon; then
  __silent_kill ibus-daemon
  __silent_start ibus-daemon --xim -d
elif __does_cmd_exist ibus; then
  __silent_kill ibus
  __silent_start ibus start --type=direct
elif __does_cmd_exist fcitx; then
  __silent_kill fcitx
  __silent_start fcitx
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# enable control+alt+backspace
if __does_cmd_exist setxkbmap; then
  __silent_kill setxkbmap
  __silent_start setxkbmap -model pc104 -layout us -option "terminate:ctrl_alt_bksp"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# xsettings
if __does_cmd_exist xsettingsd; then
  __silent_kill xsettingsd
  __silent_start xsettingsd -c "$DESKTOP_SESSION_CONFDIR/xsettingsd.conf"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Authentication dialog
# ubuntu
if [ -f "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1" ]; then
  __silent_kill polkit-gnome-authentication-agent-1
  __silent_start "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
# Fedora
elif [ -f "/usr/libexec/polkit-gnome-authentication-agent-1" ]; then
  __silent_kill polkit-gnome-authentication-agent-1
  __silent_start "/libexec/polkit-gnome-authentication-agent-1"
# Arch
elif [ -f "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" ]; then
  __silent_kill polkit-gnome-authentication-agent-1
  __silent_start "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Notification daemon
if [ -f "/usr/lib/xfce4/notifyd/xfce4-notifyd" ]; then
  __silent_kill xfce4-notifyd
  __silent_start "/usr/lib/xfce4/notifyd/xfce4-notifyd"
elif [ -f "/usr/lib/x86_64-linux-gnu/xfce4/notifyd/xfce4-notifyd" ]; then
  __silent_kill xfce4-notifyd
  __silent_start "/usr/lib/x86_64-linux-gnu/xfce4/notifyd/xfce4-notifyd"
elif __does_cmd_exist "xfce4-notifyd"; then
  __silent_kill xfce4-notifyd
  __silent_start xfce4-notifyd
elif __does_cmd_exist dunst; then
  __silent_kill dunst
  __silent_start dunst
elif __does_cmd_exist deadd-notification-center; then
  __silent_kill deadd-notification-center
  __silent_start deadd-notification-center
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# start conky
if __does_cmd_exist conky; then
  __silent_kill conky
  __silent_start conky -c "$DESKTOP_SESSION_CONFDIR/conky.conf"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Wallpaper manager
if __does_cmd_exist randomwallpaper && __is_stopped randomwallpaper; then
  __silent_start randomwallpaper bg start
elif __does_cmd_exist variety; then
  __silent_kill variety
  __silent_start variety
elif __does_cmd_exist feh; then
  __silent_kill feh
  __silent_start feh --bg-fill "${WALLPAPER_DIR:-$HOME/.local/share/wallpapers}/system/default.jpg"
elif __does_cmd_exist nitrogen; then
  __silent_kill nitrogen
  __silent_start nitrogen --restore
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Network Manager
if __does_cmd_exist nm-applet; then
  __silent_kill nm-applet
  __silent_start nm-applet
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Package Manager
if __does_cmd_exist check-for-updates; then
  __silent_kill check-for-updates
  __silent_start check-for-updates
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# bluetooth
if __does_cmd_exist blueberry-tray; then
  __silent_kill blueberry-tray
  __silent_start blueberry-tray
elif __does_cmd_exist blueman-applet; then
  __silent_kill blueman-applet
  __silent_start blueman-applet
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# num lock activated
if __does_cmd_exist numlockx && __is_stopped numlockx; then
  __silent_kill numlockx
  __silent_start numlockx on
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# volume
if __does_cmd_exist volumeicon && __is_stopped volumeicon; then
  __silent_kill volumeicon
  __silent_start volumeicon
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# clipman
if __does_cmd_exist xfce4-clipman && __is_stopped xfce4-clipman; then
  __silent_kill xfce4-clipman
  __silent_start xfce4-clipman
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PowerManagement
if __does_cmd_exist xfce4-power-manager; then
  __silent_kill xfce4-power-manager
  __silent_start xfce4-power-manager
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Session used if you want xfce4
if __does_cmd_exist xfce4-session && __desktop_name "xfce4"; then
  __silent_kill xfce4-session
  __silent_start xfce4-session
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Screenkey
#if __does_cmd_exist screenkey ; then
#    __silent_kill screenkey
#    __silent_start screenkey
#fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# mpd
if { [ -z "$MPDSERVER" ] || [ "$MPDSERVER" = "localhost" ]; } && __does_cmd_exist mpd && __is_stopped mpd; then
  __silent_kill mpd
  __silent_start mpd
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# bittorrent client
if __does_cmd_exist transmission-daemon && __is_stopped transmission-daemon; then
  __silent_start transmission-daemon
fi
if __does_cmd_exist mytorrent && __is_stopped "${MYTORRENT:-$TORRENT}"; then
  __silent_kill mytorrent
  __silent_start mytorrent
elif __does_cmd_exist transmission-remote-gtk && __is_stopped transmission-remote-gtk && __is_running transmission-daemon; then
  __silent_start transmission-remote-gtk -m
elif __does_cmd_exist transmission-gtk && __is_stopped transmission-gtk; then
  __silent_start transmission-gtk -m
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# additional apps to start
if [ -d "$DESKTOP_SESSION_START_DIR" ]; then
  for autostart_script in "$DESKTOP_SESSION_START_DIR"/*.sh; do
    if [ -f "$autostart_script" ]; then . "$autostart_script"; fi
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Welcome Message
if __does_cmd_exist notifications; then
  sleep 90 && notifications "$DESKTOP_SESSION" "Welcome $USER to the $DESKTOP_SESSION Desktop" &
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Unset uneeded functions and variables
unset autostart_script DESKTOP_SESSION_START_DIR
unset -f __does_cmd_exist __silent_kill __silent_start __get_pid
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# final
sleep 10
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit 0
# End application
# ex: ts=2 sw=2 et filetype=sh
