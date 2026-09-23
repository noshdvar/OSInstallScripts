#!/usr/bin/env bash

# ============================================================
# Fedora KDE x86_64 – Komplettinstallation
#
# Ziele:
#   - Fedora KDE x86_64
#   - native Pakete bevorzugen, wo sinnvoll
#   - Flatpak für ausgewählte Anwendungen
#   - Fehler einzelner Pakete dürfen die Installation
#     anderer Anwendungen NICHT verhindern
#   - Zusammenfassung aller Fehler am Ende
# ============================================================

set -u
set -o pipefail


# ============================================================
# Farben
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'


# ============================================================
# Statuslisten
# ============================================================

SUCCESS=()
FAILED=()
SKIPPED=()


# ============================================================
# Hilfsfunktionen
# ============================================================

info() {
    echo
    echo -e "${BLUE}>>> $*${NC}"
}

success() {
    echo -e "${GREEN}✓ $*${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $*${NC}"
}

error() {
    echo -e "${RED}✗ $*${NC}"
}


# Native Pakete EINZELN installieren.
# Dadurch blockiert ein defektes/nicht vorhandenes Paket
# nicht die Installation der folgenden Pakete.

install_dnf_package() {

    local package="$1"

    echo
    echo "------------------------------------------------------------"
    echo "Installiere natives Paket: $package"
    echo "------------------------------------------------------------"

    if rpm -q "$package" >/dev/null 2>&1; then

        success "$package ist bereits installiert."
        SKIPPED+=("RPM: $package (bereits installiert)")
        return 0

    fi

    if sudo dnf install -y "$package"; then

        success "$package installiert."
        SUCCESS+=("RPM: $package")

    else

        error "$package konnte nicht installiert werden."
        FAILED+=("RPM: $package")

    fi
}


# Flatpaks ebenfalls EINZELN installieren.

install_flatpak() {

    local app="$1"

    echo
    echo "------------------------------------------------------------"
    echo "Installiere Flatpak: $app"
    echo "------------------------------------------------------------"

    if flatpak info "$app" >/dev/null 2>&1; then

        success "$app ist bereits installiert."
        SKIPPED+=("Flatpak: $app (bereits installiert)")
        return 0

    fi

    if flatpak install \
        -y \
        --noninteractive \
        flathub \
        "$app"; then

        success "$app installiert."
        SUCCESS+=("Flatpak: $app")

    else

        error "$app konnte nicht installiert werden."
        FAILED+=("Flatpak: $app")

    fi
}


# ============================================================
# Start
# ============================================================

clear

echo "============================================================"
echo " Fedora KDE x86_64 Setup"
echo "============================================================"
echo


# ============================================================
# Architektur prüfen
# ============================================================

ARCH="$(uname -m)"

echo "Erkannte Architektur: $ARCH"

if [[ "$ARCH" != "x86_64" ]]; then

    error "Dieses Skript ist ausschließlich für x86_64 vorgesehen."
    exit 1

fi

success "x86_64 erkannt."


# ============================================================
# sudo vorbereiten
# ============================================================

info "sudo-Berechtigung prüfen"

if ! sudo -v; then

    error "Keine sudo-Berechtigung."
    exit 1

fi


# ============================================================
# Fedora Version
# ============================================================

FEDORA_VERSION="$(rpm -E %fedora)"

echo
echo "Fedora-Version: $FEDORA_VERSION"


# ============================================================
# System aktualisieren
# ============================================================

info "System aktualisieren"

if sudo dnf upgrade --refresh -y; then

    success "System aktualisiert."
    SUCCESS+=("Systemupdate")

else

    warning "Systemupdate nicht vollständig erfolgreich."
    FAILED+=("Systemupdate")

    echo
    echo "Die Installation wird trotzdem fortgesetzt."

fi


# ============================================================
# RPM Fusion
# ============================================================

info "RPM Fusion aktivieren"

RPMFUSION_FREE="https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm"
RPMFUSION_NONFREE="https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"

if sudo dnf install -y \
    "$RPMFUSION_FREE" \
    "$RPMFUSION_NONFREE"; then

    success "RPM Fusion aktiviert."
    SUCCESS+=("RPM Fusion")

else

    warning "RPM Fusion konnte nicht vollständig aktiviert werden."
    FAILED+=("RPM Fusion")

    echo "RPM-Fusion-abhängige Pakete könnten dadurch später fehlschlagen."

fi


# ============================================================
# Basis-Pakete
# ============================================================

info "Basis-Pakete installieren"

BASE_PACKAGES=(

    curl
    wget
    gnupg2
    ca-certificates
    flatpak

    ark
    bzip2
    cpio
    hashdeep
    p7zip
    unrar
    zip
    unzip

    jetbrains-mono-fonts
    liberation-fonts
    google-noto-sans-fonts
    google-noto-serif-fonts

    fastfetch
    htop
    btop

    filelight
    kcalc

    dolphin-plugins
    ffmpegthumbnailer
)

for package in "${BASE_PACKAGES[@]}"; do
    install_dnf_package "$package"
done


# ============================================================
# Multimedia
# ============================================================

info "Multimedia-Unterstützung"


# ------------------------------------------------------------
# Fedora FFmpeg gegen RPM-Fusion-FFmpeg tauschen
# ------------------------------------------------------------

echo
echo "Versuche ffmpeg-free gegen vollständiges ffmpeg auszutauschen..."

if sudo dnf swap \
    -y \
    ffmpeg-free \
    ffmpeg \
    --allowerasing; then

    success "Vollständiges FFmpeg aktiviert."
    SUCCESS+=("FFmpeg / RPM Fusion")

else

    warning "FFmpeg-Swap fehlgeschlagen."

    echo "Versuche stattdessen normale ffmpeg-Installation..."

    install_dnf_package ffmpeg

fi


# ------------------------------------------------------------
# Multimedia-Codecs
# ------------------------------------------------------------

MULTIMEDIA_PACKAGES=(

    libavcodec-freeworld
    gstreamer1-plugins-bad-freeworld
    gstreamer1-plugins-ugly
    libdvdcss

)

for package in "${MULTIMEDIA_PACKAGES[@]}"; do
    install_dnf_package "$package"
done


# ============================================================
# KDE-Anwendungen
# ============================================================

info "KDE-Anwendungen installieren"

KDE_PACKAGES=(

    kde-cli-tools
    kio-extras

    kate
    partitionmanager
    haruna

    ktorrent
    kde-connect
    yakuake
    k3b

    krita
    tokodon
    kasts

    skrooge
    krusader
)

for package in "${KDE_PACKAGES[@]}"; do
    install_dnf_package "$package"
done


# ============================================================
# Weitere native Programme
# ============================================================

info "Weitere native Programme installieren"

NATIVE_PACKAGES=(

    handbrake
    audacity

)

for package in "${NATIVE_PACKAGES[@]}"; do
    install_dnf_package "$package"
done


# ============================================================
# Helium Browser
# ============================================================

info "Helium Browser einrichten"

echo "Aktiviere COPR Repository imput/helium..."

if sudo dnf copr enable -y imput/helium; then

    success "Helium COPR aktiviert."
    SUCCESS+=("Helium Repository")

    install_dnf_package helium-bin

else

    error "Helium COPR konnte nicht aktiviert werden."
    FAILED+=("Helium Repository")

    echo "Helium wird übersprungen."

fi


# ============================================================
# Microsoft Edge
# ============================================================

info "Microsoft Edge einrichten"

echo "Importiere Microsoft Signing Key..."

if sudo rpm --import \
    https://packages.microsoft.com/keys/microsoft.asc; then

    success "Microsoft Signing Key importiert."

else

    warning "Microsoft Signing Key konnte nicht importiert werden."
    FAILED+=("Microsoft Signing Key")

fi


echo
echo "Microsoft Edge Repository prüfen..."

if sudo dnf repolist --all 2>/dev/null | grep -qi "microsoft-edge"; then

    success "Microsoft Edge Repository bereits vorhanden."
    SKIPPED+=("Microsoft Edge Repository")

else

    echo "Füge Microsoft Edge Repository hinzu..."

    if sudo dnf config-manager addrepo \
        --from-repofile=https://packages.microsoft.com/yumrepos/edge/config.repo; then

        success "Microsoft Edge Repository hinzugefügt."
        SUCCESS+=("Microsoft Edge Repository")

    else

        error "Microsoft Edge Repository konnte nicht hinzugefügt werden."
        FAILED+=("Microsoft Edge Repository")

    fi

fi


# Installation trotzdem versuchen.
# Vielleicht existiert das Repository bereits unter anderem Namen.

install_dnf_package microsoft-edge-stable


# ============================================================
# LibreWolf
# ============================================================

info "LibreWolf einrichten"

if sudo dnf repolist --all 2>/dev/null | grep -qi "librewolf"; then

    success "LibreWolf Repository bereits vorhanden."
    SKIPPED+=("LibreWolf Repository")

else

    echo "Füge LibreWolf Repository hinzu..."

    if sudo dnf config-manager addrepo \
        --from-repofile=https://repo.librewolf.net/librewolf.repo; then

        success "LibreWolf Repository hinzugefügt."
        SUCCESS+=("LibreWolf Repository")

    else

        error "LibreWolf Repository konnte nicht hinzugefügt werden."
        FAILED+=("LibreWolf Repository")

    fi

fi

install_dnf_package librewolf


# ============================================================
# Flathub
# ============================================================

info "Flathub aktivieren"

if flatpak remote-list 2>/dev/null | grep -q "^flathub"; then

    success "Flathub ist bereits aktiviert."
    SKIPPED+=("Flathub")

else

    if sudo flatpak remote-add \
        --if-not-exists \
        flathub \
        https://flathub.org/repo/flathub.flatpakrepo; then

        success "Flathub aktiviert."
        SUCCESS+=("Flathub")

    else

        error "Flathub konnte nicht aktiviert werden."
        FAILED+=("Flathub")

    fi

fi


# ============================================================
# Flatpak-Anwendungen
# ============================================================

info "Flatpak-Anwendungen installieren"

FLATPAKS=(

    com.spotify.Client

    io.anytype.anytype

    org.kde.plasmatube

    com.github.taiko2k.tauonmb

    au.com.shiftyjelly.pocketcasts

    com.github.jeromerobert.pdfarranger

    im.riot.Riot

    com.bitwarden.desktop

    org.telegram.desktop

    org.signal.Signal
)

for app in "${FLATPAKS[@]}"; do
    install_flatpak "$app"
done


# ============================================================
# Flatpak Updates
# ============================================================

info "Installierte Flatpaks aktualisieren"

if flatpak update -y --noninteractive; then

    success "Flatpaks aktualisiert."
    SUCCESS+=("Flatpak Updates")

else

    warning "Flatpak-Update konnte nicht vollständig durchgeführt werden."
    FAILED+=("Flatpak Updates")

fi


# ============================================================
# DNF Metadaten aktualisieren
# ============================================================

info "DNF-Metadaten aktualisieren"

if sudo dnf makecache; then

    success "DNF-Metadaten aktualisiert."

else

    warning "DNF-Metadaten konnten nicht vollständig aktualisiert werden."

fi


# ============================================================
# Ergebnis
# ============================================================

echo
echo
echo "============================================================"
echo " INSTALLATION ABGESCHLOSSEN"
echo "============================================================"

echo
echo -e "${GREEN}Erfolgreich: ${#SUCCESS[@]}${NC}"

if (( ${#SUCCESS[@]} > 0 )); then

    for item in "${SUCCESS[@]}"; do
        echo "  ✓ $item"
    done

fi


echo
echo -e "${YELLOW}Übersprungen / bereits vorhanden: ${#SKIPPED[@]}${NC}"

if (( ${#SKIPPED[@]} > 0 )); then

    for item in "${SKIPPED[@]}"; do
        echo "  - $item"
    done

fi


echo
echo -e "${RED}Fehlgeschlagen: ${#FAILED[@]}${NC}"

if (( ${#FAILED[@]} > 0 )); then

    for item in "${FAILED[@]}"; do
        echo "  ✗ $item"
    done

fi


echo
echo "============================================================"

if (( ${#FAILED[@]} == 0 )); then

    echo -e "${GREEN}Alle Installationen erfolgreich abgeschlossen.${NC}"

else

    echo -e "${YELLOW}Die Installation wurde abgeschlossen,"
    echo -e "aber ${#FAILED[@]} Vorgänge waren nicht erfolgreich.${NC}"

    echo
    echo "Die übrigen Anwendungen wurden davon nicht beeinflusst."

fi

echo
echo "Ein Neustart wird empfohlen."
echo
