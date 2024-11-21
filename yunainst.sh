#!/bin/bash

{
resolution="1"
proxy="0"
centered="0"
background="1"
wasd="0"
quickslot="0"
read -p 'Would you like to edit your game configuration (y/N)? ' changeconfig
if [[ "$changeconfig" =~ ^([yY][eE][sS]|[yY])$ ]]; then

  echo "0 = 800x600"
  echo "1 = 1280x720 (recommended)"
  echo "2 = 1280x800"
  echo "3 = 1600x900"
  echo "4 = 1920x1080"
  echo "5 = 1920x1200"
  echo "6 = 2560x1440"
  echo "7 = 3840x1080 (Ultrawide only)"
  read -p 'What is your preferred resolution (0-7)? ' resolution
  until [[ $resolution =~ ^(-0+|\+?0*[012345])$ ]] ; do
    read -r -p "please enter a number between 0 and 7: " resolution
  done

  echo "Connect to Singapore Proxy Server"
  echo "SEA users will experience more stable connections if enabling this configuration"
  echo "Set this value to 1 only if you are having trouble connecting to the game server while overseas"
  read -p 'Do you want to use the Singapore proxy (y/N)? ' proxyq
  if [[ "$proxyq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
    proxy="1"
  fi

  read -p 'Do you want the game to start centered (y/N)? ' centeredq
  if [[ "$centeredq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
    centered="1"
  fi

  echo "Map Backgrounds"
  echo "May increase performance at the cost of beauty"
  read -p 'Do you want backgrounds to be disabled (y/N)? ' backgroundq
  if [[ "$backgroundq" =~ ^([yY][eE][sS]|[yY])|"0"$ ]]; then
    background="0"
  fi

  echo "WASD Movement Remapping"
  echo "Prefer to use WASD instead of the arrow keys? Enable this! Simply set the value to 1"
  echo "NOTE: The arrow keys will basically swap with WASD keys, so you can still assign keys to them"
  read -p 'Do you want to use WASD as your movement keys (y/N)? ' wasdq
  if [[ "$wasdq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
    wasd="1"
  fi

  echo "Expanded Quick Slot"
  echo "This option will extend the quickslot window from 8 slots to 26 slots"
  read -p 'Do you want to extend your quickslots (y/N)? ' quickslotq
  if [[ "$quickslotq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
    quickslot="1"
  fi

fi
rm ~/Games/YunaMS/Settings.ini
touch ~/Games/YunaMS/Settings.ini
cat << EOF >> ~/Games/YunaMS/Settings.ini
[Settings]

; Most client modifications can be changed in-game via the Widget (bottom right button in-game).
; For other settings, see below. Simply change the value after the "=" sign to your liking.

;==============================================================================================
; Change Client Resolution
; NOTE: Larger resolutions can only be supported by specific monitors!
; 0 = 800x600
; 1 = 1280x720 (recommended)
; 2 = 1280x800
; 3 = 1600x900
; 4 = 1920x1080
; 5 = 1920x1200
; 6 = 2560x1440
; 7 = 3840x1080 (Ultrawide only)
resolution = "$resolution"
;==============================================================================================
; Connect to Singapore Proxy Server
; SEA users will experience more stable connections if enabling this configuration
; Set this value to 1 only if you are having trouble connecting to the game server while overseas
; 0 = Use main game server (default)
; 1 = Use singapore proxy server
singapore_proxy = "$proxy"
;==============================================================================================
; Change Position of Client on Launch
; 0 = Client launches top left of screen
; 1 = Client launches centered
start_centered = "$centered"
;==============================================================================================
; Map Backgrounds
; May increase performance at the cost of beauty
; 0 = Disabled
; 1 = Enabled (default)
map_background = "$background"
;==============================================================================================
; WASD Movement Remapping
; Prefer to use WASD instead of the arrow keys? Enable this! Simply set the value to 1
; NOTE: The arrow keys will basically swap with WASD keys, so you can still assign keys to them
; 0 = Disabled (default)
; 1 = Enabled
wasd_remapping = "$wasd"
;==============================================================================================
; Expanded Quick Slot
; This option will extend the quickslot window from 8 slots to 26 slots
; 0 = Disabled (default)
; 1 = Enabled
expanded_qs = "$quickslot"
;==============================================================================================
EOF
}
