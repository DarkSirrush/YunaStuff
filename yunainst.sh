#!/bin/bash

{ #install MegaCMD to allow for direct download of Mega.nz links
if pacman -Qs megacmd > /dev/null ; then
  echo "megacmd is installed, skipping..."
else
  wget https://mega.nz/linux/repo/Arch_Extra/x86_64/megacmd-x86_64.pkg.tar.zst && sudo pacman -U --noconfirm "$PWD/megacmd-x86_64.pkg.tar.zst"
fi
}

{ #Checks if dependencies from Arch Repository installed, installs if not existing
declare -a arr=("wine" "winetricks" "wine-mono" "wine-gecko" "flatpak" "unrar" "ark")
for package in "${arr[@]}"
  do
    if pacman -Qs $package > /dev/null ; then
      echo "$package is installed, skipping..."
    else
      sudo pacman -Sy --noconfirm $package
    fi
  done
}

[ -f ~/megacmd-x86_64.pkg.tar.zst ] && rm ~/megacmd-x86_64.pkg.tar.zst #cleanup temp file
[ ! -f ~/Downloads/YunaMS.rar ] && mega-get https://mega.nz/file/M7s2EZwB#CA7-l-pqf3ZnJBwYCSYtrqUT6WhHAT9uSkdU42ds9CE ~/Downloads #Download YunaMS main file
[ ! -f ~/Downloads/linux-patcher.rar ] && curl https://yuna.ms/linux-patcher -o ~/Downloads/linux-patcher.rar #Download linux-specific files
sudo pacman -Sy --noconfirm wine winetricks wine-mono wine-gecko flatpak unrar ark #Install dependancies from the Arch Repository - note that you may have some of these by default, they are just included for paranoia reasons
mkdir -p ~/Games
ark -b ~/Downloads/YunaMS.rar -o ~/Games/
rm ~/Games/YunaMS/D3DCompiler_47_cor3.dll
rm ~/Games/YunaMS/Patcher.exe
rm ~/Games/YunaMS/PenImc_cor3.dll
rm ~/Games/YunaMS/PresentationNative_cor3.dll
rm ~/Games/YunaMS/vcruntime140_cor3.dll
rm ~/Games/YunaMS/wpfgfx_cor3.dll
ark -b ~/Downloads/linux-patcher.rar -o ~/Games/YunaMS/
flatpak install -y --noninteractive flathub com.usebottles.bottles #install bottles from Flathub
flatpak override --user --filesystem=home com.usebottles.bottles
. ~/.bashrc
. ~/.bash_profile
flatpak run com.usebottles.bottles #first run, close manually once done first run process... need to see if I can auto close it?
flatpak run --command=bottles-cli com.usebottles.bottles new --bottle-name yunams --environment gaming #creates the bottle
WINEPREFIX=~/.var/app/com.usebottles.bottles/data/bottles/bottles/YunaMS winetricks -q dinput8 dotnetcoredesktop6 #installs Patcher dependencies
flatpak run --command=bottles-cli com.usebottles.bottles add -b yunams -n YunaMS -p ~/Games/YunaMS/YunaMS.exe #adds launch option for game
flatpak run --command=bottles-cli com.usebottles.bottles add -b yunams -n Patcher -p ~/Games/YunaMS/Patcher.exe #adds launch option for patcher
flatpak run --command=bottles-cli com.usebottles.bottles run -b yunams -p Patcher #Patcher first run
