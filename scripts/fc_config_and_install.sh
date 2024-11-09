#!/bin/bash

# Überprüfen, ob das Skript als Root ausgeführt wird
if [ "$EUID" -eq 0 ]; then
  echo "Dieses Skript sollte nicht als Root ausgeführt werden. Starte den Root-spezifischen Teil mit sudo und den Benutzer-Teil als normaler Benutzer."
  exit 1
fi

# Root-spezifischer Teil
echo "Starte Root-spezifischen Teil mit sudo..."

# Erstelle die Sudo-Konfigurationsdatei für die Gruppe wheel, falls nötig
sudoers_file="/etc/sudoers.d/rootusers"
sudoers_entry="%wheel ALL=(ALL) NOPASSWD: ALL"

if [ ! -f "$sudoers_file" ]; then
  echo "Erstelle Sudo-Konfigurationsdatei $sudoers_file und füge Eintrag hinzu."
  echo "$sudoers_entry" | sudo tee "$sudoers_file" > /dev/null
  echo "Sudo-Konfigurationsdatei $sudoers_file erfolgreich erstellt."
else
  # Überprüfen, ob der Eintrag bereits vorhanden ist
  if ! grep -Fxq "$sudoers_entry" "$sudoers_file"; then
    echo "Eintrag nicht vorhanden. Füge Eintrag zu $sudoers_file hinzu."
    echo "$sudoers_entry" | sudo tee -a "$sudoers_file" > /dev/null
    echo "Eintrag erfolgreich hinzugefügt."
  else
    echo "Eintrag bereits in $sudoers_file vorhanden. Keine Änderungen vorgenommen."
  fi
fi

# Setze Git-Konfiguration für Username und E-Mail
echo "Setze Git-Konfiguration..."
git config --global user.name "Betara"
git config --global user.email "hi.thomas@gmx.de"
echo "Git-Username und E-Mail wurden gesetzt."

# Konfiguriere Git, um das Passwort im Cache für 1 Stunde zu speichern (3600 Sekunden)
echo "Konfiguriere Git Credential Cache, um das Passwort für 1 Stunde zu speichern..."
git config --global credential.helper store

# Paketinstallation für Fedora
echo "Installiere benötigte Pakete (git, zsh, curl)..."
sudo dnf install -y git zsh curl

# Definiere die Liste der zu installierenden Pakete
packages=(
  "tmux"
  "neovim"
  "stow"
  "zsh"
  "exa"
  "fzf"
  "thunderbird"
  "thunderbird-i18n-de"
  "gimp"
  "gnome-shell-extensions"
  "gnome-calendar"
  "gnome-contacts"
  "vlc"
  "kitty"
  "gnome-shell-extension-dash-to-dock"
  "ttf-roboto-mono-nerd"
  "ttf-roboto-mono"
  "ttf-meslo-nerd"
)

# Installiere die gewünschten Pakete, wenn sie noch nicht installiert sind
echo "Installiere die gewünschten Pakete..."
for package in "${packages[@]}"; do
  if dnf list installed "$package" &> /dev/null; then
    echo "$package ist bereits installiert, überspringe Installation."
  else
    sudo dnf install -y "$package"
    echo "$package erfolgreich installiert."
  fi
done

# Installiere Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installiere Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo "Oh My Zsh erfolgreich installiert."
else
  echo "Oh My Zsh ist bereits installiert. Überspringe Installation."
fi

# Installiere das Plugin zsh-autosuggestions
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
  echo "Installiere zsh-autosuggestions Plugin..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  echo "zsh-autosuggestions Plugin erfolgreich installiert."
fi

# Installiere das Plugin zsh-syntax-highlighting
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
  echo "Installiere zsh-syntax-highlighting Plugin..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  echo "zsh-syntax-highlighting Plugin erfolgreich installiert."
fi

# Installiere das Plugin fast-syntax-highlighting
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" ]; then
  echo "Installiere fast-syntax-highlighting Plugin..."
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting"
  echo "fast-syntax-highlighting Plugin erfolgreich installiert."
fi

# Füge die Plugins zur .zshrc hinzu, falls sie noch nicht aktiviert sind
if ! grep -q "zsh-autosuggestions" "$HOME/.zshrc"; then
  sed -i 's/^plugins=(/plugins=(zsh-autosuggestions /' "$HOME/.zshrc"
fi
if ! grep -q "zsh-syntax-highlighting" "$HOME/.zshrc"; then
  sed -i 's/^plugins=(/plugins=(zsh-syntax-highlighting /' "$HOME/.zshrc"
fi
if ! grep -q "fast-syntax-highlighting" "$HOME/.zshrc"; then
  sed -i 's/^plugins=(/plugins=(fast-syntax-highlighting /' "$HOME/.zshrc"
fi

echo "Plugins zur .zshrc hinzugefügt."

# Setze Zsh als Standard-Shell für den Benutzer
if [ "$SHELL" != "$(command -v zsh)" ]; then
  echo "Setze Zsh als Standard-Shell..."
  chsh -s "$(command -v zsh)"
  echo "Zsh wurde als Standard-Shell festgelegt. Sie müssen sich neu anmelden, um die Änderung zu übernehmen."
fi

# Installiere Oh My Posh
if ! command -v oh-my-posh &> /dev/null; then
  echo "Installiere Oh My Posh..."
  sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
  sudo chmod +x /usr/local/bin/oh-my-posh
  sudo chmod +x /usr/local/bin/oh-my-posh
  echo "Oh My Posh erfolgreich installiert."

  # Füge Oh My Posh Konfiguration zu .zshrc hinzu
  echo 'eval "$(oh-my-posh init zsh)"' >> "$HOME/.zshrc"
  echo "Oh My Posh zur .zshrc hinzugefügt."
else
  echo "Oh My Posh ist bereits installiert. Überspringe Installation."
fi

echo "Fertig!"