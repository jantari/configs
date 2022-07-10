Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History

if ($PSStyle) {
    $PSStyle.FileInfo.Directory = "`e[4;1m"
}

Invoke-Expression (&starship init powershell)
