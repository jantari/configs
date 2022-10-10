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
    'bat'
)

scoop install @ScoopPackages

# Install Windows Terminal Preview from Microsoft Store
winget install --source msstore --id "9N8G5RFZ9XK3" --accept-source-agreements --accept-package-agreements --silent

