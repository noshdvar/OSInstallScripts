#!/usr/bin/env bash
# install_pkg_debianstable_kde.sh - Debian Stable (Trixie) + KDE
set -uo pipefail

if [ "$(id -u)" -eq 0 ]; then echo "Bitte als normaler User mit sudo starten."; exit 1; fi

FAILED=()

apt_try() {
    # Installiert Pakete einzeln, fehlende werden übersprungen und gemeldet
    for p in "$@"; do
        if apt-cache show "$p" >/dev/null 2>&1; then
            sudo apt install -y "$p" || FAILED+=("$p")
        else
            echo "!! Paket nicht verfügbar: $p"; FAILED+=("$p")
        fi
    done
}

echo "=== contrib / non-free aktivieren ==="
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    sudo sed -i -E '/^Components:/ { /contrib/! s/$/ contrib/ }; /^Components:/ { /non-free( |$)/! s/$/ non-free/ }; /^Components:/ { /non-free-firmware/! s/$/ non-free-firmware/ }' /etc/apt/sources.list.d/debian.sources
else
    echo "!! /etc/apt/sources.list.d/debian.sources fehlt - bitte contrib/non-free manuell aktivieren."
fi

echo "=== System aktualisieren ==="
sudo apt update && sudo apt upgrade -y

echo "=== Basis-Pakete installieren ==="
sudo apt install -y curl wget gnupg ca-certificates flatpak extrepo

apt_try ttf-mscorefonts-installer ark bzip2 cpio hashdeep 7zip p7zip-full \
    unrar rar unzip zip fonts-jetbrains-mono kasts plasma-discover-backend-flatpak

echo "=== DVD-Support (libdvd-pkg) ==="
sudo apt install -y libdvd-pkg && sudo dpkg-reconfigure -fnoninteractive libdvd-pkg || FAILED+=("libdvd-pkg")

echo "=== Flathub aktivieren ==="
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "=== KDE / Debian Repo Anwendungen installieren ==="
apt_try kde-cli-tools kio-extras kate partitionmanager haruna handbrake audacity \
    ktorrent fastfetch yakuake k3b krita tellico kget skrooge akregator ksnip \
    minder krusader audex

echo "=== Microsoft Edge Repository ==="
sudo install -d -m 0755 /etc/apt/keyrings
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/microsoft.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" \
    | sudo tee /etc/apt/sources.list.d/microsoft-edge.list >/dev/null
sudo apt update
sudo apt install -y microsoft-edge-stable || FAILED+=("microsoft-edge-stable")

echo "=== LibreWolf Repository (extrepo) ==="
sudo extrepo enable librewolf
sudo apt update
sudo apt install -y librewolf || FAILED+=("librewolf")

echo "=== RustDesk und TeamViewer (nicht in Debian) ==="
TMP="$(mktemp -d)"
wget -q -O "$TMP/teamviewer.deb" https://download.teamviewer.com/download/linux/teamviewer_amd64.deb \
    && sudo apt install -y "$TMP/teamviewer.deb" || FAILED+=("teamviewer")
rm -rf "$TMP"

echo "=== Flatpak Anwendungen installieren ==="
flatpak_try() {
    for a in "$@"; do
        sudo flatpak install -y --noninteractive flathub "$a" || FAILED+=("flatpak:$a")
    done
}
flatpak_try \
    com.rustdesk.RustDesk \
    io.github.mrvladus.List \
    com.spotify.Client \
    org.kde.plasmatube \
    com.github.taiko2k.tauonmb \
    com.github.jeromerobert.pdfarranger \
    io.element.Element \
    io.github.kdiskmark.KDiskMark \
    org.telegram.desktop \
    com.jgraph.drawio.desktop

echo "=== Helium ==="
echo "Bitte manuell installieren: https://helium.computer"

echo "=== Installation abgeschlossen ==="
if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "Fehlgeschlagen/übersprungen: ${FAILED[*]}"
fi
echo "Bitte einmal neu anmelden oder rebooten."
