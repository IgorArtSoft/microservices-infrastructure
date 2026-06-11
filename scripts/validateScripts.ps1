$errors = @()

Get-ChildItem .\scripts -Recurse -Filter *.ps1 | ForEach-Object {
    Write-Host "Checking $($_.FullName)" -ForegroundColor Cyan

    $tokens = $null
    $parseErrors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        $_.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    ) | Out-Null

    if ($parseErrors.Count -gt 0) {
        $errors += $parseErrors
        $parseErrors | ForEach-Object {
            Write-Host "ERROR in $($_.Extent.File): line $($_.Extent.StartLineNumber) - $($_.Message)" -ForegroundColor Red
        }
    }
}

if ($errors.Count -eq 0) {
    Write-Host "All PowerShell scripts parsed successfully." -ForegroundColor Green
}
else {
    throw "PowerShell script syntax errors were found."
}