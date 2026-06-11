Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$InfrastructureRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path
$WorkspaceRoot = (Resolve-Path (Join-Path $InfrastructureRoot "..")).Path

$Services = @(
    @{
        Name = "order-service"
        Directory = Join-Path $WorkspaceRoot "order-service"
        Port = 8081
        Color = "Green"
    },
    @{
        Name = "payment-service"
        Directory = Join-Path $WorkspaceRoot "payment-service"
        Port = 8082
        Color = "Blue"
    }
    # Later:
    # @{
    #     Name = "customer-service"
    #     Directory = Join-Path $WorkspaceRoot "customer-service"
    #     Port = 8083
    #     Color = "Magenta"
    # }
)

function Get-ServiceRunCommand {
    param (
        [string]$ServiceDir
    )

    $mavenWrapper = Join-Path $ServiceDir "mvnw.cmd"

    if (Test-Path $mavenWrapper) {
        return ".\mvnw.cmd spring-boot:run -DskipTests"
    }

    return "mvn spring-boot:run -DskipTests"
}

function New-ServiceTabCommand {
    param (
        [string]$ServiceName,
        [string]$ServiceDir,
        [string]$ConsoleColor,
        [string]$RunCommand
    )

    return @"
`$Host.UI.RawUI.WindowTitle = '$ServiceName'
`$Host.UI.RawUI.ForegroundColor = '$ConsoleColor'
Clear-Host
Write-Host 'Starting $ServiceName...' -ForegroundColor $ConsoleColor
Write-Host 'Directory: $ServiceDir' -ForegroundColor $ConsoleColor
Write-Host ''
Set-Location -LiteralPath '$ServiceDir'
$RunCommand
"@
}

if (!(Get-Command wt.exe -ErrorAction SilentlyContinue)) {
    throw "Windows Terminal command 'wt.exe' was not found. Install or enable Windows Terminal."
}

if ([string]::IsNullOrWhiteSpace($env:WT_SESSION)) {
    throw "This script should be run from Windows Terminal. Open Windows Terminal from the infrastructure repository and run .\scripts\start-all.ps1 again."
}

foreach ($service in $Services) {
    if (!(Test-Path $service.Directory)) {
        throw "$($service.Name) folder was not found: $($service.Directory)"
    }
}

Write-Host "Starting microservices in new tabs of the current Windows Terminal window..." -ForegroundColor Cyan

$wtArgs = @("-w", "0")

$first = $true

foreach ($service in $Services) {
    $runCommand = Get-ServiceRunCommand -ServiceDir $service.Directory
    $tabCommand = New-ServiceTabCommand `
        -ServiceName $service.Name `
        -ServiceDir $service.Directory `
        -ConsoleColor $service.Color `
        -RunCommand $runCommand

    if (!$first) {
        $wtArgs += ";"
    }

    $wtArgs += @(
        "new-tab",
        "--title", $service.Name,
        "--suppressApplicationTitle",
        "powershell.exe",
        "-NoExit",
        "-Command", $tabCommand
    )

    $first = $false
}

& wt.exe @wtArgs

if ($LASTEXITCODE -ne 0) {
    throw "Failed to start service tabs in Windows Terminal."
}

Write-Host ""
Write-Host "Microservices are starting in new Windows Terminal tabs." -ForegroundColor Green

foreach ($service in $Services) {
    Write-Host "$($service.Name): http://localhost:$($service.Port)" -ForegroundColor $service.Color
}