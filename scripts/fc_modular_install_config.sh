#!/bin/bash

# Überprüfen, ob das Skript als Benutzer mit sudo-Rechten ausgeführt wird
check_sudo() {
  if [ "$EUID" -eq 0 ]; then
    echo "Dieses Skript sollte nicht als root ausgeführt werden."
    exit 1
  fi
}

# Konfiguration der sudoers Datei für die Gruppe 'wheel'
configure_sudoers() {
  local sudoers_file="/etc/sudoers.d/rootusers"
  if [ -f "$sudoers_file" ]; then
    echo "Die Datei $sudoers_file existiert bereits. Erstelle ein Backup."
    sudo cp "$sudoers_file" "${sudoers_file}.bak"
  fi
  echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" > /dev/null
  sudo chmod 440 "$sudoers_file"
  echo "Die Datei $sudoers_file wurde erfolgreich konfiguriert."
}

# Repository hinzufügen
add_repository() {
  local name="$1"
  local content="$2"
  local file="/etc/yum.repos.d/$name.repo"
  echo "Füge das Repository $name hinzu..."
  echo "$content" | sudo tee "$file" > /dev/null
}

# RPM Fusion Repositories hinzufügen
add_rpm_fusion() {
  echo "Füge RPM Fusion free und non-free Repositories hinzu..."
  sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

# Pakete installieren
install_packages() {
  local packages=("$@")
  echo "Aktualisiere die Paketlisten..."
  sudo dnf check-update -y
  echo "Installiere die benötigten Pakete..."
  for package in "${packages[@]}"; do
    echo "Installiere $package..."
    sudo dnf install -y "$package"
  done
}

# Oh My Zsh installieren
install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    if [ -x "$(command -v zsh)" ]; then
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
}

# Plugins für Oh My Zsh installieren
install_zsh_plugin() {
  local plugin_url="$1"
  local plugin_dir="$2"
  if [ ! -d "$plugin_dir" ]; then
    git clone "$plugin_url" "$plugin_dir"
    echo "Plugin $plugin_dir wurde installiert."
  else
    echo "Plugin $plugin_dir ist bereits installiert."
  fi
}

# Zsh als Standard-Shell setzen
set_default_shell() {
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    echo "Setze Zsh als Standard-Shell..."
    chsh -s "$(command -v zsh)"
    echo "Zsh wurde als Standard-Shell festgelegt. Sie müssen sich neu anmelden, um die Änderung zu übernehmen."
  fi
}

# Oh My Posh installieren
install_oh_my_posh() {
  if [ ! -f "/usr/bin/oh-my-posh" ]; then
    echo "Oh My Posh ist nicht installiert. Lade das Binary herunter..."
    sudo curl -L -o /usr/bin/oh-my-posh https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v24.5.1/posh-linux-amd64
    sudo chmod +x /usr/bin/oh-my-posh
    echo "Oh My Posh wurde erfolgreich installiert."
  else
    echo "Oh My Posh ist bereits installiert."
  fi
}

# Meslo Nerd Fonts installieren
install_meslo_fonts() {
  local font_dir="/usr/share/fonts/meslo-nerd-fonts"
  if [ -d "$font_dir" ]; then
    echo "Meslo Nerd Fonts sind bereits installiert."
  else
    git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git /tmp/nerd-fonts
    sudo mkdir -p "$font_dir"
    sudo cp /tmp/nerd-fonts/patched-fonts/Meslo/*/*.ttf "$font_dir/"
    sudo fc-cache -fv
    rm -rf /tmp/nerd-fonts
    echo "Meslo Nerd Fonts wurden erfolgreich installiert."
  fi
}

# Plugins zur .zshrc hinzufügen
activate_plugins() {
  if ! grep -q "zsh-syntax-highlighting" ~/.zshrc; then
    sed -i '/^plugins=(/s/)/ zsh-syntax-highlighting fast-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
    echo "Plugins wurden zur .zshrc hinzugefügt."
  fi
}

# Hauptskript
main() {
  check_sudo
  configure_sudoers
  
  add_repository "google-chrome" \
"[google-chrome]
name=google-chrome - \$basearch
baseurl=https://dl.google.com/linux/chrome/rpm/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub"
  
  add_repository "brave-browser" \
"[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc"
  
  add_repository "vscode" \
"[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc"

  add_rpm_fusion

  install_packages \
    "neovim" "vlc" "kitty" "google-chrome-stable" \
    "google-roboto-fonts" "google-roboto-mono-fonts" \
    "fontawesome-fonts-all" "fastfetch" "fzf" \
    "eza" "brave-browser" "gimp"

  install_oh_my_zsh

  install_zsh_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  install_zsh_plugin "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting"
  install_zsh_plugin "https://github.com/zsh-users/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

  set_default_shell
  install_oh_my_posh
  install_meslo_fonts
  activate_plugins

  echo "Skript abgeschlossen."
}

main

