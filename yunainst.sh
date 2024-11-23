#!/bin/bash
. /etc/os-release
{

  if [ "$ID" == "steamos" ] ; then #If OS is Steam Deck, then run steam-deck specific instructions
    { 
      setPassword=$(passwd -S | grep -c "NP") #Checks if sudo password has been set
      if [ $setPassword -eq 0 ] ; then
        echo "sudo password set, skipping..."
      else
        echo "Please set a password"
        echo "Do not lose this password, it's a PITA to reset"
        passwd
      fi
    }
  echo "This is a Steam Deck, disabling write protection and enabling pacman"
  sudo steamos-readonly disable
  sudo pacman-key --init
  sudo pacman-key --populate archlinux
  
  { #install MegaCMD to allow for direct download of Mega.nz links
    if pacman -Qs megacmd > /dev/null ; then
      echo "MegaCMD is installed, skipping..."
    else
      echo "Installing MegaCMD"
      wget https://mega.nz/linux/repo/Arch_Extra/x86_64/megacmd-x86_64.pkg.tar.zst && sudo pacman -U --noconfirm "$PWD/megacmd-x86_64.pkg.tar.zst"
      [ -f ~/megacmd-x86_64.pkg.tar.zst ] && rm ~/megacmd-x86_64.pkg.tar.zst #cleanup temp file
    fi
  }
  
  {
    echo "Downloading YunaMS.rar"
    if ! mega-get https://mega.nz/file/Nj0VBKYL#9lU738YDXSPv4ySjMM2bVI_grSTUR9f0zidValq-YhU ; then
        echo ""
        echo -e "Mega link out of date, please manually download from \e[0;34mhttps://yuna.ms/download\e[0m and run this script again."
        echo ""
        echo -e "Ping \e[0;35m@DarkSirrush\e[0m on Discord to get the link updated. Alternatively, start a pull request at \e[0;34mhttps://github.com/DarkSirrush/YunaStuff\e[0m"
        echo ""
        exit
      else
        [ -f ~/Downloads/YunaMS.rar ] && echo "YunaMS.rar already downloaded, skipping..."
        [ ! -f ~/Downloads/YunaMS.rar ] && mega-get https://mega.nz/file/Nj0VBKYL#9lU738YDXSPv4ySjMM2bVI_grSTUR9f0zidValq-YhU ~/Downloads #Download YunaMS main file
    fi
  }

  echo "Downloading linux-patcher.rar"
  [ -f ~/Downloads/linux-patcher.rar ] && echo "linux-patcher.rar already downloaded, skipping..."
  [ ! -f ~/Downloads/linux-patcher.rar ] && curl https://yuna.ms/linux-patcher -o ~/Downloads/linux-patcher.rar #Download linux-specific files
  mkdir -p ~/Games #Ensures $HOME/Games directory exists
  ark -b ~/Downloads/YunaMS.rar -o ~/Games/ #Extracts game files
  { #Removes files to be overwritten by Linux Patcher files, to avoid user being prompted to overwrite them.
    declare -a winversions=("D3DCompiler_47_cor3.dll" "Patcher.exe" "PenImc_cor3.dll" "PresentationNative_cor3.dll" "vcruntime140_cor3.dll" "wpfgfx_cor3.dll")
    for winfiles in "${winversions[@]}"
      do
        rm ~/Games/YunaMS/$winfiles
      done
  }
  
  ark -b ~/Downloads/linux-patcher.rar -o ~/Games/YunaMS/
  flatpak install -y --noninteractive flathub com.usebottles.bottles #install bottles from Flathub
  flatpak install -y --noninteractive flathub org.winehq.Wine
  flatpak override --user --filesystem=home com.usebottles.bottles
  sleep 5 && echo "Sleeping for 5 seconds"
  . "$BASH" &>/dev/null
  flatpak run com.usebottles.bottles #first run, close manually once done first run process... need to see if I can auto close it?
  flatpak run --command=bottles-cli com.usebottles.bottles new --bottle-name YunaMS --environment gaming #creates the bottle
  flatpak run --env="WINEPREFIX=~/.var/app/com.usebottles.bottles/data/bottles/bottles/YunaMS" --env="WINEARCH=win64" org.winehq.Wine /app/bin/winetricks -q dinput8 dotnetdesktop6 #installs Patcher dependencies
  flatpak run --command=bottles-cli com.usebottles.bottles add -b YunaMS -n YunaMS -p ~/Games/YunaMS/YunaMS.exe #adds launch option for game
  flatpak run --command=bottles-cli com.usebottles.bottles add -b YunaMS -n Patcher -p ~/Games/YunaMS/Patcher.exe #adds launch option for patcher
  flatpak run --command=bottles-cli com.usebottles.bottles run -b YunaMS -p Patcher #Patcher first run

  { #Create Application Menu Shortcut
    if [ ! -f ~/.local/share/applications/YunaMS.desktop ]; then
      mkdir -p ~/.local/share/applications/
      rm ~/.local/share/applications/YunaMS.desktop
      touch ~/.local/share/applications/YunaMS.desktop
      cat <<-EOF> ~/.local/share/applications/YunaMS.desktop 
[Desktop Entry]
Name=YunaMS
Exec=flatpak run --command=bottles-cli com.usebottles.bottles run -p YunaMS -b 'YunaMS' -- %u
Type=Application
Terminal=false
Categories=Game;
Icon=~/Games/YunaMS/icon.png
Comment=Launch YunaMS using Bottles.
StartupWMClass=YunaMS
Actions=Configure;
[Desktop Action Configure]
Name=Configure in Bottles
Exec=flatpak run com.usebottles.bottles -b 'YunaMS'
EOF
    fi
  }
  
  { #Create Game Config
    resolution="2"
    proxy="0"
    centered="0"
    background="1"
    wasd="0"
    quickslot="0"
    read -p 'Would you like to edit your game configuration (y/N)? ' changeconfig
    if [[ "$changeconfig" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    
      echo "0 = 800x600"
      echo "1 = 1280x720"
      echo "2 = 1280x800 (Default)"
      echo "3 = 1600x900"
      echo "4 = 1920x1080"
      echo "5 = 1920x1200"
      echo "6 = 2560x1440"
      echo "7 = 3840x1080 (Ultrawide only)"
    
      echo ""
      echo "Press enter for default"
      read -p 'What is your preferred resolution (0-7)? ' resolution
      until [[ $resolution =~ ^(-0+|\+?0*[012345])$ ]] ; do
        read -r -p "please enter a number between 0 and 7: " resolution
      done
    
      echo ""
      echo "Connect to Singapore Proxy Server"
      echo "SEA users will experience more stable connections if enabling this configuration"
      echo "Set this value to 1 only if you are having trouble connecting to the game server while overseas"
      echo ""
      echo "Press enter for default"
      read -p 'Do you want to use the Singapore proxy (y/N)? ' proxyq
      if [[ "$proxyq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
        proxy="1"
      fi
    
      echo ""
      echo "Press enter for default"
      read -p 'Do you want the game to start centered (y/N)? ' centeredq
      if [[ "$centeredq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
        centered="1"
      fi
    
      echo ""
      echo "Map Backgrounds"
      echo "May increase performance at the cost of beauty"
      echo ""
      echo "Press enter for default"
      read -p 'Do you want backgrounds to be disabled (y/N)? ' backgroundq
      if [[ "$backgroundq" =~ ^([yY][eE][sS]|[yY])|"0"$ ]]; then
        background="0"
      fi
    
      echo ""
      echo "WASD Movement Remapping"
      echo "Prefer to use WASD instead of the arrow keys? Enable this! Simply set the value to 1"
      echo "NOTE: The arrow keys will basically swap with WASD keys, so you can still assign keys to them"
      echo ""
      echo "Press enter for default"
      read -p 'Do you want to use WASD as your movement keys (y/N)? ' wasdq
      if [[ "$wasdq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
        wasd="1"
      fi
    
      echo ""
      echo "Expanded Quick Slot"
      echo "This option will extend the quickslot window from 8 slots to 26 slots"
      echo ""
      echo "Press enter for default"
      read -p 'Do you want to extend your quickslots (y/N)? ' quickslotq
      if [[ "$quickslotq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
        quickslot="1"
      fi
    
    fi
    rm ~/Games/YunaMS/Settings.ini
    touch ~/Games/YunaMS/Settings.ini
    cat <<-EOF> ~/Games/YunaMS/Settings.ini
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

  echo "Re-enabling write protection"
  sudo steamos-readonly enable
  echo ""
  echo "If you know what you are doing, and need write protection to stay off, please run the command \"sudo steamos-readonly disable\" again."

elif [[ "$ID" == "arch"|| "$ID" == "arch32"|| "$ID" == "arcolinux"|| "$ID" == "artix"|| "$ID" == "blackarch"|| "$ID" == "chimeraos"|| "$ID" == "endeavouros"|| "$ID" == "garuda"|| "$ID" == "hyperbola"|| "$ID" == "kaos"|| "$ID" == "manjaro"|| "$ID" == "rebornos" ]] ; then

  { #install MegaCMD to allow for direct download of Mega.nz links
    if pacman -Qs megacmd > /dev/null ; then
      echo "megacmd is installed, skipping..."
    else
      wget https://mega.nz/linux/repo/Arch_Extra/x86_64/megacmd-x86_64.pkg.tar.zst && sudo pacman -U --noconfirm "$PWD/megacmd-x86_64.pkg.tar.zst"
      [ -f ~/megacmd-x86_64.pkg.tar.zst ] && rm ~/megacmd-x86_64.pkg.tar.zst #cleanup temp file
    fi
  }
  
  { #Checks if dependencies from Arch Repository installed, installs if not existing
    declare -a arr=("wine" "winetricks" "wine-mono" "wine-gecko" "flatpak" "unrar" "ark")
    for package in "${arr[@]}"
      do
        if pacman -Qs $package > /dev/null ; then
          echo "$package is installed, skipping..."
        else
          echo "$package is not installed, installing..."
          sudo pacman -Sy --noconfirm $package
        fi
      done
  }
  
  {
    if ! mega-get https://mega.nz/file/Nj0VBKYL#9lU738YDXSPv4ySjMM2bVI_grSTUR9f0zidValq-YhU ; then
        echo ""
        echo -e "Mega link out of date, please manually download from \e[0;34mhttps://yuna.ms/download\e[0m and run this script again."
        echo ""
        echo -e "Ping \e[0;35m@DarkSirrush\e[0m on Discord to get the link updated. Alternatively, start a pull request at \e[0;34mhttps://github.com/DarkSirrush/YunaStuff\e[0m"
        echo ""
        exit
      else
        [ ! -f ~/Downloads/YunaMS.rar ] && mega-get https://mega.nz/file/Nj0VBKYL#9lU738YDXSPv4ySjMM2bVI_grSTUR9f0zidValq-YhU ~/Downloads #Download YunaMS main file
    fi
  }
  
  [ ! -f ~/Downloads/linux-patcher.rar ] && curl https://yuna.ms/linux-patcher -o ~/Downloads/linux-patcher.rar #Download linux-specific files
  mkdir -p ~/Games #Ensures $HOME/Games directory exists
  ark -b ~/Downloads/YunaMS.rar -o ~/Games/ #Extracts game files
  { #Removes files to be overwritten by Linux Patcher files, to avoid user being prompted to overwrite them.
    declare -a winversions=("D3DCompiler_47_cor3.dll" "Patcher.exe" "PenImc_cor3.dll" "PresentationNative_cor3.dll" "vcruntime140_cor3.dll" "wpfgfx_cor3.dll")
    for winfiles in "${winversions[@]}"
      do
        rm ~/Games/YunaMS/$winfiles
    done
  }
  
  ark -b ~/Downloads/linux-patcher.rar -o ~/Games/YunaMS/
  flatpak install -y --noninteractive flathub com.usebottles.bottles #install bottles from Flathub
  flatpak override --user --filesystem=home com.usebottles.bottles
  sleep 5 && echo "Sleeping for 5 seconds"
  . "$BASH" &>/dev/null
  flatpak run com.usebottles.bottles #first run, close manually once done first run process... need to see if I can auto close it?
  flatpak run --command=bottles-cli com.usebottles.bottles new --bottle-name YunaMS --environment gaming #creates the bottle
  WINEPREFIX=~/.var/app/com.usebottles.bottles/data/bottles/bottles/YunaMS winetricks -q dinput8 dotnetdesktop6 #installs Patcher dependencies
  flatpak run --command=bottles-cli com.usebottles.bottles add -b YunaMS -n YunaMS -p ~/Games/YunaMS/YunaMS.exe #adds launch option for game
  flatpak run --command=bottles-cli com.usebottles.bottles add -b YunaMS -n Patcher -p ~/Games/YunaMS/Patcher.exe #adds launch option for patcher
  flatpak run --command=bottles-cli com.usebottles.bottles run -b YunaMS -p Patcher #Patcher first run

  {
    if [ ! -f ~/.local/share/applications/YunaMS.desktop ]; then
      mkdir -p ~/.local/share/applications/
      rm ~/.local/share/applications/YunaMS.desktop
      touch ~/.local/share/applications/YunaMS.desktop
      cat <<-EOF> ~/.local/share/applications/YunaMS.desktop 
[Desktop Entry]
Name=YunaMS
Exec=flatpak run --command=bottles-cli com.usebottles.bottles run -p YunaMS -b 'YunaMS' -- %u
Type=Application
Terminal=false
Categories=Game;
Icon=~/Games/YunaMS/icon.png
Comment=Launch YunaMS using Bottles.
StartupWMClass=YunaMS
Actions=Configure;
[Desktop Action Configure]
Name=Configure in Bottles
Exec=flatpak run com.usebottles.bottles -b 'YunaMS'
EOF
    fi
  }

#Create Game Config
    resolution="1"
    proxy="0"
    centered="0"
    background="1"
    wasd="0"
    quickslot="0"
    read -p 'Would you like to edit your game configuration (y/N)? ' changeconfig
    if [[ "$changeconfig" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    
      echo "0 = 800x600"
      echo "1 = 1280x720 (Default)"
      echo "2 = 1280x800"
      echo "3 = 1600x900"
      echo "4 = 1920x1080"
      echo "5 = 1920x1200"
      echo "6 = 2560x1440"
      echo "7 = 3840x1080 (Ultrawide only)"
    
      echo ""
      echo "Press enter for default"
      read -p 'What is your preferred resolution (0-7)? ' resolution
      until [[ $resolution =~ ^(-0+|\+?0*[012345])$ ]] ; do
        read -r -p "please enter a number between 0 and 7: " resolution
      done
    
      echo ""
      echo "Connect to Singapore Proxy Server"
      echo "SEA users will experience more stable connections if enabling this configuration"
      echo "Set this value to 1 only if you are having trouble connecting to the game server while overseas"
      echo ""
      echo "Press enter for default"
      read -p 'Do you want to use the Singapore proxy (y/N)? ' proxyq
      if [[ "$proxyq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
        proxy="1"
      fi
    
      echo ""
      echo "Press enter for default"
      read -p 'Do you want the game to start centered (y/N)? ' centeredq
      if [[ "$centeredq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
        centered="1"
      fi
    
      echo ""
      echo "Map Backgrounds"
      echo "May increase performance at the cost of beauty"
      echo ""
      echo "Press enter for default"
      read -p 'Do you want backgrounds to be disabled (y/N)? ' backgroundq
      if [[ "$backgroundq" =~ ^([yY][eE][sS]|[yY])|"0"$ ]]; then
        background="0"
      fi
    
      echo ""
      echo "WASD Movement Remapping"
      echo "Prefer to use WASD instead of the arrow keys? Enable this! Simply set the value to 1"
      echo "NOTE: The arrow keys will basically swap with WASD keys, so you can still assign keys to them"
      echo ""
      echo "Press enter for default"
      read -p 'Do you want to use WASD as your movement keys (y/N)? ' wasdq
      if [[ "$wasdq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
        wasd="1"
      fi
    
      echo ""
      echo "Expanded Quick Slot"
      echo "This option will extend the quickslot window from 8 slots to 26 slots"
      echo ""
      echo "Press enter for default"
      read -p 'Do you want to extend your quickslots (y/N)? ' quickslotq
      if [[ "$quickslotq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
        quickslot="1"
      fi
    
    fi
    rm ~/Games/YunaMS/Settings.ini
    touch ~/Games/YunaMS/Settings.ini
    cat <<-EOF> ~/Games/YunaMS/Settings.ini
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


else
  echo -e "This script does not support your OS. Raise an issue, or, better yet, do a pull request with your chosen OS at \e[0;34mhttps://github.com/DarkSirrush/YunaStuff\e[0m"
fi
}
