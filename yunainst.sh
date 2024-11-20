#!/bin/bash
{ #Checks if sudo password has been set
setPassword=$(passwd -S | grep -c "NP")


if [ $setPassword -eq 0 ]; then
  echo "sudo password set, skipping..."
else
  echo "Please set a password"
  echo "Do not lose this password, it's a PITA to reset"
  passwd
fi
}

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
cat << EOF >> ~/.local/share/applications/YunaMS.desktop
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
