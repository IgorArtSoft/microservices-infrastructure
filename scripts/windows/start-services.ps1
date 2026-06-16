Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Find-InfrastructureRoot {
    param (
        [string]$StartDirectory
    )

    $currentDirectory = Resolve-Path $StartDirectory

    while ($true) {
        $candidateComposeFile = Join-Path $currentDirectory "docker-compose.infra.yml"

        if (Test-Path $candidateComposeFile) {
            return $currentDirectory.Path
        }

        $parentDirectory = Split-Path -Parent $currentDirectory

        if ($parentDirectory -eq $currentDirectory.Path -or [string]::IsNullOrWhiteSpace($parentDirectory)) {
            throw "Could not find infrastructure repository root. Expected docker-compose.infra.yml above $StartDirectory."
        }

        $currentDirectory = Resolve-Path $parentDirectory
    }
}

$ScriptDir = $PSScriptRoot
$InfrastructureRoot = Find-InfrastructureRoot -StartDirectory $ScriptDir
$WorkspaceRoot = (Resolve-Path (Join-Path $InfrastructureRoot "..")).Path

Write-Host "Infrastructure root: $InfrastructureRoot" -ForegroundColor DarkGray
Write-Host "Workspace root:      $WorkspaceRoot" -ForegroundColor DarkGray

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

    $escapedServiceName = $ServiceName.Replace("'", "''")
    $escapedServiceDir = $ServiceDir.Replace("'", "''")

    return @"
`$ErrorActionPreference = 'Stop'
`$Host.UI.RawUI.WindowTitle = '$escapedServiceName'
`$Host.UI.RawUI.ForegroundColor = '$ConsoleColor'

Clear-Host

Write-Host 'Starting $escapedServiceName...' -ForegroundColor $ConsoleColor
Write-Host 'Directory: $escapedServiceDir' -ForegroundColor $ConsoleColor
Write-Host ''

Set-Location -LiteralPath '$escapedServiceDir'

$RunCommand

`$exitCode = if (`$null -eq `$LASTEXITCODE) { 0 } else { `$LASTEXITCODE }

Write-Host ''
Write-Host '$escapedServiceName stopped. Closing tab...' -ForegroundColor Yellow
Write-Host "Original service exit code: `$exitCode" -ForegroundColor DarkGray

exit 0
"@
}

foreach ($service in $Services) {
    if (!(Test-Path $service.Directory)) {
        throw "$($service.Name) folder was not found: $($service.Directory)"
    }
}

if (!(Get-Command wt.exe -ErrorAction SilentlyContinue)) {
    throw "Windows Terminal command 'wt.exe' was not found. Install or enable Windows Terminal."
}

Write-Host "Starting microservices in new Windows Terminal tabs..." -ForegroundColor Cyan

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
	    "--title",
	    $service.Name,
	    "--suppressApplicationTitle",
	    "powershell.exe",
	    "-NoProfile",
	    "-ExecutionPolicy",
	    "Bypass",
	    "-Command",
	    $tabCommand
	)

    $first = $false
}

& wt.exe @wtArgs

if ($LASTEXITCODE -ne 0) {
    throw "Failed to start microservice tabs in Windows Terminal."
}

Write-Host ""
Write-Host "Microservice startup commands were sent to Windows Terminal." -ForegroundColor Green

foreach ($service in $Services) {
    Write-Host "$($service.Name): http://localhost:$($service.Port)" -ForegroundColor $service.Color
}