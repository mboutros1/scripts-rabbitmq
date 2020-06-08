
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
    $erlangkey = Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Ericsson\Erlang -ErrorAction SilentlyContinue   
    
    if ($null -eq $erlangkey) {
        $destFile = (Join-Path (Get-Location) otp_win64_$erLang.exe)
        if ( -not (Test-Path $destFile) ) {
            Write-Host "Downloading  Erlang http://erlang.org/download/otp_win64_$erLang.exe"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest "http://erlang.org/download/otp_win64_$erLang.exe" -OutFile $destFile
        }
        Write-Host "Installing Erlang"
        ##& $destFile | Out-Null
        $ags = "/S /D=$drive" + ":\Program Files\er10.3"
        Write-Host "$destFile  $ags"
        Start-Process -Wait $destFile  $ags         
        $erHome = ((Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Ericsson\Erlang)[0] | Get-ItemProperty).'(default)'
    }
    else {
        $erHome = ((Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Ericsson\Erlang)[0] | Get-ItemProperty).'(default)'
    }
    $env:ERLANG_HOME = [System.Environment]::GetEnvironmentVariable("ERLANG_HOME", "Machine")
    if ($env:ERLANG_HOME -eq $null -and $null -ne $erHome) {
        [Environment]::SetEnvironmentVariable("ERLANG_HOME", $erHome, "Machine")
        $env:ERLANG_HOME = $erHome
    }
 
    if ($null -eq $erHome) {
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
        $rabInstalledKey = Get-Item HKLM:\SOFTWARE\Ericsson\Erlang\ErlSrv\1.1\RabbitMQ -ErrorAction SilentlyContinue   
        if ( $rabInstalledKey -ne $null)
        {
            Remove-Item HKLM:\SOFTWARE\Ericsson\Erlang\ErlSrv\1.1\RabbitMQ -ErrorAction SilentlyContinue   
        }
        Write-Host "Installing RabbitMQ"
        $ags = "/S /SD /D=$drive" + ":\Program Files\RabbitMQ Server"
        Write-Host "$destFile  $ags"
        $timeouted = $null 
        $proc = Start-Process  $destFile  $ags  -PassThru
        $proc | Wait-Process -Timeout 30 -ErrorAction SilentlyContinue -ErrorVariable timeouted
        if ($timeouted)
        {
            # terminate the process
            $proc | kill
    
            # update internal error counter
        }
        elseif ($proc.ExitCode -ne 0)
        {
            # update internal error counter
            Write-Host $proc.ExitCode
        }
        ##Wait-Process -Timeout 300 -Name $installProc

        # & $destFile | Out-Null
    }
    
    Write-Host "Erlang home $env:ERLANG_HOME"
    if (-not (Test-Path $binPath)) {
        Write-Host  "Couldn't find RabbitMQ installation folder $binPath"
        return
    }
    Write-Host "Installing plugins"
    .$binPath\rabbitmq-plugins.bat enable rabbitmq_management


    Write-Host "Waiting for node to warm up"
    Start-Sleep -Seconds 25
    Write-Host "Setting up main user"
    .$binPath\rabbitmqctl.bat add_user mainuser mainuser 
    .$binPath\rabbitmqctl.bat set_user_tags mainuser administrator
    .$binPath\rabbitmqctl.bat set_permissions -p / mainuser ".*" ".*" ".*"
}