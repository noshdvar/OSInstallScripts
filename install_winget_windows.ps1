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
    @{ Id = "2Team.NanaZip";               Name = "NanaZip" },
    @{ Id = "DEVCOM.JetBrainsMonoNerdFont"; Name = "JetBrains Mono Nerdfont" },
    @{ Id = "RustDesk.RustDesk";           Name = "RustDesk" },
    @{ Id = "TeamViewer.TeamViewer";       Name = "TeamViewer" },
    @{ Id = "Fastfetch-cli.Fastfetch";     Name = "Fastfetch" },
    @{ Id = "LibreWolf.LibreWolf";         Name = "LibreWolf" },
    @{ Id = "JGraph.Draw";                 Name = "draw.io Desktop" },    
    @{ Id = "DoubleCommander.DoubleCommander"; Name = "Double Commander" },
    @{ Id = "CrystalDiskMark.CrystalDiskMark"; Name = "CrystalDiskMark" },
    @{ Id = "ArtCraft.PdfCraft";           Name = "PDFCraft" },
    @{ Id = "TheDocumentFoundation.LibreOffice"; Name = "LibreOffice" },
    @{ Id = "Greenshot.Greenshot";         Name = "Greenshot" },
    @{ Id = "OO-Software.ShutUp10";        Name = "O&O ShutUp10++" },
    @{ Id = "Microsoft.VisualStudioCode";  Name = "Visual Studio Code" },
    @{ Id = "mRemoteNG.mRemoteNG";         Name = "mRemoteNG" },
    @{ Id = "JanDeDobbeleer.OhMyPosh";     Name = "Oh My Posh" },
    @{ Id = "Microsoft.PowerToys";         Name = "Microsoft PowerToys" },
    @{ Id = "CodecGuide.K-LiteCodecPack.Mega"; Name = "K-LiteCodecPack.Mega" }
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

# Profil bei Bedarf anlegen.
$profileDirectory = Split-Path -Parent $PROFILE

if (-not (Test-Path -LiteralPath $profileDirectory)) {
    New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# Initialisierung nur einmal hinzufuegen.
$initLine = 'oh-my-posh init pwsh | Invoke-Expression'
$profileContent = Get-Content -LiteralPath $PROFILE -Raw

if ($profileContent -notmatch '(?m)^\s*oh-my-posh\s+init\s+pwsh\b') {
    Add-Content -LiteralPath $PROFILE -Value "`r`n$initLine" -Encoding UTF8
}

# Profil fuer die aktuelle Sitzung laden.
. $PROFILE


Write-Host ""
Write-Host "=== Winget-Installation abgeschlossen ===" -ForegroundColor Green
Write-Host ""
Write-Host "Installiere nun noch Huetro for Hue, Snapmaker Orca, Orcaslicer, Towdow.app aus dem Microsoft Store, sowie den Helium Browser und https://www.michieldb.nl/other/cursors/ Posys 125% cursor" -ForegroundColor Green
