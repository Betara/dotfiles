#!/bin/bash

# Überprüfen, ob das Skript als ein Benutzer mit sudo-Rechten ausgeführt wird
if [ "$EUID" -eq 0 ]; then
  echo "Dieses Skript sollte nicht als root ausgeführt werden."
  exit 1
fi

# Konfiguration der sudoers Datei für die Gruppe 'wheel'
sudoers_file="/etc/sudoers.d/rootusers"
if [ -f "$sudoers_file" ]; then
  echo "Die Datei $sudoers_file existiert bereits. Erstelle ein Backup."
  sudo cp "$sudoers_file" "${sudoers_file}.bak"
fi

# Die nötigen Berechtigungen für die Gruppe wheel ohne Passwortanforderung hinzufügen
echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" > /dev/null

# Setze die Berechtigungen der sudoers-Datei korrekt
sudo chmod 440 "$sudoers_file"
echo "Die Datei $sudoers_file wurde erfolgreich konfiguriert."

# Hinzufügen des Google Chrome Repositorys
echo "Füge das Google Chrome Repository hinzu..."
sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<EOF
[google-chrome]
name=google-chrome - \$basearch
baseurl=https://dl.google.com/linux/chrome/rpm/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

# Hinzufügen der RPM Fusion Repositories
echo "Füge RPM Fusion free und non-free Repositories hinzu..."
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Hinzufügen von Barve Browser Repository
echo "Füge das Brave Browser Repository hinzu..."
sudo tee /etc/yum.repos.d/brave-browser.repo > /dev/null <<EOF
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
EOF

# Array mit den Paketnamen
packages=(
  "vlc"
  "kitty"
  "google-chrome-stable"
  "google-roboto-fonts"
  "google-roboto-mono-fonts"
  "fontawesome-fonts-all"
  "fastfetch"
  "fzf"
  "eza"
  "brave-browser"
)

# Paketquellen aktualisieren
echo "Aktualisiere die Paketlisten..."
sudo dnf check-update -y

# Pakete installieren
echo "Installiere die benötigten Pakete..."
for package in "${packages[@]}"; do
  echo "Installiere $package..."
  sudo dnf install -y "$package"
done

echo "Die Pakete wurden erfolgreich installiert."

# Installation von Oh My Zsh
echo "Installiere Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  if [ -x "$(command -v zsh)" ]; then
    # Installiere Oh My Zsh über ein Skript
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Oh My Zsh wurde erfolgreich installiert."
  else
    echo "Zsh ist nicht installiert. Installiere Zsh..."
    sudo dnf install -y zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi
else
  echo "Oh My Zsh ist bereits installiert."
fi

# Installation der Plugins für Oh My Zsh
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

echo "Installiere zsh-syntax-highlighting Plugin..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  echo "zsh-syntax-highlighting Plugin wurde installiert."
else
  echo "zsh-syntax-highlighting Plugin ist bereits installiert."
fi

echo "Installiere fast-syntax-highlighting Plugin..."
if [ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
  echo "fast-syntax-highlighting Plugin wurde installiert."
else
  echo "fast-syntax-highlighting Plugin ist bereits installiert."
fi

echo "Installiere zsh-autosuggestions Plugin..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  echo "zsh-autosuggestions Plugin wurde installiert."
else
  echo "zsh-autosuggestions Plugin ist bereits installiert."
fi

# Prüfen und Installation von Oh My Posh
echo "Überprüfe, ob Oh My Posh bereits unter /usr/bin/oh-my-posh installiert ist..."
if [ ! -f "/usr/bin/oh-my-posh" ]; then
  echo "Oh My Posh ist nicht installiert. Lade das Binary herunter..."
  sudo curl -L -o /usr/bin/oh-my-posh https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v24.5.1/posh-linux-amd64
  sudo chmod +x /usr/bin/oh-my-posh
  echo "Oh My Posh wurde erfolgreich nach /usr/bin/oh-my-posh heruntergeladen und ausführbar gemacht."
else
  echo "Oh My Posh ist bereits installiert unter /usr/bin/oh-my-posh."
fi

# Installation der Meslo Nerd Fonts
echo "Installiere die Meslo Nerd Fonts global..."
FONT_DIR="/usr/share/fonts/meslo-nerd-fonts"
if [ -d "$FONT_DIR" ]; then
  echo "Meslo Nerd Fonts sind bereits installiert."
else
  # Klonen des Nerd Fonts Repositories und Installation der Meslo Fonts
  git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git /tmp/nerd-fonts
  sudo mkdir -p "$FONT_DIR"
  sudo cp /tmp/nerd-fonts/patched-fonts/Meslo/*/*.ttf "$FONT_DIR/"
  sudo fc-cache -fv # Aktualisiere den Font-Cache
  rm -rf /tmp/nerd-fonts # Entferne das temporäre Verzeichnis
  echo "Meslo Nerd Fonts wurden erfolgreich global in $FONT_DIR installiert."
fi

# Aktivierung der Plugins in der .zshrc-Datei
if ! grep -q "zsh-syntax-highlighting" ~/.zshrc; then
  sed -i '/^plugins=(/s/)/ zsh-syntax-highlighting fast-syntax-highlighting)/' ~/.zshrc
  echo "Plugins wurden zur .zshrc hinzugefügt."
fi

echo "Skript abgeschlossen."

