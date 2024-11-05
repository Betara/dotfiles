#!/bin/bash

# Überprüfen, ob das Skript als Root ausgeführt wird
if [ "$EUID" -eq 0 ]; then
  echo "Dieses Skript sollte nicht als Root ausgeführt werden. Starte den Root-spezifischen Teil mit sudo und den Benutzer-Teil als normaler Benutzer."
  exit 1
fi

# Root-spezifischer Teil
echo "Starte Root-spezifischen Teil mit sudo..."

# Erstelle die Sudo-Konfigurationsdatei für die Gruppe wheel, falls nötig
sudoers_file="/etc/sudoers.d/rootuser"
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
git config --global credential.helper 'cache --timeout=3600'

# Installiere benötigte Pakete, falls noch nicht vorhanden
sudo pacman -S --needed --noconfirm git base-devel

# Installiere yay, falls noch nicht vorhanden
if ! command -v yay &> /dev/null; then
  # Klone das yay Repository und führe die Installation als nicht-Root-Benutzer durch
  echo "Klone das yay Repository und installiere yay..."
  git clone https://aur.archlinux.org/yay.git "$HOME/yay"
  cd "$HOME/yay" || exit
  makepkg -si --noconfirm
  cd "$HOME"
  rm -rf "$HOME/yay"
else
  echo "yay ist bereits installiert. Überspringe Installation."
fi

# Definiere die Liste der zu installierenden Pakete
packages=(
  "tmux"
  "neovim"
  "stow"
  "zsh"
  "thunderbird"
  "thunderbird-i18n-de"
  "gnome-shell-extensions"
  "gnome-canlendar"
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
  package_name=$(basename "$package") # Extrahiere den Paketnamen
  if pacman -Qs "$package_name" > /dev/null; then
    echo "$package_name ist bereits installiert, überspringe Installation."
  else
    yay -S --noconfirm "$package"
    if pacman -Qs "$package_name" > /dev/null; then
      echo "$package_name erfolgreich installiert."
    else
      echo "Fehler bei der Installation von $package_name."
    fi
  fi
done

echo "Fertig!"

