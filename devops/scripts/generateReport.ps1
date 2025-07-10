param (
    [string]$environment,
    [string]$resourceGroup,
    [string]$vmName,
    [string]$hostpoolName,
    [string]$applicationGroupName,
    [string]$displayName,
    [string]$location,
    [string]$vmsize,
    [string]$imagesku,
    [string]$imageoffer,
    [string]$imagepublisher,
    [string]$imageversion,
    [string]$shutdownTime,
    [string]$diskSizeGB,
    [string]$workspaceName,
    [string]$subscriptionId,
    [string]$adminusername
)

# --- Debug Values---
#$environment = 'dev'
#$resourceGroup = 'dev'
#$vmName = 'dev'
#$hostpoolName = 'dev'
#$applicationGroupName = 'dev'
#$displayName = 'dev'
#$location = 'dev'
#$vmsize = 'dev'
#$imagesku = 'dev'
#$imageoffer = 'dev'
#$imagepublisher = 'dev'
#$imageversion = 'dev'
#$shutdownTime = 'dev'
#$diskSizeGB = 'dev'
#$adminusername = 'dev'

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

# ===== Ressourcen Abfragen =====

try {
    $vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroup
    $tags = $vm.Tags
    $encryption = $vm.SecurityProfile.EncryptionAtHost
    $nicId = $vm.NetworkProfile.NetworkInterfaces[0].Id
    $nicName = ($nicId -split "/")[-1]
    $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup
    
    $hostpool = Get-AzWvdHostPool -Name $hostpoolName -ResourceGroupName $resourceGroup
    $HostPoolType = $hostpool.HostPoolType
    $StartVMOnConnect = $hostpool.StartVMOnConnect
    $LoadBalancerType = $hostpool.LoadBalancerType
    $poolLocation = $hostpool.Location

    $privateIp = $nic.IpConfigurations[0].PrivateIpAddress

    $publicIp = ""
    if ($nic.IpConfigurations[0].PublicIpAddress) {
        $publicIpId = $nic.IpConfigurations[0].PublicIpAddress.Id
        $publicIpName = ($publicIpId -split "/")[-1]
        $publicIpObj = Get-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $resourceGroup
        $publicIp = $publicIpObj.IpAddress
    } else {
        Write-Host "[Warning] Public IP not found."
    }
} catch {
    Write-Host "[Warning] Network details couldn't be loaded: $_"
    $nicName = "-"
    $privateIp = "-"
    $publicIp = "-"
}

$tag = foreach ($key in $tags.Keys) {
    "$key : $($tags[$key]) ¦"
}

# ===== Link zu Subcription generieren =====

switch ($environment) {
    'dev' { $tenantDomain = 'tieitf.onmicrosoft.com' }
    'int' { $tenantDomain = 'tstglobal.onmicrosoft.com' }
    'prd' { $tenantDomain = 'szhglobal.onmicrosoft.com' }
    default { Write-Host "Unknown environment! only dev, int, prd are allowed!" ; exit }
}

$linkToSubscription = "https://portal.azure.com/#@$tenantDomain/resource/subscriptions/$subscriptionId/overview"

# ===== Ausgabe =====

$asciiDev = @"
                         ,----..                                                                  
   ,---,     ,---,.     /   /   \    ,--,     ,--,              ,---,         ,---,.              
,`--.' |   ,'  .'  \   /   .     :   |'. \   / .`|            .'  .' `\     ,'  .' |        ,---. 
|   :  : ,---.' .' |  .   /   ;.  \  ; \ `\ /' / ;          ,---.'     \  ,---.'   |       /__./| 
:   |  ' |   |  |: | .   ;   /  ` ;  `. \  /  / .'          |   |  .`\  | |   |   .'  ,---.;  ; | 
|   :  | :   :  :  / ;   |  ; \ ; |   \  \/  / ./           :   : |  '  | :   :  |-, /___/ \  | | 
'   '  ; :   |    ;  |   :  | ; | '    \  \.'  /            |   ' '  ;  : :   |  ;/| \   ;  \ ' | 
|   |  | |   :     \ .   |  ' ' ' :     \  ;  ;             '   | ;  .  | |   :   .'  \   \  \: | 
'   :  ; |   |   . | '   ;  \; /  |    / \  \  \            |   | :  |  ' |   |  |-,   ;   \  ' . 
|   |  ' '   :  '; |  \   \  ',  /    ;  /\  \  \           '   : | /  ;  '   :  ;/|    \   \   ' 
'   :  | |   |  | ;    ;   :    /   ./__;  \  ;  \          |   | '` ,/   |   |    |     \   `  ; 
;   |.'  |   :   /      \   \ .'    |   : / \  \  ;         ;   :  .'     |   :   .'      :   \ | 
'---'    |   | ,'        `---`      ;   |/   \  ' |         |   ,.'       |   | ,'         '---'  
         `----'                     `---'     `--`          '---'         `----'                  
"@

$asciiInt = @"
                                                                                           ,----, 
                         ,----..                                              ,--.       ,/   .`| 
   ,---,     ,---,.     /   /   \    ,--,     ,--,             ,---,        ,--.'|     ,`   .'  : 
,`--.' |   ,'  .'  \   /   .     :   |'. \   / .`|          ,`--.' |    ,--,:  : |   ;    ;     / 
|   :  : ,---.' .' |  .   /   ;.  \  ; \ `\ /' / ;          |   :  : ,`--.'`|  ' : .'___,/    ,'  
:   |  ' |   |  |: | .   ;   /  ` ;  `. \  /  / .'          :   |  ' |   :  :  | | |    :     |   
|   :  | :   :  :  / ;   |  ; \ ; |   \  \/  / ./           |   :  | :   |   \ | : ;    |.';  ;   
'   '  ; :   |    ;  |   :  | ; | '    \  \.'  /            '   '  ; |   : '  '; | `----'  |  |   
|   |  | |   :     \ .   |  ' ' ' :     \  ;  ;             |   |  | '   ' ;.    ;     '   :  ;   
'   :  ; |   |   . | '   ;  \; /  |    / \  \  \            '   :  ; |   | | \   |     |   |  '   
|   |  ' '   :  '; |  \   \  ',  /    ;  /\  \  \           |   |  ' '   : |  ; .'     '   :  |   
'   :  | |   |  | ;    ;   :    /   ./__;  \  ;  \          '   :  | |   | '`--'       ;   |.'    
;   |.'  |   :   /      \   \ .'    |   : / \  \  ;         ;   |.'  '   : |           '---'      
'---'    |   | ,'        `---`      ;   |/   \  ' |         '---'    ;   |.'                      
         `----'                     `---'     `--`                   '---'                        
"@

$asciiPrd = @"
                         ,----..                            ,-.----.                              
   ,---,     ,---,.     /   /   \    ,--,     ,--,          \    /  \   ,-.----.        ,---,     
,`--.' |   ,'  .'  \   /   .     :   |'. \   / .`|          |   :    \  \    /  \     .'  .' `\   
|   :  : ,---.' .' |  .   /   ;.  \  ; \ `\ /' / ;          |   |  .\ : ;   :    \  ,---.'     \  
:   |  ' |   |  |: | .   ;   /  ` ;  `. \  /  / .'          .   :  |: | |   | .\ :  |   |  .`\  | 
|   :  | :   :  :  / ;   |  ; \ ; |   \  \/  / ./           |   |   \ : .   : |: |  :   : |  '  | 
'   '  ; :   |    ;  |   :  | ; | '    \  \.'  /            |   : .   / |   |  \ :  |   ' '  ;  : 
|   |  | |   :     \ .   |  ' ' ' :     \  ;  ;             ;   | |`-'  |   : .  /  '   | ;  .  | 
'   :  ; |   |   . | '   ;  \; /  |    / \  \  \            |   | ;     ;   | |  \  |   | :  |  ' 
|   |  ' '   :  '; |  \   \  ',  /    ;  /\  \  \           :   ' |     |   | ;\  \ '   : | /  ;  
'   :  | |   |  | ;    ;   :    /   ./__;  \  ;  \          :   : :     :   ' | \.' |   | '` ,/   
;   |.'  |   :   /      \   \ .'    |   : / \  \  ;         |   | :     :   : :-'   ;   :  .'     
'---'    |   | ,'        `---`      ;   |/   \  ' |         `---'.|     |   |.'     |   ,.'       
         `----'                     `---'     `--`            `---`     `---'       '---'         
"@

# Je nach Umgebung nur das passende ASCII-Art ausgeben:
switch ($environment) {
    'dev' { Write-Host $asciiDev }
    'int' { Write-Host $asciiInt }
    'prd' { Write-Host $asciiPrd }
    default { Write-Host "Unknown environment! only dev, int, prd are allowed!" }
}
                                                                                               

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
Write-Host "║                                             DEPLOYMENT OVERVIEW                                                ║"
Write-Host "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
Write-Host ""

Write-Host "╭─🔹 Environment ────────────────────────────────────────────────────────────────────────────────────────────────"
Write-Host "│ Timestamp             : $timestamp"
Write-Host "│ Environment           : $environment"
Write-Host "│ Location              : $location"
Write-Host "╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────"

Write-Host "╭─🔹 Virtual Machine ────────────────────────────────────────────────────────────────────────────────────────────"
Write-Host "│ VM Name               : $vmName"
Write-Host "│ EncryptionAtHost      : $encryption"
Write-Host "│ Admin Username        : $adminusername"
Write-Host "│ VM Size               : $vmsize"
Write-Host "│ Disk Size (GB)        : $diskSizeGB"
Write-Host "│ Tags                  : $tag"
Write-Host "╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────"

Write-Host "╭─🔹 Azure Virtual Desktop ───────────────────────────────────────────────────────────────────────────────────────"
Write-Host "│ Session Host Name     : $displayName"
Write-Host "│ HostPoolType          : $HostPoolType"
Write-Host "│ LoadBalancerType      : $LoadBalancerType"
Write-Host "│ StartVMOnConnect      : $StartVMOnConnect"
Write-Host "│ Location              : $poolLocation"
Write-Host "╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────"

Write-Host "╭─🔹 Image Configuration ─────────────────────────────────────────────────────────────────────────────────────────"
Write-Host "│ Publisher             : $imagepublisher"
Write-Host "│ Offer                 : $imageoffer"
Write-Host "│ SKU                   : $imagesku"
Write-Host "│ Version               : $imageversion"
Write-Host "╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────"

Write-Host "╭─🔹 Network Information ─────────────────────────────────────────────────────────────────────────────────────────"
Write-Host "│ NIC Name              : $nicName"
Write-Host "│ Private IP            : $privateIp"
Write-Host "│ Public IP             : $publicIp"
Write-Host "╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────"

Write-Host "╭─🔹 Extensions ──────────────────────────────────────────────────────────────────────────────────────────────────"
Write-Host "│ Shutdown Time         : $shutdownTime"
Write-Host "╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────"

Write-Host "╭─🔹 How to find Subscription? ───────────────────────────────────────────────────────────────────────────────────"
Write-Host "│ Click here: $linktoSubscription"
Write-Host "╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────"

Write-Host ""

Write-Host "[Automation] Shutdown VM now for saving costs..."
Stop-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Force -Confirm:$false
