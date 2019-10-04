
$binPath = "$($drive):\Program Files\RabbitMQ Server\rabbitmq_server-$rmqVer\sbin"

function SyncCookie($cookie) { 
    $p = "$env:windir\System32\config\systemprofile\.erlang.cookie"
    if (Test-Path $p) {
        Remove-Item $p -Force        
    } 
    [System.IO.File]::WriteAllText($p, $cookie)
    $p = "$env:USERPROFILE\.erlang.cookie"   
    if (Test-Path $p) {
        Remove-Item $p -Force        
    } 
    [System.IO.File]::WriteAllText($p, $cookie)
    
}

function SetBaseVariables {
    
    $env:RABBITMQ_BASE = "$dataFolder\data"
    [Environment]::SetEnvironmentVariable("RABBITMQ_BASE", "$dataFolder\data", "Machine")

    $env:RABBITMQ_MNESIA_BASE = "$dataFolder\data\cluster"
    [Environment]::SetEnvironmentVariable("RABBITMQ_MNESIA_BASE", "$dataFolder\data\cluster", "Machine")
  
    $env:RABBITMQ_ERLANG_COOKIE = "NYHBTWHELPSDAMMUMJGP"
    [Environment]::SetEnvironmentVariable("RABBITMQ_ERLANG_COOKIE", "NYHBTWHELPSDAMMUMJGP", "Machine")
    SyncCookie -cookie $env:RABBITMQ_ERLANG_COOKIE
}

function Install() {

    Stop-Process -name "epmd" -Force -ErrorAction SilentlyContinue
    $env:ERLANG_HOME = [System.Environment]::GetEnvironmentVariable("ERLANG_HOME", "Machine")
    if ($env:ERLANG_HOME -eq $null) {
        $destFile = (Join-Path (Get-Location) otp_win64_$erLang.exe)
        if ( -not (Test-Path $destFile) ) {
            Write-Host "Downloading  Erlang http://erlang.org/download/otp_win64_$erLang.exe"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest "http://erlang.org/download/otp_win64_$erLang.exe" -OutFile $destFile
        }
        Write-Host "Installing Erlang"
        & $destFile | Out-Null
    }
    $ERLANG_HOME = ((Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Ericsson\Erlang)[0] | Get-ItemProperty).'(default)'
    $env:ERLANG_HOME = [System.Environment]::GetEnvironmentVariable("ERLANG_HOME", "Machine")
    if ($env:ERLANG_HOME -eq $null -and $ERLANG_HOME -ne $null) {
        [Environment]::SetEnvironmentVariable("ERLANG_HOME", $ERLANG_HOME, "Machine")
        $env:ERLANG_HOME = $ERLANG_HOME
    }
    elseif ($ERLANG_HOME -eq $null) { $ERLANG_HOME = $env:ERLANG_HOME }
    
    if ($ERLANG_HOME -eq $null) {
        Write-Host "Erlang was not installed successfully, try restart the shell an rerun the script."
        return
    } 
    SetBaseVariables
    $destFile = (Join-Path (Get-Location) rabbitmq-server-$rmqVer.exe)
    if ( -not (Test-Path $destFile) ) {
        # https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.6/rabbitmq-server-3.7.6.exe
        Write-Host "Downloading  RabbitMQ https://github.com/rabbitmq/rabbitmq-server/releases/download/v$rmqVer/rabbitmq-server-$rmqVer.exe"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest https://github.com/rabbitmq/rabbitmq-server/releases/download/v$rmqVer/rabbitmq-server-$rmqVer.exe -OutFile $destFile
    }

    If (Get-Service "RabbitmQ" -ErrorAction SilentlyContinue) {
    }
    else {
    
        Write-Host "Installing RabbitMQ"
    
        & $destFile | Out-Null
    }
    
    Write-Host "Erlang home $env:ERLANG_HOME"

    Write-Host "Installing plugins"
    .$binPath\rabbitmq-plugins.bat enable rabbitmq_management


    Write-Host "Waiting for node to warm up"
    Start-Sleep -Seconds 25
    Write-Host "Setting up main user"
    .$binPath\rabbitmqctl add_user mainuser mainuser | Out-Null
    .$binPath\rabbitmqctl set_user_tags mainuser administrator | Out-Null
    .$binPath\rabbitmqctl set_permissions -p / mainuser ".*" ".*" ".*" | Out-Null
}