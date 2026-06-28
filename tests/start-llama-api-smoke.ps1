$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$script = Join-Path $root 'start-llama-api.bat'

if (-not (Test-Path $script)) {
    throw "Launcher script not found: $script"
}

$output = & $script --dry-run 2>&1 | Out-String

if ($LASTEXITCODE -ne 0) {
    throw "Launcher dry-run failed with exit code $LASTEXITCODE.`n$output"
}

$requiredMarkers = @(
    'DRY_RUN_OK',
    'Resolved server:',
    'Resolved model:',
    'Resolved context:',
    'Resolved port:'
)

foreach ($marker in $requiredMarkers) {
    if ($output -notmatch [regex]::Escape($marker)) {
        throw "Missing expected output marker '$marker'.`n$output"
    }
}

if ($output -match '%SHOW_NAME%' -or $output -match '%SHOW_MODEL%') {
    throw "Dry-run leaked an unresolved menu variable.`n$output"
}

$interactiveInput = "1`r`n1`r`n1`r`n8081`r`nn`r`n"
$interactiveInputPath = Join-Path $env:TEMP 'llama-menu-n-input.txt'
[System.IO.File]::WriteAllText($interactiveInputPath, $interactiveInput, [System.Text.Encoding]::ASCII)
$interactiveOutput = cmd /c "`"$script`" --menu-test < `"$interactiveInputPath`"" 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    throw "Interactive menu failed with exit code $LASTEXITCODE.`n$interactiveOutput"
}

if ($interactiveOutput -match '%SHOW_NAME%' -or $interactiveOutput -match '%SHOW_MODEL%') {
    throw "Interactive menu leaked an unresolved menu variable.`n$interactiveOutput"
}

if ($interactiveOutput -match 'Invalid selection') {
    throw "Interactive menu rejected valid numeric input.`n$interactiveOutput"
}

if ($interactiveOutput -notmatch 'MENU_TEST_OK') {
    throw "Interactive menu did not reach command construction.`n$interactiveOutput"
}

$specInput = "1`r`n2`r`n1`r`n8082`r`ny`r`n"
$specInputPath = Join-Path $env:TEMP 'llama-menu-y-input.txt'
[System.IO.File]::WriteAllText($specInputPath, $specInput, [System.Text.Encoding]::ASCII)
$specOutput = cmd /c "`"$script`" --menu-test < `"$specInputPath`"" 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    throw "Speculative menu failed with exit code $LASTEXITCODE.`n$specOutput"
}

if ($specOutput -match 'Invalid selection') {
    throw "Speculative menu rejected valid input.`n$specOutput"
}

if ($specOutput -notmatch 'Speculative decoding: enabled') {
    throw "Speculative menu did not enable draft model.`n$specOutput"
}

if ($specOutput -notmatch '\-md "D:\\HEY\.Q\\models\\Qwen3-0\.6B-Q8_0\.gguf"') {
    throw "Speculative command did not include quoted draft model path.`n$specOutput"
}

if ($specOutput -match '--draft-max|--draft-min') {
    throw "Speculative command still uses removed draft flags.`n$specOutput"
}

if ($specOutput -notmatch '--spec-draft-n-max 16' -or $specOutput -notmatch '--spec-draft-n-min 1' -or $specOutput -notmatch '--spec-draft-p-min 0.8') {
    throw "Speculative command did not include current spec-draft flags.`n$specOutput"
}

$envInput = "1`r`n2`r`n1`r`n8098`r`nn`r`n"
$envInputPath = Join-Path $env:TEMP 'llama-env-n-input.txt'
[System.IO.File]::WriteAllText($envInputPath, $envInput, [System.Text.Encoding]::ASCII)
$envOutput = cmd /c "`"$script`" --env-test < `"$envInputPath`"" 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    throw "Environment test failed with exit code $LASTEXITCODE.`n$envOutput"
}

if ($envOutput -match '此时不应有|was unexpected at this time') {
    throw "Environment test hit a batch parser error.`n$envOutput"
}

if ($envOutput -notmatch 'ENV_TEST_OK') {
    throw "Environment test did not complete.`n$envOutput"
}

Write-Host 'Smoke test passed.'
