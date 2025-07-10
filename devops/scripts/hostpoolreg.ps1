Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [System.String]$token
)

$agentService = Get-Service -Name 'RDAgentBootLoader' -ErrorAction SilentlyContinue
$infraService = Get-Service -Name 'RDAgent' -ErrorAction SilentlyContinue

if ($agentService.Status -eq 'Running' -and $infraService.Status -eq 'Running') {
    Write-Host "AVD Agent already installed... exiting now..."
    exit 0
} else {
    Write-Host "AVD Agent is not installed... installing now..."
}

if (!(Test-Path "C:\Temp\")) {
    New-Item -Path "C:\Temp\" -ItemType Directory
}

$urls = @{
    "C:\Temp\RWrmXv.msi" = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
    "C:\Temp\RWrxrH.msi" = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"
}

foreach ($file in $urls.Keys) {
    try {
        Write-Host "Loading: $($urls[$file])"
        Invoke-WebRequest -Uri $urls[$file] -OutFile $file -UseBasicParsing
        if (!(Test-Path $file)) {
            Write-Host "Error: Files couldn't load: $file"
            exit 1
        }
    } catch {
        Write-Host "Download failed for $($urls[$file])"
        exit 1
    }
}

Start-Sleep -Seconds 30

foreach ($file in $urls.Keys) {
    Unblock-File -Path "$file"
}

Write-Host "Starting installation of AVD Agent..."
msiexec /i "C:\Temp\RWrmXv.msi" /quiet REGISTRATIONTOKEN=$token
Start-Sleep -Seconds 180

Write-Host "Starting installation of AVD Boot Loader..."
msiexec /i "C:\Temp\RWrxrH.msi" /quiet
Start-Sleep -Seconds 120

Write-Host "Installation successful!"
