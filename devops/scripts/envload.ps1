$envFile = "$env:BUILD_SOURCESDIRECTORY/devops/config/config.json"
$envName = $env:DEPLOY_ENVIRONMENT

$json = Get-Content $envFile | ConvertFrom-Json

$merged = @{}
$json.default.PSObject.Properties | ForEach-Object { $merged[$_.Name] = $_.Value }
$json.environment.$envName.PSObject.Properties | ForEach-Object { $merged[$_.Name] = $_.Value }

foreach ($pair in $merged.GetEnumerator()) {
    $name = $pair.Key -replace '[^a-zA-Z0-9]', '_'
    $isSecret = ($name -ieq 'adminPassword')
    $flag = if ($isSecret) { 'isSecret=true;' } else { '' }
    Write-Host "##vso[task.setvariable variable=$name;${flag}isOutput=true]$($pair.Value)"
}
