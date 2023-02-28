# Configure preferred ExecutionPolicy.
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

# Font
# --tls-max 1.2 is a workaround for this bug: https://github.com/curl/curl/issues/9431
# until windows ships with a version of curl in the box that includes: https://github.com/curl/curl/commit/12e1def51a75392df62e65490416007d7e68dab9
$CurlArgs = @(
    '--fail',
    '--location' # Follow redirects
    '--tls-max', '1.2',
    "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FantasqueSansMono/Regular/complete/Fantasque%20Sans%20Mono%20Regular%20Nerd%20Font%20Complete%20Windows%20Compatible.ttf",
    '--output',
    "$env:TEMP\FantasqueSansMono.ttf"
)
curl.exe @CurlArgs
(New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere("$env:TEMP\FantasqueSansMono.ttf", 0x14);
reg.exe add "HKCU\Console" /v FaceName /t REG_SZ /d "FantasqueSansMono NF" /f
reg.exe add "HKCU\Console" /v FontFamily /t REG_DWORD /d 0x36 /f
reg.exe add "HKCU\Console" /v FontSize /t REG_DWORD /d 0x100000 /f
reg.exe add "HKCU\Console" /v FontWeight /t REG_DWORD /d 0x190 /f

if (-not (Test-Path -LiteralPath $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force }

if (-not ((Get-Content -LiteralPath $PROFILE -ErrorAction Ignore) -like '*starship init powershell*')) {
    Add-Content -LiteralPath $PROFILE -Value 'Invoke-Expression (&starship init powershell)' -Force
    . $PROFILE
}

# Install Windows Terminal Preview from Microsoft Store
winget install --source msstore --id "9N8G5RFZ9XK3" --accept-source-agreements --accept-package-agreements --silent

# Settings
## Disable Windows 11 SnapLayout overlay on maximize button
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableSnapAssistFlyout /t REG_DWORD /d 0 /f

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

