[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, HelpMessage = "U ssssssss s")]
    [Alias("MachineName")]
    [string]$drive ,
    [string]$rmqVer = "3.7.18",
    [string]$erLang = "21.3"   
)
cls

$dataFolder = "$($drive):\rabbitmq"
. (Join-Path (pwd) common.ps1) 
Write-Host $dataFolder $rmqVer $erLang

New-Item $dataFolder -ItemType Directory -Force
 
 
Install
 
 