﻿# Configure preferred ExecutionPolicy.
# Switching from Unrestricted is also required for the scoop setup.
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install some software as non-portable versions
@(
    '7zip.7zip',
    'SumatraPDF.SumatraPDF',
    'VideoLAN.VLC',
    'Mozilla.Firefox',
    'KeePassXCTeam.KeePassXC',
    'Microsoft.PowerShell',
    'Microsoft.PowerShell.Preview'
) | ForEach-Object {
    winget install --source winget --id "$_" --scope machine --silent
}

# Install scoop
if (-not (Get-Command scoop -ErrorAction Ignore)) {
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
}

# Install git first because scoop uses it to self-update
scoop install git

scoop bucket add extras
scoop update

$ScoopPackages = @(
    'starship',
    'neovim',
    'jq',
    'delta',
    'tokei',
    'sed',
    'bottom',
    'bat',
    'gping'
)

scoop install @ScoopPackages

if (-not (Test-Path -LiteralPath $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force }

if (-not ((Get-Content -LiteralPath $PROFILE -ErrorAction Ignore) -like '*starship init powershell*')) {
    Add-Content -LiteralPath $PROFILE -Value 'Invoke-Expression (&starship init powershell)' -Force
    . $PROFILE
}

# Install Windows Terminal Preview from Microsoft Store
winget install --source msstore --id "9N8G5RFZ9XK3" --accept-source-agreements --accept-package-agreements --silent

# Begin As Administrator
#
# Set up WSL2
# https://learn.microsoft.com/en-us/windows/wsl/install
Start-Process -FilePath powershell.exe -Verb RunAs -Wait -ArgumentList @(
    '-NoProfile',
    '-Command',
    '"wsl --install --no-distribution"'
)

wsl --version
if ($LASTEXITCODE -ne 0) {
    Write-Error "WSL is not set up properly (or outdated). Retry after a reboot."
}
#
# End As Administrator

