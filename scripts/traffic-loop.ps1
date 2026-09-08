$ErrorActionPreference = "Stop"
$sec = 0
$suricataDir = "D:\soc-lab\config\suricata"
$seed = "C:\Users\Rudraksh Dixit\Desktop\cloud-siem-lab\seed-localstack.py"

Write-Host "traffic-loop: suricata attacks + cloudtrail re-seed. Ctrl+C to stop."
while ($true) {
    $sec++
    docker compose -f "$suricataDir\docker-compose.yml" restart attacker | Out-Null
    Write-Host ("[{0}] suricata attacker re-ran (port scan + RDP probes now in swarm)" -f (Get-Date -Format HH:mm:ss))
    Start-Sleep -Seconds 45

    if (($sec % 3) -eq 0) {
        Write-Host ("[{0}] re-seeding cloudtrail events (epoch-unique keys, wodle picks up within 10m)" -f (Get-Date -Format HH:mm:ss))
        python $seed | Out-Null
    }
    Start-Sleep -Seconds 45
}