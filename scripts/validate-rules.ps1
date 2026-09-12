param(
    [Parameter(Mandatory=$true)]
    [string]$RulePath
)

if (-not (Test-Path $RulePath)) {
    Write-Error "File not found: $RulePath"
    exit 1
}

Write-Host "[*] Validating custom Wazuh rules: $RulePath"
$result = docker exec wazuh.manager /var/ossec/bin/wazuh-analysisd -t 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] Rules validated successfully"
} else {
    Write-Host "[-] Rule validation failed:"
    Write-Host $result
    exit 1
}
