#Requires -Version 5.1
# Windows-Installationsskript – Entsprechung zu install_deb_kdeapps.sh

$ErrorActionPreference = "Continue"

function Install-WingetApp {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$Name = $Id
    )

    Write-Host "==> Installiere: $Name ($Id)" -ForegroundColor Cyan

    winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Installation fehlgeschlagen oder bereits vorhanden: $Name ($Id)"
    }
}

# --- Basis- und Systemwerkzeuge ---
$baseApps = @(
    @{ Id = "cURL.cURL";                   Name = "curl" },
    @{ Id = "GnuPG.GnuPG";                 Name = "GnuPG" },
    @{ Id = "2Team.NanaZip";               Name = „NanaZip“ },
    @{ Id = "JetBrainsMono.JetBrainsMono"; Name = "JetBrains Mono" }
    @{ Id = "RustDesk.RustDesk";           Name = "RustDesk" },
    @{ Id = "TeamViewer.TeamViewer";       Name = "TeamViewer" },
    @{ Id = "Fastfetch-cli.Fastfetch";     Name = "Fastfetch" },
    @{ Id = "LibreWolf.LibreWolf";         Name = "LibreWolf" },
    @{ Id = "JGraph.Draw";                 Name = "draw.io Desktop" },    
    @{ Id = "DoubleCommander.DoubleCommander"; Name = "Double Commander" },
    @{ Id = "CrystalDiskMark.CrystalDiskMark"; Name = "CrystalDiskMark" },
    @{ Id = "ArtCraft.PdfCraft";           Name = „PDFCraft“ },
    @{ Id = "TheDocumentFoundation.LibreOffice"; Name = "LibreOffice" },
    @{ Id = "Greenshot.Greenshot";         Name = "Greenshot" },
    @{ Id = "OO-Software.ShutUp10";        Name = "O&O ShutUp10++" },
    @{ Id = "Microsoft.VisualStudioCode";  Name = "Visual Studio Code" },
    @{ Id = "mRemoteNG.mRemoteNG";         Name = "mRemoteNG" }
)

# --- KDE- und Desktop-Anwendungen ---
$kdeApps = @(
    @{ Id = "KDE.Krita";                   Name = "Krita" },
    @{ Id = "KDE.Kdenlive";                Name = "Kdenlive" },
    @{ Id = "Audacity.Audacity";           Name = "Audacity" },
    @{ Id = "HandBrake.HandBrake";         Name = "HandBrake" },
    @{ Id = "mpv.net";                     Name = "mpv.net" },
    @{ Id = "Threema.ThreemaDesktop";      Name = "Threema Desktop" },
    @{ Id = "OpenWhisperSystems.Signal";   Name = "Signal Desktop" },
    @{ Id = "Telegram.TelegramDesktop";    Name = "Telegram Desktop" },
    @{ Id = "Element.Element";             Name = "Element / Matrix" },
    @{ Id = "Spotify.Spotify";             Name = "Spotify" }
)

# --- Medien ---
$mediaApps = @(
    @{ Id = "qBittorrent.qBittorrent";         Name = "qBittorrent" },
    @{ Id = "MakeMKV.MakeMKV";                 Name = "MakeMKV" },
    @{ Id = "Betterbird.Betterbird";           Name = "Betterbird" },
    @{ Id = "Mumble.Mumble";                   Name = "Mumble" },
    @{ Id = "enzo1982.freac";                  Name = "fre:ac – CD-Ripper / FLAC" },
    @{ Id = "AndreWiethoff.ExactAudioCopy";    Name = "Exact Audio Copy – präziser CD-Ripper" },
    @{ Id = "calibre.calibre";                 Name = "Calibre" },
    @{ Id = "Nextcloud.NextcloudDesktop";      Name = "Nextcloud Desktop" },
    @{ Id = "Valve.Steam";                     Name = "Steam" }
)

foreach ($app in ($baseApps + $kdeApps + $mediaApps)) {
    Install-WingetApp -Id $app.Id -Name $app.Name
}

Write-Host ""
Write-Host "=== Winget-Installation abgeschlossen ===" -ForegroundColor Green
Write-Host ""
Write-Host "Installiere nun noch Huetro for Hue, Snapmaker Orca, Orcaslicer, Towdow.app aus dem Microsoft Store, sowie den Helium Browser und https://www.michieldb.nl/other/cursors/ Posys 125% cursor" -ForegroundColor Green
