# Configure preferred ExecutionPolicy.
# Switching from Unrestricted is also required for the scoop setup.
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# New unique pipe name every time to avoid conflicts
[string]$PipeName = 'psipc-' + (New-Guid).Guid
[string]$ElevatedClient = @'
[string]$PipeName = '{0}'
'@ -f $PipeName + @'

# Fail early on all possible errors and inform the parent
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$global:ErrorActionPreference = 'Stop'

trap {
    Write-Host "$_"
    #$ss.WriteString("ERROR");
    &pause
    break
}

Write-Host "GOT PARAMETER: $PipeName"

class StreamString {
    [System.IO.Stream]$ioStream
    [System.Text.UTF8Encoding]$streamEncoding

    [PSObject] ReadString() {
        [int]$len = 0;
        $CmdId = $this.ioStream.ReadByte()
        $flags = $this.ioStream.ReadByte()
        $len = $this.ioStream.ReadByte()
        if ($len -eq -1) {
            return $null
        }
        $len = $len * 256
        $len += $this.ioStream.ReadByte()
        $inBuffer = [Byte[]]::new($len)
        $this.ioStream.Read($inBuffer, 0, $len)
        return [PSCustomObject]@{
            'CommandId' = $CmdId
            'RunSync'   = [bool]($flags -band 1)
            'Command'   = $this.streamEncoding.GetString($inBuffer)
        }
    }

    [int] WriteString([string]$outString) {
        [byte[]]$outBuffer = $this.streamEncoding.GetBytes($outString)
        [int]$len = $outBuffer.Length
        if ($len -gt [UInt16]::MaxValue) {
            $len = [UInt16]::MaxValue
        }
        $this.ioStream.WriteByte([byte][Math]::Floor($len / 256))
        $this.ioStream.WriteByte([byte]($len -band 255))
        $this.ioStream.Write($outBuffer, 0, $len)
        $this.ioStream.Flush();
        return $outBuffer.Length + 2;
    }
}

$pipeClient = [System.IO.Pipes.NamedPipeClientStream]::new(".", $PipeName, 'InOut', 'None')
Write-Host "Connecting back to parent process/server..."
$pipeClient.Connect();
Write-Host 'Connected!'

$CommandQueue     = [System.Collections.Queue]::Synchronized( [System.Collections.Queue]::new() )
$CommandRunningHT = [Hashtable]::Synchronized( @{'CommandRunning' = $false } )
$TSPipeClient     = [System.IO.Stream]::Synchronized($pipeClient)

$ss = [StreamString]@{
    'ioStream' = $TSPipeClient
    'streamEncoding' = [System.Text.UnicodeEncoding]::UTF8
}



$runspace  = [runspacefactory]::CreateRunspace()
$runspace.Open()

$runspace.SessionStateProxy.SetVariable('CommandQueue',   $CommandQueue)
$runspace.SessionStateProxy.SetVariable('CommandRunningHT', $CommandRunningHT)
$runspace.SessionStateProxy.SetVariable('TSPipeClient',   $TSPipeClient)

$powershell = [powershell]::Create()
$powershell.Runspace = $runspace

$powershell.AddScript({
    class StreamString {
        [System.IO.Stream]$ioStream
        [System.Text.UTF8Encoding]$streamEncoding

        [PSObject] ReadString() {
            [int]$len = 0;
            $CmdId = $this.ioStream.ReadByte()
            $flags = $this.ioStream.ReadByte()
            $len = $this.ioStream.ReadByte()
            if ($len -eq -1) {
                return $null
            }
            $len = $len * 256
            $len += $this.ioStream.ReadByte()
            $inBuffer = [Byte[]]::new($len)
            $this.ioStream.Read($inBuffer, 0, $len)
            return [PSCustomObject]@{
                'CommandId' = $CmdId
                'RunSync'   = [bool]($flags -band 1)
                'Command'   = $this.streamEncoding.GetString($inBuffer)
            }
        }

        [int] WriteString([string]$outString) {
            [byte[]]$outBuffer = $this.streamEncoding.GetBytes($outString)
            [int]$len = $outBuffer.Length
            if ($len -gt [UInt16]::MaxValue) {
                $len = [UInt16]::MaxValue
            }
            $this.ioStream.WriteByte([byte][Math]::Floor($len / 256))
            $this.ioStream.WriteByte([byte]($len -band 255))
            $this.ioStream.Write($outBuffer, 0, $len)
            $this.ioStream.Flush();
            return $outBuffer.Length + 2;
        }
    }

    $ss = [StreamString]@{
        'ioStream' = $TSPipeClient
        'streamEncoding' = [System.Text.UnicodeEncoding]::UTF8
    }

    $ss.WriteString("READY_FOR_INSTRUCTIONS")

    do {
        $IncomingCmd = $ss.ReadString()
        $CommandQueue.Enqueue($IncomingCmd)
        if ($IncomingCmd.RunSync) {
            $ss.WriteString("ENQUEUED $($IncomingCmd.CommandId) (SYNC)")
            # Wait and dont enqueue more commands until the just-queued
            # synchronous command has finished (aka the queue is empty)
            # because if we loop around again and wait for more commands
            # to queue, ReadString() blocks the pipe on our end and we
            # can't write to it to communicate the exec status of the sync
            # command back to our parent process.
            do {
                Start-Sleep -Seconds 1
            } until ($CommandQueue.Count -eq 0 -and $CommandRunningHT['CommandRunning'] -eq $false)
        }
    } while (1)
}).AddArgument($PipeName) | Out-Null

$CommandRunspace = $powershell.BeginInvoke()

$LastReportedQueueSize = -1
$WorkerRunspace = [powershell]::Create()
$Handle = $null

do {
    if ($CommandQueue.Count -ne $LastReportedQueueSize) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $($CommandQueue.Count) commands waiting in the queue" -ForegroundColor Yellow
        $LastReportedQueueSize = $CommandQueue.Count
    }

    if ($CommandQueue.Count -and $WorkerRunspace.Runspace.RunspaceAvailability -eq 'Available') {
        Write-Host "Executing next command ..." -ForegroundColor Yellow
        $CommandRunningHT['CommandRunning'] = $true
        $CmdData = $CommandQueue.Dequeue()
        $null   = $WorkerRunspace.AddScript( [ScriptBlock]::Create($CmdData.Command) )
        $Handle = $WorkerRunspace.BeginInvoke()
        if ($CmdData.RunSync) {
            $null = $ss.WriteString("STARTED $($CmdData.CommandId)");
        }
    }

    Start-Sleep -Seconds 2

    if ($Handle -and $Handle.IsCompleted) {
        Write-Host "Calling EndInvoke() for a completed command ..." -ForegroundColor Yellow
        $WorkerRunspace.EndInvoke($handle)
        $Handle = $null
        if ($CmdData.RunSync) {
            $null = $ss.WriteString("FINISHED $($CmdData.CommandId)");
        }
        $CommandRunningHT['CommandRunning'] = $false
    }
} while (1)
'@

[string]$ElevatedClientB64 = [System.Convert]::ToBase64String( [System.Text.Encoding]::Unicode.GetBytes($ElevatedClient) )
Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList "-NoExit -NonInteractive -NoProfile -EncodedCommand $ElevatedClientB64"

class StreamString {
    [System.IO.Stream]$ioStream
    [System.Text.UTF8Encoding]$streamEncoding

    [PSObject] ReadString() {
        [int]$len = 0;
        $len = $this.ioStream.ReadByte()
        if ($len -eq -1) {
            return $null
        }
        $len = $len * 256
        $len += $this.ioStream.ReadByte()
        $inBuffer = [Byte[]]::new($len)
        $this.ioStream.Read($inBuffer, 0, $len)
        return $this.streamEncoding.GetString($inBuffer)
    }

    [int] WriteString([string]$outString) {
        [byte[]]$outBuffer = $this.streamEncoding.GetBytes($outString)
        [int]$len = $outBuffer.Length
        if ($len -gt [UInt16]::MaxValue) {
            $len = [UInt16]::MaxValue
        }
        $this.ioStream.WriteByte([byte]0) # CommandId, doesn't matter if we're not waiting on it
        $this.ioStream.WriteByte([byte]0) # 0b00000000 as the flag for "run this asynchronously"
        $this.ioStream.WriteByte([byte][Math]::Floor($len / 256))
        $this.ioStream.WriteByte([byte]($len -band 255))
        $this.ioStream.Write($outBuffer, 0, $len)
        $this.ioStream.Flush();
        return $outBuffer.Length + 2;
    }

    [PSObject] EnqueueCommandAndWait([byte]$CommandId, [string]$outString) {
        [byte[]]$outBuffer = $this.streamEncoding.GetBytes($outString)
        [int]$len = $outBuffer.Length
        if ($len -gt [UInt16]::MaxValue) {
            $len = [UInt16]::MaxValue
        }
        $this.ioStream.WriteByte($CommandId) # CommandId, so we know what to wait for
        $this.ioStream.WriteByte([byte]1) # 0b00000001 as the flag for "run this synchronously"
        $this.ioStream.WriteByte([byte][Math]::Floor($len / 256))
        $this.ioStream.WriteByte([byte]($len -band 255))
        $this.ioStream.Write($outBuffer, 0, $len)
        $this.ioStream.Flush();

        $read = ''
        do {
            Write-Host "Blocking in read from pipe (getting exec status) ..."
            $read = $this.ReadString()
            Write-Host "[CLIENT] $read"
        } until ($read -eq "FINISHED $CommandId")

        return $outBuffer.Length + 4;
    }
}

$namedPipeServer = [System.IO.Pipes.NamedPipeServerStream]::new($PipeName, 'InOut', 1, 'Byte');

$task = $namedPipeServer.WaitForConnectionAsync()
do {
    Write-Host "Waiting for pipe connection"
} until ($task.Wait([timespan]::FromSeconds(2)))

$ss = [StreamString]@{
    'ioStream' = $namedPipeServer
    'streamEncoding' = [System.Text.UnicodeEncoding]::UTF8
}

Write-Host "Reading first line from child process:"
do {
    $read = $ss.ReadString()
    Write-Host "[CLIENT] $read"
} until ($read -eq 'READY_FOR_INSTRUCTIONS')

# Send commands!
$ss.EnqueueCommandAndWait(42, 'Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force') | Out-Host

Install-Module -Name PSReadLine -Scope CurrentUser -Force

# Update all Microsoft Store apps (async)
$ss.WriteString('Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName "UpdateScanMethod"') | Out-Host

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
$WaitTimer = [System.Diagnostics.Stopwatch]::StartNew()
[TimeSpan]$LastInitiatedStoreUpdate = [TimeSpan]::Zero
do {
    $DAIVersion = (Get-AppxPackage -Name Microsoft.DesktopAppInstaller).Version
    $WingetCmd  = Get-Command -Name winget -CommandType Application -ErrorAction Ignore
    Write-Host "[$(Get-Date -Format 'HH:mm:ss') - $($WaitTimer.Elapsed)] winget available: $( if ($WingetCmd) { "True" } else { "False" } ), DesktopAppInstaller version: $DAIVersion"
    Start-Sleep -Seconds 10
    # Re-initiate Store updates every 5 minues until winget is available
    if ($WaitTimer.Elapsed - $LastInitiatedStoreUpdate -ge [TimeSpan]::FromMinutes(5)) {
        # Update all Microsoft Store apps (async)
        Write-Host "[$(Get-Date -Format 'HH:mm:ss') - $($WaitTimer.Elapsed)] Re-initializing Store app updates"
        $ss.WriteString('Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName "UpdateScanMethod"') | Out-Host
        $LastInitiatedStoreUpdate = $WaitTimer.Elapsed
    }
} until ($WingetCmd)

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
    $null = $ss.WriteString("winget install --source winget --id `"$_`" --scope machine --silent --no-upgrade")
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
$ss.EnqueueCommandAndWait(43, 'wsl --install --no-distribution') | Out-Host

wsl --version
if ($LASTEXITCODE -ne 0) {
    Write-Error "WSL is not set up properly (or outdated). Retry after a reboot."
}
#
# End As Administrator

