#!/usr/bin/env bash
# ============================================================
# Debian Stable (Trixie) + KDE Plasma, x86_64 - Komplettinstallation
# Jede Installation läuft einzeln; Fehler stoppen nichts.
# Am Ende: Zusammenfassung, v.a. der fehlgeschlagenen Tools.
# ============================================================

set -u
set -o pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

SUCCESS=(); FAILED=(); SKIPPED=()

info()    { echo; echo -e "${BLUE}>>> $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warning() { echo -e "${YELLOW}⚠ $*${NC}"; }
error()   { echo -e "${RED}✗ $*${NC}"; }

export DEBIAN_FRONTEND=noninteractive
APT="sudo -E apt-get -o Dpkg::Options::=--force-confold"

# ------------------------------------------------------------
# Einzelinstallation nativer Pakete
# ------------------------------------------------------------
install_apt_package() {
    local pkg="$1"
    echo; echo "--- APT: $pkg ---"
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        success "$pkg bereits installiert."; SKIPPED+=("APT: $pkg (bereits installiert)"); return 0
    fi
    local cand
    cand="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2}')"
    if [[ -z "$cand" || "$cand" == "(none)" ]]; then
        error "$pkg in den aktiven Quellen nicht verfügbar."; FAILED+=("APT: $pkg (nicht in Debian Stable-Quellen)"); return 1
    fi
    if $APT install -y "$pkg"; then
        success "$pkg installiert."; SUCCESS+=("APT: $pkg")
    else
        error "$pkg fehlgeschlagen."; FAILED+=("APT: $pkg")
    fi
}

install_apt_list() { local p; for p in "$@"; do install_apt_package "$p"; done; }

# ------------------------------------------------------------
# Einzelinstallation Flatpak
# ------------------------------------------------------------
install_flatpak() {
    local app="$1"
    echo; echo "--- Flatpak: $app ---"
    if flatpak info "$app" >/dev/null 2>&1; then
        success "$app bereits installiert."; SKIPPED+=("Flatpak: $app (bereits installiert)"); return 0
    fi
    if sudo flatpak install -y --noninteractive flathub "$app"; then
        success "$app installiert."; SUCCESS+=("Flatpak: $app")
    else
        error "$app fehlgeschlagen."; FAILED+=("Flatpak: $app")
    fi
}

# ------------------------------------------------------------
# Externe .deb (Herstellerdownload)
# ------------------------------------------------------------
install_remote_deb() {
    local name="$1" url="$2" pkg="$3" tmp
    echo; echo "--- .deb: $name ---"
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        success "$name bereits installiert."; SKIPPED+=("DEB: $name (bereits installiert)"); return 0
    fi
    tmp="$(mktemp -d)"
    if wget -q --show-progress -O "$tmp/$name.deb" "$url" && $APT install -y "$tmp/$name.deb"; then
        success "$name installiert."; SUCCESS+=("DEB: $name")
    else
        error "$name fehlgeschlagen."; FAILED+=("DEB: $name")
    fi
    rm -rf "$tmp"
}

# ============================================================
echo "============================================================"
echo " Debian Stable + KDE Setup (x86_64)"
echo "============================================================"

if [[ "$(id -u)" -eq 0 ]]; then error "Bitte als normaler Benutzer mit sudo starten."; exit 1; fi

ARCH="$(dpkg --print-architecture)"
if [[ "$ARCH" != "amd64" ]]; then error "Nur amd64 unterstützt (erkannt: $ARCH)."; exit 1; fi
success "amd64 erkannt."

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "System: ${PRETTY_NAME:-unbekannt}"
    [[ "${ID:-}" != "debian" ]] && warning "Kein Debian erkannt (ID=${ID:-?}) - es geht trotzdem weiter."
fi

info "sudo prüfen"
if ! sudo -v; then error "Keine sudo-Berechtigung."; exit 1; fi

# ------------------------------------------------------------
info "contrib / non-free aktivieren"
SRC=/etc/apt/sources.list.d/debian.sources
if [[ -f "$SRC" ]]; then
    if sudo sed -i -E '/^Components:/ { /contrib/! s/$/ contrib/ }; /^Components:/ { / non-free( |$)/! s/$/ non-free/ }; /^Components:/ { /non-free-firmware/! s/$/ non-free-firmware/ }' "$SRC"; then
        success "Components in $SRC ergänzt."; SUCCESS+=("contrib/non-free aktiviert")
    else
        warning "Anpassung von $SRC fehlgeschlagen."; FAILED+=("contrib/non-free aktivieren")
    fi
else
    warning "$SRC nicht gefunden (klassische sources.list?). contrib/non-free bitte manuell aktivieren."
    FAILED+=("contrib/non-free aktivieren (debian.sources fehlt)")
fi

info "System aktualisieren"
if sudo apt-get update && $APT upgrade -y; then
    success "System aktualisiert."; SUCCESS+=("Systemupdate")
else
    warning "Systemupdate nicht vollständig."; FAILED+=("Systemupdate")
fi

# ------------------------------------------------------------
info "Basis-Pakete"
install_apt_list curl wget gnupg ca-certificates flatpak extrepo \
    plasma-discover-backend-flatpak \
    ark bzip2 cpio hashdeep 7zip p7zip-full unrar rar unzip zip \
    fonts-jetbrains-mono fonts-liberation fonts-noto-core \
    fastfetch htop btop filelight kcalc dolphin-plugins ffmpegthumbnailer

info "Microsoft Core Fonts (EULA wird vorab akzeptiert)"
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
install_apt_package ttf-mscorefonts-installer

# ------------------------------------------------------------
info "Multimedia"
install_apt_list ffmpeg libavcodec-extra \
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav

echo; echo "--- DVD-Support (libdvd-pkg / libdvdcss2) ---"
if dpkg-query -W -f='${Status}' libdvdcss2 2>/dev/null | grep -q "install ok installed"; then
    success "libdvdcss2 bereits installiert."; SKIPPED+=("libdvdcss2 (bereits installiert)")
else
    echo "libdvd-pkg libdvd-pkg/first-install note" | sudo debconf-set-selections 2>/dev/null
    if $APT install -y libdvd-pkg && sudo dpkg-reconfigure -fnoninteractive libdvd-pkg \
        && dpkg-query -W -f='${Status}' libdvdcss2 2>/dev/null | grep -q "install ok installed"; then
        success "libdvdcss2 über libdvd-pkg gebaut."; SUCCESS+=("DVD-Support (libdvd-pkg/libdvdcss2)")
    else
        error "DVD-Support fehlgeschlagen."; FAILED+=("DVD-Support (libdvd-pkg/libdvdcss2)")
    fi
fi

# ------------------------------------------------------------
info "KDE-Anwendungen"
install_apt_list kde-cli-tools kio-extras kate partitionmanager haruna \
    ktorrent kdeconnect yakuake k3b krita tokodon kasts skrooge krusader \
    kget akregator tellico audex ksnip

info "Weitere native Programme"
install_apt_list handbrake audacity minder

# ------------------------------------------------------------
info "Microsoft Edge einrichten"
sudo install -d -m 0755 /etc/apt/keyrings
if wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/microsoft.gpg \
   && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" \
        | sudo tee /etc/apt/sources.list.d/microsoft-edge.list >/dev/null \
   && sudo apt-get update; then
    success "Edge-Repository eingerichtet."; SUCCESS+=("Microsoft Edge Repository")
else
    error "Edge-Repository fehlgeschlagen."; FAILED+=("Microsoft Edge Repository")
fi
install_apt_package microsoft-edge-stable

info "LibreWolf einrichten (extrepo)"
if sudo extrepo enable librewolf && sudo apt-get update; then
    success "LibreWolf-Repository aktiviert."; SUCCESS+=("LibreWolf Repository")
else
    error "LibreWolf-Repository fehlgeschlagen."; FAILED+=("LibreWolf Repository")
fi
install_apt_package librewolf

info "TeamViewer (Hersteller-.deb)"
install_remote_deb teamviewer https://download.teamviewer.com/download/linux/teamviewer_amd64.deb teamviewer

# ------------------------------------------------------------
info "Flathub aktivieren"
if flatpak remote-list --system 2>/dev/null | grep -q "^flathub"; then
    success "Flathub bereits aktiv."; SKIPPED+=("Flathub")
elif sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
    success "Flathub aktiviert."; SUCCESS+=("Flathub")
else
    error "Flathub fehlgeschlagen."; FAILED+=("Flathub")
fi

info "Flatpak-Anwendungen"
FLATPAKS=(
    com.spotify.Client
    io.anytype.anytype
    org.kde.plasmatube
    com.github.taiko2k.tauonmb
    au.com.shiftyjelly.pocketcasts
    com.github.jeromerobert.pdfarranger
    io.element.Element
    com.bitwarden.desktop
    org.telegram.desktop
    org.signal.Signal
    io.github.mrvladus.List
    io.github.kdiskmark.KDiskMark
    com.jgraph.drawio.desktop
    com.rustdesk.RustDesk
)
for app in "${FLATPAKS[@]}"; do install_flatpak "$app"; done

info "Flatpaks aktualisieren"
if sudo flatpak update -y --noninteractive; then
    success "Flatpaks aktualisiert."; SUCCESS+=("Flatpak Updates")
else
    warning "Flatpak-Update unvollständig."; FAILED+=("Flatpak Updates")
fi

# ============================================================
# Zusammenfassung
# ============================================================
echo; echo
echo "============================================================"
echo " INSTALLATION ABGESCHLOSSEN"
echo "============================================================"
echo; echo -e "${GREEN}Erfolgreich: ${#SUCCESS[@]}${NC}"
for i in "${SUCCESS[@]}"; do echo "  ✓ $i"; done
echo; echo -e "${YELLOW}Übersprungen / bereits vorhanden: ${#SKIPPED[@]}${NC}"
for i in "${SKIPPED[@]}"; do echo "  - $i"; done
echo; echo -e "${RED}NICHT erfolgreich installiert: ${#FAILED[@]}${NC}"
for i in "${FAILED[@]}"; do echo "  ✗ $i"; done
echo
if (( ${#FAILED[@]} == 0 )); then
    echo -e "${GREEN}Alles erfolgreich.${NC}"
else
    echo -e "${YELLOW}${#FAILED[@]} Vorgänge sind fehlgeschlagen; alle anderen wurden davon nicht beeinflusst.${NC}"
fi
echo
echo "Hinweis: Helium ist nicht in Debian paketiert -> manuell: https://helium.computer"
echo "Ein Neustart bzw. neues Anmelden wird empfohlen."
