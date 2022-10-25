Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineKeyHandler -Chord 'Alt+F4' -ScriptBlock { Write-Host "Exiting ..."; [Environment]::Exit(0) }
Set-PSReadLineOption -PredictionSource History

if ($PSStyle) {
    $PSStyle.FileInfo.Directory = "`e[4;1m"
}

Invoke-Expression (&starship init powershell)
