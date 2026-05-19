Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceDir = "D:\Programming\webservicesjava25"

$orderServiceDir = Join-Path $workspaceDir "order-service"
$paymentServiceDir = Join-Path $workspaceDir "payment-service"

function Get-ServiceRunCommand {
    param (
        [string]$ServiceDir
    )

    $mavenWrapper = Join-Path $ServiceDir "mvnw.cmd"

    if (Test-Path $mavenWrapper) {
        return ".\mvnw.cmd spring-boot:run"
    }

    return "mvn spring-boot:run"
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
    throw "Windows Terminal command 'wt.exe' was not found."
}

if ([string]::IsNullOrWhiteSpace($env:WT_SESSION)) {
    throw "This PowerShell session is not running inside Windows Terminal. Open Windows Terminal, go to D:\Programming\webservicesjava25\kafka-local-dev, and run .\scripts\start-services.ps1 again."
}

if (!(Test-Path $orderServiceDir)) {
    throw "order-service folder not found: $orderServiceDir"
}

if (!(Test-Path $paymentServiceDir)) {
    throw "payment-service folder not found: $paymentServiceDir"
}

$orderRunCommand = Get-ServiceRunCommand -ServiceDir $orderServiceDir
$paymentRunCommand = Get-ServiceRunCommand -ServiceDir $paymentServiceDir

$orderTabCommand = New-ServiceTabCommand `
    -ServiceName "order-service" `
    -ServiceDir $orderServiceDir `
    -ConsoleColor "Green" `
    -RunCommand $orderRunCommand

$paymentTabCommand = New-ServiceTabCommand `
    -ServiceName "payment-service" `
    -ServiceDir $paymentServiceDir `
    -ConsoleColor "Blue" `
    -RunCommand $paymentRunCommand

Write-Host "Starting microservices in new tabs of the current Windows Terminal window..." -ForegroundColor Cyan

$wtArgs = @(
    "-w", "0",

    "new-tab",
    "--title", "order-service",
    "--suppressApplicationTitle",
    "powershell.exe",
    "-NoExit",
    "-Command",
    $orderTabCommand,

    ";",

    "new-tab",
    "--title", "payment-service",
    "--suppressApplicationTitle",
    "powershell.exe",
    "-NoExit",
    "-Command",
    $paymentTabCommand
)

& wt.exe @wtArgs

if ($LASTEXITCODE -ne 0) {
    throw "Failed to start service tabs in Windows Terminal."
}

Write-Host ""
Write-Host "Microservices are starting in new tabs of the current Windows Terminal window." -ForegroundColor Cyan
Write-Host "order-service:   http://localhost:8081" -ForegroundColor Green
Write-Host "payment-service: http://localhost:8082" -ForegroundColor Blue