#!/bin/bash

steamdeckStart() {
    echo "Steam Deck detected, running Steam Deck specific commands"
    echo "Checking if sudo password is set"
    setPassword=$(passwd -S | grep -c "NP") #Checks if sudo password has been set
    if [ $setPassword -eq 0 ] ; then
        echo "sudo password set, skipping..."
    else
        echo "sudo password not set"
        echo "Please set a sudo password"
        echo "Do not lose this password, it's a PITA to reset"
        passwd
    fi
    echo "This is a Steam Deck, disabling write protection and enabling pacman"
    sudo steamos-readonly disable
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    sudo pacman -Syyu #Just because
    sudo pacman -Scc #To hopefully remove everything broken if needed
}

installDependencies() { #Checks if dependencies from Arch Repository installed, installs if not existing
    echo "Checking if required dependencies are installed"
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

megaInstall() { #install MegaCMD to allow for direct download of Mega.nz links
    echo "Checking if MegaCMD is installed"
    if pacman -Qs megacmd > /dev/null ; then
        echo "MegaCMD is installed, skipping..."
    else
        echo "Installing MegaCMD"
        wget https://mega.nz/linux/repo/Arch_Extra/x86_64/megacmd-x86_64.pkg.tar.zst && sudo pacman -U --noconfirm "$HOME/megacmd-x86_64.pkg.tar.zst"
        [ -f $HOME/megacmd-x86_64.pkg.tar.zst ] && rm $HOME/megacmd-x86_64.pkg.tar.zst #cleanup temp file
        sudo pacman -Sy
    fi
}

patcherDownload() {
    echo "Downloading linux-patcher.rar from https://yuna.ms/linux-patcher"
    [ -f $HOME/Downloads/linux-patcher.rar ] && echo "linux-patcher.rar already downloaded, skipping..."
    [ ! -f $HOME/Downloads/linux-patcher.rar ] && curl https://yuna.ms/linux-patcher -o $HOME/Downloads/linux-patcher.rar #Download linux-specific files
    mkdir -p $HOME/Games #Ensures $HOME/Games directory exists
    echo "Extracting YunaMS.rar"
    ark -b $HOME/Downloads/YunaMS.rar -o $HOME/Games/ #Extracts game files
    { #Removes files to be overwritten by Linux Patcher files, to avoid user being prompted to overwrite them.
        declare -a winVersions=("D3DCompiler_47_cor3.dll" "Patcher.exe" "PenImc_cor3.dll" "PresentationNative_cor3.dll" "vcruntime140_cor3.dll" "wpfgfx_cor3.dll" "favicon.ico" "icon.png")
        for winFiles in "${winVersions[@]}"
        do
            rm $HOME/Games/YunaMS/$winFiles > /dev/null
        done
    }
    echo "Extracting Linux Patcher Files"
    ark -b $HOME/Downloads/linux-patcher.rar -o $HOME/Games/YunaMS/
}

gameDownload() {
    echo "Downloading game files"
    megalink=$(curl https://yuna.ms/download | grep -o https\:\/\/mega.nz.*\"\> )
    megalink=${megalink:0:$((${#megalink} - 2))}
    if [ -f $HOME/Downloads/[yY]una[mM][sS].rar ]; then
        echo "YunaMS.rar already exists, skipping..."
        patcherDownload
    elif ! mega-get $megalink $HOME/Downloads; then
        echo ""
        echo -e "Mega link out of date, please manually download from \e[0;34mhttps://yuna.ms/download\e[0m and run this script again."
        echo ""
        echo -e "Ping \e[0;35m@DarkSirrush\e[0m on Discord to get the link updated. Alternatively, start a pull request at \e[0;34mhttps://github.com/DarkSirrush/YunaStuff\e[0m"
        echo ""
        exit
    else
        echo "Downloading YunaMS.rar from $megalink"
        patcherDownload
    fi
}

bottlesInstall() {
    echo "Installing Bottles"
    flatpak install -y --noninteractive flathub com.usebottles.bottles #install bottles from Flathub
    echo "Setting user override so Bottles can function"
    flatpak override --user --filesystem=home com.usebottles.bottles
    sleep 5 && echo "Sleeping for 5 seconds"
    echo "Reloading Bash"
    . "$BASH" &>/dev/null
    sleep 5 && echo "Sleeping for 5  more seconds"
    echo "Running Bottles for first time"
    echo "Please follow the prompts from Bottles, and close it once complete"
    flatpak run com.usebottles.bottles #first run, close manually once done first run process... need to see if I can auto close it?
    echo "Creating YunaMS Bottle"
    flatpak run --command=bottles-cli com.usebottles.bottles new --bottle-name YunaMS --environment gaming #creates the bottle
    sleep 5
    echo "Installing dependencies"
    WINEPREFIX=$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/YunaMS winetricks -q dinput8 dotnetdesktop6 #installs Patcher dependencies
    sleep 5
    echo "Adding YunaMS and Patcher to Bottles Launcher"
    flatpak run --command=bottles-cli com.usebottles.bottles add -b YunaMS -n YunaMS -p $HOME/Games/YunaMS/YunaMS.exe #adds launch option for game
    flatpak run --command=bottles-cli com.usebottles.bottles add -b YunaMS -n Patcher -p $HOME/Games/YunaMS/Patcher.exe #adds launch option for patcher
    echo "Running Patcher"
    flatpak run --command=bottles-cli com.usebottles.bottles run -b YunaMS -p Patcher #Patcher first run
    echo "Patcher complete, continuing"
}

steamdeckBottles() {
    echo "Installing Bottles"
    flatpak install -y --noninteractive flathub com.usebottles.bottles #install bottles from Flathub
    echo "Installing Wine"
    sudo flatpak install -y --noninteractive flathub org.winehq.Wine/x86_64/stable-24.08 #Installs wine from Flathub, version set to reduce need for user input
    echo "Setting user override so Bottles can function"
    flatpak override --user --filesystem=home com.usebottles.bottles
    sleep 5 && echo "Sleeping for 5 seconds"
    echo "Reloading Bash"
    . "$BASH" &>/dev/null
    sleep 5 && echo "Sleeping for 5  more seconds"
    echo "Running Bottles for first time"
    echo "Please follow the prompts from Bottles, and close it once complete"
    flatpak run com.usebottles.bottles #first run, close manually once done first run process... need to see if I can auto close it?
    echo "Creating YunaMS Bottle"
    flatpak run --command=bottles-cli com.usebottles.bottles new --bottle-name YunaMS --environment gaming #creates the bottle
    sleep 5
    echo "Installing dependencies"
    flatpak run --env="WINEPREFIX=/home/deck/.var/app/com.usebottles.bottles/data/bottles/bottles/YunaMS" --env="WINEARCH=win64" org.winehq.Wine /app/bin/winetricks -q dinput8 dotnetdesktop6 #installs Patcher dependencies
    sleep 5
    echo "Adding YunaMS and Patcher to Bottles Launcher"
    flatpak run --command=bottles-cli com.usebottles.bottles add -b YunaMS -n YunaMS -p $HOME/Games/YunaMS/YunaMS.exe #adds launch option for game
    flatpak run --command=bottles-cli com.usebottles.bottles add -b YunaMS -n Patcher -p $HOME/Games/YunaMS/Patcher.exe #adds launch option for patcher
    echo "Running Patcher"
    flatpak run --command=bottles-cli com.usebottles.bottles run -b YunaMS -p Patcher #Patcher first run
    echo "Patcher complete, continuing"
}

createShortcut() {
    echo "Creating Launcher Shortcut"
    if [ ! -f $HOME/.local/share/applications/YunaMS.desktop ]; then
      mkdir -p $HOME/.local/share/applications/
      touch $HOME/.local/share/applications/YunaMS.desktop
      cat <<-EOF> $HOME/.local/share/applications/YunaMS.desktop
[Desktop Entry]
Name=YunaMS
Exec=flatpak run --command=bottles-cli com.usebottles.bottles run -p YunaMS -b 'YunaMS' -- %u
Type=Application
Terminal=false
Categories=Game;
Icon=$HOME/Games/YunaMS/icon.png
Comment=Launch YunaMS using Bottles.
StartupWMClass=YunaMS
Actions=Patcher;Configure;
[Desktop Action Patcher]
Name=Run Patcher
Exec=flatpak run --command=bottles-cli com.usebottles.bottles run -p Patcher -b 'YunaMS' -- %u
[Desktop Action Configure]
Name=Configure in Bottles
Exec=flatpak run com.usebottles.bottles -b 'YunaMS'
EOF
    else
    echo "Shortcut already made, skipping..."
    fi
}

createSettings() {
    #Create Game Config
    proxy="0"
    centered="0"
    background="1"
    wasd="0"
    quickslot="0"
    read -p 'Would you like to edit your game configuration (y/N)? ' changeconfig
    if [[ "$changeconfig" =~ ^([yY][eE][sS]|[yY])$ ]]; then

      echo "0 = 800x600"
      echo "1 = 1280x720 (Default)"
      echo "2 = 1280x800 (Steam Deck Default)"
      echo "3 = 1600x900"
      echo "4 = 1920x1080"
      echo "5 = 1920x1200"
      echo "6 = 2560x1440"
      echo "7 = 3840x1080 (Ultrawide only)"

      echo ""
      echo "Press enter for default"
      read -p "Do you want to change the default resolution (y/N)?" resolutionq
      if [[ "$resolutionq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
        read -p 'What is your preferred resolution (0-7)? ' -i $resolution resolution
        until [[ $resolution =~ ^(-0+|\+?0*[01234567])$ ]] ; do
            read -r -p 'please enter a number between 0 and 7: ' resolution
        done
      fi

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
    rm $HOME/Games/YunaMS/[sS]ettings.ini
    touch $HOME/Games/YunaMS/Settings.ini
    cat <<-EOF> $HOME/Games/YunaMS/Settings.ini
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
resolution = $resolution
;==============================================================================================
; Connect to Singapore Proxy Server
; SEA users will experience more stable connections if enabling this configuration
; Set this value to 1 only if you are having trouble connecting to the game server while overseas
; 0 = Use main game server (default)
; 1 = Use singapore proxy server
singapore_proxy = $proxy
;==============================================================================================
; Change Position of Client on Launch
; 0 = Client launches top left of screen
; 1 = Client launches centered
start_centered = $centered
;==============================================================================================
; Map Backgrounds
; May increase performance at the cost of beauty
; 0 = Disabled
; 1 = Enabled (default)
map_background = $background
;==============================================================================================
; WASD Movement Remapping
; Prefer to use WASD instead of the arrow keys? Enable this! Simply set the value to 1
; NOTE: The arrow keys will basically swap with WASD keys, so you can still assign keys to them
; 0 = Disabled (default)
; 1 = Enabled
wasd_remapping = $wasd
;==============================================================================================
; Expanded Quick Slot
; This option will extend the quickslot window from 8 slots to 26 slots
; 0 = Disabled (default)
; 1 = Enabled
expanded_qs = $quickslot
;==============================================================================================
EOF
echo "Settings Created"
}

{
    echo "Start"
    . /etc/os-release
    if [ "$ID" == "steamos" ] ; then #If OS is Steam Deck, then run steam-deck specific instructions
        steamdeckStart
        megaInstall
        gameDownload
        steamdeckBottles
        createShortcut
        resolution="2"
        createSettings
        echo "Re-enabling write protection"
        sudo steamos-readonly enable
        echo ""
        echo "If you know what you are doing, and need write protection to stay off, please run the command \"sudo steamos-readonly disable\" again."
        echo "Done"
    elif command -v pacman > /dev/null ; then
        installDependencies
        megaInstall
        gameDownload
        bottlesInstall
        createShortcut
        resolution="1"
        createSettings
        echo "Done"
    else
        echo -e "This script does not support your OS. Raise an issue, or, better yet, do a pull request with your chosen OS at \e[0;34mhttps://github.com/DarkSirrush/YunaStuff\e[0m"
    fi
    read -p 'Would you like to remove the install files (y/N)? ' cleanUpq
    if [[ "$cleanUpq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
        read -p 'Do you wish to keep YunaMS.rar for faster reinstallation (y/N)? ' keepClientq
        if [[ "$keepClientq" =~ ^([yY][eE][sS]|[yY])|"1"$ ]]; then
            rm $HOME/yunainst.sh
            rm $HOME/Downloads/linux-patcher.rar
        else
            rm $HOME/yunainst.sh
            rm $HOME/Downloads/linux-patcher.rar
            rm $HOME/Downloads/[yY]una[mM][sS].rar
        fi
    fi
}
