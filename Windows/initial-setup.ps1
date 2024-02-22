# Configure preferred ExecutionPolicy.
# Switching from Unrestricted is also required for the scoop setup.
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Start-Process -FilePath powershell.exe -Verb RunAs -Wait -ArgumentList @(
    '-NoProfile',
    '-Command',
    "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force"
)

Install-Module -Name PSReadLine -Scope CurrentUser -Force

# Update all Microsoft Store apps (async)
Start-Process -FilePath powershell.exe -Verb RunAs -Wait -ArgumentList @(
    '-NoProfile',
    '-Command',
    '"Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName "UpdateScanMethod""'
)

# Update AppInstaller / winget
$CurlArgs = @(
    '--fail',
    '--location' # Follow redirects
    '--tls-max', '1.2',
    "https://github.com/microsoft/winget-cli/releases/download/v1.6.3482/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle",
    '--output',
    "$env:TEMP\ai.msixbundle"
)
curl.exe @CurlArgs

# Settings
## Disable notifications from Ad / spam apps
reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested" /v Enabled /t REG_DWORD /d 0 /f
reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.HelloFace" /v Enabled /t REG_DWORD /d 0 /f
## Disable Start Menu ads (W10 only?)
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f
## Disable Settings app suggested bing searches (W10 only?)
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338393Enabled /t REG_DWORD /d 0 /f
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353694Enabled /t REG_DWORD /d 0 /f
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353696Enabled /t REG_DWORD /d 0 /f
## Disable "News and Interests" in taskbar (W10 only)
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v ShellFeedsTaskbarViewMode /t REG_DWORD /d 2 /f
## Disable "Search highlights" (weird icons and spam articles in the search bar)
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsDynamicSearchBoxEnabled /t REG_DWORD /d 0 /f
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds\DSB" /v ShowDynamicContent /t REG_DWORD /d 0 /f
## Dark Theme
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
## Disable Windows 11 SnapLayout overlay on maximize button
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableSnapAssistFlyout /t REG_DWORD /d 0 /f
## Disable Aero Shake
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisallowShaking /t REG_DWORD /d 1 /f
## Open File Explorer with "This PC" as the initial view
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f
## Always show file extensions
reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f
## Set up CMD shell prompt and some default aliases for interactive shells
reg.exe add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d 'prompt $E[92m%USERNAME%@%COMPUTERNAME%$E[0m:$E[32m$P$E[0m$_$E(0mq$E(B cmd$G & doskey ls=dir /o $* & doskey cat=type $* & doskey reboot=shutdown /r /t 0 $* & doskey clear=cls' /f

# Wait for winget command to be come available (may need to wait for the "Microsoft.DesktopAppInstaller" app to update through the Store first)
# TODO: periodically re-run the store update CIM method because the store itself updating can sometimes interrupt and stop the updating process of other apps
Write-Host "Waiting for winget to become available ..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$OldProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'
do {
    $DAIVersion = (Get-AppxPackage -Name Microsoft.DesktopAppInstaller).Version
    $WingetCmd  = Get-Command -Name winget -CommandType Application -ErrorAction Ignore
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] winget available: $( if ($WingetCmd) { "True" } else { "False" } ), DesktopAppInstaller version: $DAIVersion"

    if ($sw.Elapsed -gt [TimeSpan]::FromMinutes(5)) {
        # Attempt install / update. This will fail for as long as some dependencies aren't there yet.
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Attempting DesktopAppInstaller update via msixbundle ..."
        Add-AppxPackage -Path "$env:TEMP\ai.msixbundle" -ErrorAction SilentlyContinue
        $sw.Restart()
    }
    Start-Sleep -Seconds 10
} until ($WingetCmd)
$ProgressPreference = $OldProgressPreference
$sw.Stop()

$preDesktop = [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('CommonDesktop') |
    Get-ChildItem -Filter '*.lnk'

# Install some software as non-portable versions
@(
    'Microsoft.VCRedist.2015+.x64', # Dependency of neovim
    '7zip.7zip',
    'SumatraPDF.SumatraPDF',
    'VideoLAN.VLC',
    'Mozilla.Firefox',
    'KeePassXCTeam.KeePassXC',
    'Microsoft.PowerShell',
    'Microsoft.PowerShell.Preview'
) | ForEach-Object {
    winget install --source winget --id "$_" --scope machine --silent --no-upgrade
}

# Cleaning up new unwhanted desktop icons
$postDesktop = [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('CommonDesktop') |
    Get-ChildItem -Filter '*.lnk'

Write-Host "Cleaning up winget created desktop icons..."
$postDesktop | Where-Object FullName -notin $preDesktop.FullName | % {
    Remove-Item -LiteralPath $_.FullName -ErrorAction SilentlyContinue
    if ($?) {
        Write-Host "Cleaned up $($_.Name)"
    } else {
        Write-Host "Could not clean up $($_.Name)"
    }
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
    'neovim', # winget has neovim now, maybe use that?
    'jq',
    'delta',
    'tokei',
    'sed',
    'bottom',
    'bat',
    'gcc', # Required by one/some of my neovim plugins
    'gping'
)

scoop install @ScoopPackages

# Clean up scoop package cache
scoop cache rm *

# Remove some default apps I don't use
@(
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.GetHelp'
    'Microsoft.Getstarted',
    'Microsoft.MixedReality.Portal',
    'Microsoft.SkypeApp',
    'Microsoft.Microsoft3DViewer',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.XboxApp'
) | Foreach-Object { Get-AppxPackage -Name $_ | Remove-AppxPackage }

if (-not (Test-Path -Path "$env:USERPROFILE\repos")) { mkdir "$env:USERPROFILE\repos" }

#git clone --origin github-https https://github.com/jantari/poshwal.git "${env:USERPROFILE}\repos\poshwal"
git clone --origin github-https https://github.com/jantari/configs.git "${env:USERPROFILE}\repos\configs"

# Neovim config setup
robocopy.exe "${env:USERPROFILE}\repos\configs\neovim" "${env:LOCALAPPDATA}\nvim" /E /XC /XN /XO /NP

# Set up PowerShell profile
[string]$Pwsh5Profile = [System.Environment]::GetFolderPath('MyDocuments') + '\PowerShell'
[string]$Pwsh7Profile = [System.Environment]::GetFolderPath('MyDocuments') + '\WindowsPowerShell'
Robocopy.exe "${env:USERPROFILE}\repos\configs\Windows\files" "$Pwsh5Profile" "Microsoft.PowerShell_profile.ps1" /NJH /NJS /NP /XO
Robocopy.exe "${env:USERPROFILE}\repos\configs\Windows\files" "$Pwsh7Profile" "Microsoft.PowerShell_profile.ps1" /NJH /NJS /NP /XO

. $PROFILE

# Conhost Theme
$CurlArgs = @(
    '--fail',
    '--location' # Follow redirects
    '--tls-max', '1.2',
    "https://gist.githubusercontent.com/jantari/6a20699d84470582608b55e3693fea0a/raw/af1550f9a9345dbd34f4cc8edbffd94de87de7c8/conhost-sapphire.reg",
    '--output',
    "$env:TEMP\ConhostSapphireTheme.reg"
)
curl.exe @CurlArgs
reg.exe import "$env:TEMP\ConhostSapphireTheme.reg"

# Restore Neovim plugins after config setup
nvim --headless -c "lua require('lazy').restore({wait=true})" -c qa

# Font
# --tls-max 1.2 is a workaround for this bug: https://github.com/curl/curl/issues/9431
# until windows ships with a version of curl in the box that includes: https://github.com/curl/curl/commit/12e1def51a75392df62e65490416007d7e68dab9
$CurlArgs = @(
    '--fail',
    '--location' # Follow redirects
    '--tls-max', '1.2',
    "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FantasqueSansMono/Regular/FantasqueSansMNerdFont-Regular.ttf",
    '--output',
    "$env:TEMP\FantasqueSansMono.ttf"
)
curl.exe @CurlArgs
(New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere("$env:TEMP\FantasqueSansMono.ttf", 0x14);
reg.exe add "HKCU\Console" /v FaceName /t REG_SZ /d "FantasqueSansM Nerd Font" /f
reg.exe add "HKCU\Console" /v FontFamily /t REG_DWORD /d 0x36 /f
reg.exe add "HKCU\Console" /v FontSize /t REG_DWORD /d 0x100000 /f
reg.exe add "HKCU\Console" /v FontWeight /t REG_DWORD /d 0x190 /f

# Remove theme settings from existing Shortcuts to PowerShell so the new theme applies everywhere including Win + X menu and the file explorer shortcuts
$wscriptCom = New-Object -ComObject WScript.Shell
$shortcuts  = Get-ChildItem -Path ([Environment]::GetFolderPath('Programs') + '\Windows PowerShell\*.lnk') -Exclude "*ISE*"
foreach ($shortcut in $shortcuts) {
    $OldShortcut = $wscriptCom.CreateShortcut($shortcut.FullName)
    if (Test-Path -Path ($shortcut.FullName + '.bak')) {
        Remove-Item -Path $shortcut.FullName
    } else {
        Rename-Item -Path $shortcut.FullName -NewName "$shortcut.bak"
    }
    $NewShortcut = $wscriptCom.CreateShortcut($shortcut.FullName)
    $NewShortcut.Description      = $OldShortcut.Description
    $NewShortcut.TargetPath       = $OldShortcut.TargetPath
    $NewShortcut.WorkingDirectory = $OldShortcut.WorkingDirectory
    $NewShortcut.Save()
}

# Install Windows Terminal Preview from Microsoft Store
winget install --source msstore --id "9N8G5RFZ9XK3" --accept-source-agreements --accept-package-agreements --silent
# Install Spotify from Microsoft Store
winget install --source msstore --id "9NCBCSZSJRSB"  --accept-source-agreements --accept-package-agreements --silent

# Begin As Administrator
#
# Set up WSL2
# https://learn.microsoft.com/en-us/windows/wsl/install
Start-Process -FilePath powershell.exe -Verb RunAs -Wait -ArgumentList @(
    '-NoProfile',
    '-Command',
    '"wsl --install --distribution Ubuntu-22.04 --no-launch"'
)

wsl --version
if ($LASTEXITCODE -ne 0) {
    Write-Error "WSL is not set up properly (or outdated). Retry after a reboot."
}
#
# End As Administrator

