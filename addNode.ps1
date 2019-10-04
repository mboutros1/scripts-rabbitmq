[CmdletBinding()]
Param(
    [Parameter(Mandatory = $False)] [string]$machineName    
)
.(Join-Path (pwd) common.ps1)
if ($machineName -eq [string]::Empty) {    
    Write-Host "Enter the other node machine name as listed in the host.txt (in this script directory)"
    Write-Host "The script will append/update the system hosts file with the content of the hosts.txt in this directory"
    $machineName = Read-Host
    $machineName = $machineName.trim()
}
$hostPath = "C:\Windows\System32\drivers\etc\hosts"
$txt = [System.IO.File]::ReadAllText((($hostPath))) 
$hostTempPath = Join-Path (pwd)   "hosts.txt"
$entry = [System.IO.File]::ReadAllText($hostTempPath) 
$pattern = '# RabbitMQ(.|\n)*?# EndRabbitMQ'
$entry = "
# RabbitMQ
$entry
# EndRabbitMQ"
Write-Host "Updating host file"
if ($txt -match $pattern -eq $true) {
    $txt = $txt -replace $pattern, $entry    
}
else {
    $txt = $txt + "\r" + $entry
}
[System.IO.File]::WriteAllText($hostPath, $txt) 


.$binPath\rabbitmq-service stop
SyncCookie -cookie $env:RABBITMQ_ERLANG_COOKIE

.$binPath\rabbitmq-service start

.$binPath\rabbitmqctl reset
.$binPath\rabbitmqctl stop_app
.$binPath\rabbitmqctl join_cluster rabbit@$machineName
.$binPath\rabbitmqctl start_app

.$binPath\rabbitmqctl cluster_status 