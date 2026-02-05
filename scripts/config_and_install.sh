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

echo "Installiere Basis-Pakete..."
install_packages "${base_packages[@]}"

case "$DE" in
  gnome)
    echo "Installiere GNOME-spezifische Pakete..."
    install_packages "${gnome_packages[@]}"
    ;;
  kde)
    echo "Installiere KDE-spezifische Pakete..."
    install_packages "${kde_packages[@]}"
    ;;
  *)
    echo "Keine unterstützte Desktop-Umgebung erkannt. Überspringe DE-spezifische Pakete."
    ;;
esac

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

# Desktop-Umgebung erkennen
DE="unknown"

if [[ "$XDG_CURRENT_DESKTOP" =~ GNOME ]] || pacman -Qs gnome-shell > /dev/null; then
  DE="gnome"
elif [[ "$XDG_CURRENT_DESKTOP" =~ KDE ]] || pacman -Qs plasma-desktop > /dev/null; then
  DE="kde"
fi

echo "Erkannte Desktop-Umgebung: $DE"

# Pakete, die immer installiert werden
base_packages=(
  tmux
  neovim
  stow
  zsh
  eza
  kitty
  vlc
  gimp
  ttf-roboto-mono
  ttf-roboto-mono-nerd
  ttf-meslo-nerd
    thunderbird
  thunderbird-i18n-de
)

# GNOME-spezifische Pakete
gnome_packages=(
  gnome-shell-extensions
  gnome-calendar
  gnome-contacts
  gnome-shell-extension-dash-to-dock
)

# KDE-spezifische Pakete
kde_packages=(
  kvantum
)

install_packages() {
  local pkg_list=("$@")

  for package in "${pkg_list[@]}"; do
    if pacman -Qi "$package" &> /dev/null; then
      echo "$package ist bereits installiert, überspringe Installation."
    else
      echo "Installiere $package..."
      yay -S --noconfirm "$package"

      if pacman -Qi "$package" &> /dev/null; then
        echo "$package erfolgreich installiert."
      else
        echo "Fehler bei der Installation von $package."
      fi
    fi
  done
}

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
else
  echo "zsh-autosuggestions ist bereits installiert. Überspringe Installation."
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

# Setze Zsh als Standard-Shell für den Benutzer
if [ "$SHELL" != "$(command -v zsh)" ]; then
  echo "Setze Zsh als Standard-Shell..."
  chsh -s "$(command -v zsh)"
  echo "Zsh wurde als Standard-Shell festgelegt. Sie müssen sich neu anmelden, um die Änderung zu übernehmen."
fi

# Installiere Oh My Posh
if ! command -v oh-my-posh &> /dev/null; then
  echo "Installiere Oh My Posh..."
  yay -S --noconfirm oh-my-posh-bin
  echo "Oh My Posh erfolgreich installiert."
else
  echo "Oh My Posh ist bereits installiert. Überspringe Installation."
fi

echo "Fertig!"

