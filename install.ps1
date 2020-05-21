. (Join-Path (pwd) common.ps1)
New-Item $dataFolder -ItemType Directory -Force

$env:RABBITMQ_BASE = "$dataFolder\data"
[Environment]::SetEnvironmentVariable("RABBITMQ_BASE", "$dataFolder\data", "Machine")

$env:RABBITMQ_MNESIA_BASE = "$dataFolder\data\cluster"
[Environment]::SetEnvironmentVariable("RABBITMQ_MNESIA_BASE", "$dataFolder\data\cluster", "Machine")
  
$env:RABBITMQ_ERLANG_COOKIE = "NYHBTWHELPSDAMMUMJGP"
[Environment]::SetEnvironmentVariable("RABBITMQ_ERLANG_COOKIE", "NYHBTWHELPSDAMMUMJGP", "Machine")
#choco install erlang --version 20.3 /y
SyncCookie -cookie $env:RABBITMQ_ERLANG_COOKIE
choco install rabbitmq --version 3.7.6 /y /f
$env:ERLANG_HOME = [System.Environment]::GetEnvironmentVariable("ERLANG_HOME", "Machine")
Write-Host "Erlang home $env:ERLANG_HOME"
Write-Host "Waiting for node to warm up"
Start-Sleep -Seconds 35
Write-Host "Setting up main user"
.$binPath\rabbitmqctl.bat add_user mainuser mainuser
.$binPath\rabbitmqctl.bat set_user_tags mainuser administrator
.$binPath\rabbitmqctl.bat set_permissions -p / mainuser ".*" ".*" ".*"
 
 
