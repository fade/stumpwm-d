#!/bin/bash
#-*- mode: shell -*-
# set -x

#=============================================================================
# GENERAL INITIALIZATION
#=============================================================================


# Identify the home of our gtkrc file, important for setting styles of 
# gtk-based applications
# export GTK2_RC_FILES="$HOME/.gtkrc-2.0"

# Load X resources (fixes some font issues)
xrdb -merge .Xresources

# Start compositing to support transparency. You can omit this
# if you prefer not to use any transparency, but it is likely to cause
# ugly black fringing with some programs such as synapse that expect
# transparency support.

# compositing for various transparency effects. picom supersedes compton.
# picom &

#=============================================================================
# SCREEN CONFIGURATION
#=============================================================================


# We handle our screen configuration using xrandr. You are likely to want to 
# edit this section to match the specific demands of your setup. The below
# setup is for a Lenovo W520 laptop that sometimes has an external monitor
# hooked up via either VGA or DVI, positioned to the left of the laptop.
#
# Note that you can run xrandr at the command line to get a list of your
# connected screens and find out what names you should use to refer to them.

# Activate primary screen 
xrandr --output  DVI-D-0 --auto --primary
sleep 1

# If we find that a screen is connected via VGA, activate it and position it
# to the left of the primary screen.
# xrandr | grep 'VGA-1-2 connected' | xrandr --output VGA-1-2 --auto --left-of LVDS1
# sleep 2

# If we find that a screen is connected via DVI, activate it and position it
# to the right of the primary screen.
xrandr | grep 'HDMI-0 connected' | xrandr --output HDMI-0 --auto --left-of DVI-D-0
sleep 1

#=============================================================================
# STARTUP ICON TRAY
#=============================================================================

# We are using stalonetray to create a small icon tray at the
# top right of the screen. You are likely to want to tweak the
# size of the icons and the width of the tray based upon the
# size of your screen and your xmobar configuration. The goal is
# to make stalonetray look like it is part of xmobar.
# 
# Line by line, the options used by default below mean:
# - icons should be aligned with the "East" or right side of the tray
# - the width of the tray should be 5 icons wide by one icon tall, and it 
#   should be located 0 pixels from the right of the screen (-0) and 0 pixels
#   from the top of the screen (+0).
# - By setting our maximum geometry to the same thing, the tray will not grow.
# - The background color of the tray should be black.
# - This program should not show up in any taskbar.
# - Icons should be set to size "24".
# - Kludges argument of "force_icons_size" forces all icons to really, truly 
#   be the size we set.
# - window-strut "none" means windows are allowed to cover the tray. In
#   other words, trust xmonad to handle this part.
#
# stalonetray --icon-gravity E \
#             --geometry 9x1-0+0 \
#             --max-geometry 9x1-0+0 \
#             --background '#1f1f1f' \
#             --skip-taskbar \
#             --icon-size 24 \
#             --kludges force_icons_size \
#     &



# Run the gnome-keyring-daemon to avoid issues you otherwise may encounter
# when using gnome applications which expect access to the keyring, such
# as Empathy. This prevents prompts you may otherwise get for invalid
# certificates and the like.
gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh


# Synaptics
# syndaemon -i 1 -t &

# Corsair K-95
ckb-next &

#Plz low screen brightness
# xbacklight -set 50

# KDE apps need a bunch of underlying plumbing. kdeinit5 is the minimum.
/usr/bin/kdeinit5 &

# Now, finally, start stumpWM
exec /usr/local/bin/stumpwm
