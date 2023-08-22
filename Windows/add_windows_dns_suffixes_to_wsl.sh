#!/bin/bash

# https://github.com/microsoft/WSL/issues/701#issuecomment-1162887704
# https://github.com/microsoft/WSL/issues/701#issuecomment-1428917142

set -euo pipefail

# Gets the global DNS domain of the computer as well as the DNS search suffix domains of all
# individual network interfaces, deduplicates any entries and formats them in a single line
DNSSEARCH=$(/mnt/c/windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoLogo -NoProfile -Command \
  '@([System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName;
  [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces().GetIPProperties().DnsSuffix;
  (Get-DnsClientGlobalSetting).SuffixSearchLIst).Where({ $_ })')

#  | tr -d '\r' | uniq | tr -s '\n' ' ')

echo "Will set search domains: ${DNSSEARCH}"

# Replacing or appending 'search ...' config line in resolv.conf
wsl.exe -d "${WSL_DISTRO_NAME}" -u root -e /usr/bin/sed -i \
  -e '/^\(search[[:blank:]]\).*/{s//\1'"${DNSSEARCH}"'/;:a;n;ba;q}' \
  -e '$asearch '"${DNSSEARCH}" \
  /etc/resolv.conf

