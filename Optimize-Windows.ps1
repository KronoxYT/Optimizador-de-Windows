param(
    [switch]$DryRun,
    [ValidateSet('Seguro','Privacidad','Gaming','Agresivo','GamingAgresivo')][string]$AutoProfile,
    [string]$AutoDisableOneDrive,
    [string]$AutoKeepGameBar
)

# Optimizador de Windows 10/11
# Perfiles: Seguro, Privacidad, Gaming, Agresivo
# Ejecutar como Administrador. Usa -DryRun para ver cambios sin aplicarlos.

$ErrorActionPreference = 'Stop'
$global:LogPath = Join-Path -Path (Get-Location) -ChildPath "optimizer.log"

function Write-Log($msg) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] $msg"
    Write-Host $line
    Add-Content -Path $global:LogPath -Value $line
}

function Ensure-Admin {
    if ($DryRun) {
        Write-Log "Modo Dry-Run: se omite elevación de administrador."
        return
    }
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warning "Este script requiere permisos de Administrador. Re-lanzando..."
        $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"")
        if ($DryRun) { $args += '-DryRun' }
        Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Verb RunAs
        exit
    }
}

function New-SystemRestorePoint {
    try {
        Write-Log "Intentando crear punto de restauración del sistema..."
        Checkpoint-Computer -Description 'Windows Optimizer pre-change' -RestorePointType 'Modify_Settings'
        Write-Log "Punto de restauración creado (si la Protección del Sistema está habilitada)."
    } catch {
        Write-Warning "No se pudo crear un punto de restauración. Asegúrate de tener activada la Protección del Sistema. Detalle: $($_.Exception.Message)"
    }
}

function Set-RegistryValue {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][ValidateSet('String','DWord','QWord')][string]$Type,
        [Parameter(Mandatory=$true)]$Value
    )
    if ($DryRun) {
        Write-Log "[DRY-RUN] RegSet $Path :: $Name=$Value ($Type)"
        return
    }
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
        Write-Log "RegSet OK: $Path :: $Name=$Value ($Type)"
    } catch {
        Write-Warning "Error estableciendo registro $Path :: $Name -> $Value. Detalle: $($_.Exception.Message)"
    }
}

function Remove-RegistryValue {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name
    )
    if ($DryRun) {
        Write-Log "[DRY-RUN] RegDel $Path :: $Name"
        return
    }
    try {
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            Write-Log "RegDel OK: $Path :: $Name"
        }
    } catch {
        Write-Warning "Error eliminando registro $Path :: $Name. Detalle: $($_.Exception.Message)"
    }
}

function Stop-AndDisableService {
    param([string]$ServiceName)
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Log "Servicio $ServiceName no encontrado, omitiendo."
        return
    }
    if ($DryRun) {
        Write-Log "[DRY-RUN] Stop/Disable $ServiceName"
        return
    }
    try {
        if ($svc.Status -ne 'Stopped') {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        }
        Set-Service -Name $ServiceName -StartupType Disabled
        Write-Log "Servicio $ServiceName deshabilitado."
    } catch {
        Write-Warning "Error deshabilitando ${ServiceName}: $($_.Exception.Message)"
    }
}

function Set-ServiceStartupType {
    param([string]$ServiceName, [string]$StartupType)
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Log "Servicio $ServiceName no encontrado, omitiendo."
        return
    }
    if ($DryRun) {
        Write-Log "[DRY-RUN] Set-Service $ServiceName StartupType=$StartupType"
        return
    }
    try {
        Set-Service -Name $ServiceName -StartupType $StartupType
        Write-Log "Servicio $ServiceName establecido en $StartupType."
    } catch {
        Write-Warning "Error estableciendo ${ServiceName}: $($_.Exception.Message)"
    }
}

function Set-HighPerformancePowerPlan {
    Write-Log "Configurando plan de energía Alto rendimiento..."
    if ($DryRun) { Write-Log "[DRY-RUN] powercfg -SETACTIVE SCHEME_MIN"; return }
    try {
        powercfg -SETACTIVE SCHEME_MIN
        Write-Log "Plan de energía Alto rendimiento activado."
    } catch {
        Write-Warning "No se pudo activar Alto rendimiento: $($_.Exception.Message)"
    }
}

function Try-EnableUltimatePerformancePlan {
    Write-Log "Intentando habilitar 'Ultimate Performance'..."
    if ($DryRun) { Write-Log "[DRY-RUN] powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61"; return }
    try {
        $guid = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) -replace '{|}'
        if ($guid) {
            powercfg -SETACTIVE $guid
            Write-Log "Ultimate Performance activado ($guid)."
        } else {
            Write-Log "Ultimate Performance no disponible en esta edición/CPU."
        }
    } catch {
        Write-Log "Ultimate Performance no disponible: $($_.Exception.Message)"
    }
}

function Apply-VisualPerformanceTweaks {
    Write-Log "Aplicando ajustes visuales para mejor rendimiento..."
    Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Type DWord -Value 2
    Set-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Type String -Value '0'
    Set-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'DragFullWindows' -Type String -Value '0'
    Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Type DWord -Value 0
}

function Apply-StorageSense {
    Write-Log "Activando Storage Sense básico..."
    Set-RegistryValue -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' -Name '01' -Type DWord -Value 1
}

function Reduce-TipsAndSuggestions {
    Write-Log "Desactivando sugerencias y contenido recomendado..."
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    Set-RegistryValue -Path $path -Name 'SubscribedContent-338387Enabled' -Type DWord -Value 0
    Set-RegistryValue -Path $path -Name 'SubscribedContent-353694Enabled' -Type DWord -Value 0
    Set-RegistryValue -Path $path -Name 'SubscribedContent-310093Enabled' -Type DWord -Value 0
}

function Limit-BackgroundApps {
    Write-Log "Limitando apps en segundo plano por políticas..."
    Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\AppPrivacy' -Name 'LetAppsRunInBackground' -Type DWord -Value 2
}

function Disable-EdgeStartupBoost {
    Write-Log "Desactivando Edge Startup Boost..."
    Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Edge' -Name 'StartupBoostEnabled' -Type DWord -Value 0
}

function Apply-PrivacyTweaks {
    Write-Log "Aplicando ajustes de privacidad..."
    Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Type DWord -Value 0
    Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo' -Name 'Disabled' -Type DWord -Value 1
    Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -Type DWord -Value 0
}

function Apply-GamingTweaks {
    param([bool]$KeepGameBar = $false)
    Write-Log "Aplicando ajustes para Gaming..."
    Set-HighPerformancePowerPlan
    Try-EnableUltimatePerformancePlan
    # Hardware-Accelerated GPU Scheduling (requiere reinicio y soporte GPU)
    Set-RegistryValue -Path 'HKLM:\System\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -Type DWord -Value 2
    if (-not $KeepGameBar) {
        # Desactivar Game Bar
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'ShowStartupPanel' -Type DWord -Value 0
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'UseGameBar' -Type DWord -Value 0
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Type DWord -Value 0
    } else {
        Write-Log "Mantener Game Bar por preferencia del usuario."
    }
}

function Apply-AggressiveTweaks {
    param([bool]$DisableOneDrive = $false)
    Write-Log "Aplicando optimizaciones agresivas (usa con precaución)..."
    # Servicios
    Stop-AndDisableService -ServiceName 'SysMain'
    Stop-AndDisableService -ServiceName 'XblGameSave'
    Stop-AndDisableService -ServiceName 'XboxGipSvc'
    Stop-AndDisableService -ServiceName 'XboxNetApiSvc'
    # Opcional: deshabilitar Windows Search (puede afectar búsquedas/Outlook)
    Stop-AndDisableService -ServiceName 'WSearch'
    # Ajuste NTFS: desactivar actualización de último acceso para mejorar rendimiento de disco
    if ($DryRun) { Write-Log "[DRY-RUN] fsutil behavior set disablelastaccess 1" }
    else {
        try { fsutil behavior set disablelastaccess 1 | Out-Null; Write-Log "NTFS LastAccess deshabilitado." } catch { Write-Warning "No se pudo ajustar LastAccess: $($_.Exception.Message)" }
    }
    # HAGS: desactivar por preferencia agresiva
    Set-RegistryValue -Path 'HKLM:\System\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -Type DWord -Value 1
    # OneDrive (solo si el usuario acepta)
    if ($DisableOneDrive) {
        Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC' -Type DWord -Value 1
        Remove-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDrive'
        Write-Log "OneDrive bloqueado por políticas y removido del arranque del usuario actual."
    } else {
        Write-Log "Se mantiene OneDrive (sin bloquear la sincronización)."
    }
}

function Apply-SafeProfile {
    Write-Log "Aplicando perfil SEGURO..."
    Set-HighPerformancePowerPlan
    Try-EnableUltimatePerformancePlan
    Apply-VisualPerformanceTweaks
    Apply-StorageSense
    Reduce-TipsAndSuggestions
    Limit-BackgroundApps
    Disable-EdgeStartupBoost
}

function Apply-PrivacyProfile {
    Write-Log "Aplicando perfil PRIVACIDAD..."
    Apply-PrivacyTweaks
    Reduce-TipsAndSuggestions
    Limit-BackgroundApps
}

function Apply-GamingProfile {
    Write-Log "Aplicando perfil GAMING..."
    Ask-AggressiveGamingChoices
    Apply-GamingTweaks -KeepGameBar:$script:KeepGameBarChoice
}

function Apply-AggressiveProfile {
    Write-Log "Aplicando perfil AGRESIVO..."
    Ask-AggressiveGamingChoices
    Apply-AggressiveTweaks -DisableOneDrive:$script:DisableOneDriveChoice
}

function Show-Menu {
    Write-Host ""; Write-Host "============================="
    Write-Host "   Optimizador de Windows 10/11"
    Write-Host "============================="
    Write-Host "1) Perfil SEGURO (recomendado)"
    Write-Host "2) Perfil PRIVACIDAD"
    Write-Host "3) Perfil GAMING"
    Write-Host "4) Perfil AGRESIVO (precaución)"
    Write-Host "5) Perfil GAMING + AGRESIVO (tu preferencia)"
    Write-Host "6) Salir"
    Write-Host ""; Write-Host "Elige una opción (1-6): " -NoNewline
}

# Main
Ensure-Admin
Write-Log "Inicio del Optimizador (DryRun=$DryRun)"
New-SystemRestorePoint

# MODO NO INTERACTIVO: usar parámetros para aplicar perfil directo
if ($PSBoundParameters.ContainsKey('AutoProfile') -and $AutoProfile) {
    # Funciones auxiliares para convertir string->bool
    function To-Bool($val, $default) {
        if (-not $PSBoundParameters.ContainsKey($val)) { return $default }
        $raw = (Get-Variable -Name $val -ValueOnly)
        if ($null -eq $raw) { return $default }
        $s = "$raw".ToLower()
        return ($s -match '^(1|true|t|y|yes|s|si)$')
    }

    # Establecer decisiones por defecto para perfiles agresivos
    if ($AutoProfile -match 'Agresivo') {
        $script:DisableOneDriveChoice = To-Bool 'AutoDisableOneDrive' $true
        $script:KeepGameBarChoice    = To-Bool 'AutoKeepGameBar' $false
        $script:AskedChoices = $true
    }
    switch ($AutoProfile) {
        'Seguro' { Apply-SafeProfile }
        'Privacidad' { Apply-PrivacyProfile }
        'Gaming' {
            $script:KeepGameBarChoice = To-Bool 'AutoKeepGameBar' $false
            Apply-GamingTweaks -KeepGameBar:$script:KeepGameBarChoice
        }
        'Agresivo' {
            $script:DisableOneDriveChoice = To-Bool 'AutoDisableOneDrive' $true
            Apply-AggressiveTweaks -DisableOneDrive:$script:DisableOneDriveChoice
        }
        'GamingAgresivo' {
            $script:DisableOneDriveChoice = To-Bool 'AutoDisableOneDrive' $true
            $script:KeepGameBarChoice    = To-Bool 'AutoKeepGameBar' $false
            Apply-GamingTweaks -KeepGameBar:$script:KeepGameBarChoice
            Apply-AggressiveTweaks -DisableOneDrive:$script:DisableOneDriveChoice
        }
    }
    Write-Host "\nOperación finalizada (no interactivo). Revisa el archivo de log: $global:LogPath"
    Write-Host "Algunos cambios requieren reiniciar o cerrar sesión para aplicarse."
    return
}

while ($true) {
    Show-Menu
    $choice = Read-Host
    switch ($choice) {
        '1' { Apply-SafeProfile; break }
        '2' { Apply-PrivacyProfile; break }
        '3' { Apply-GamingProfile; break }
        '4' { Apply-AggressiveProfile; break }
        '5' { Apply-GamingAggressiveProfile; break }
        '6' { Write-Log 'Salida solicitada.'; break }
        default { Write-Host "Opción inválida." }
    }
}

Write-Host "\nOperación finalizada. Revisa el archivo de log: $global:LogPath"
Write-Host "Algunos cambios requieren reiniciar o cerrar sesión para aplicarse."

# NUEVOS: funciones de ayuda y perfil combinado
function Ask-YesNo($message, $default = 'N') {
    $prompt = "$message [S/N] (por defecto: $default): "
    $in = Read-Host -Prompt $prompt
    if ([string]::IsNullOrWhiteSpace($in)) { $in = $default }
    $in = $in.ToUpper()
    return ($in -eq 'S' -or $in -eq 'Y')
}

function Set-NTFSLastAccess {
    param([bool]$Disable)
    if ($Disable) {
        if ($DryRun) { Write-Log "[DRY-RUN] fsutil behavior set disablelastaccess 1" }
        else {
            try { fsutil behavior set disablelastaccess 1 | Out-Null; Write-Log "NTFS LastAccess deshabilitado." } catch { Write-Warning "No se pudo ajustar LastAccess: $($_.Exception.Message)" }
        }
    } else {
        if ($DryRun) { Write-Log "[DRY-RUN] fsutil behavior set disablelastaccess 2" }
        else {
            try { fsutil behavior set disablelastaccess 2 | Out-Null; Write-Log "NTFS LastAccess restaurado a valor por defecto del sistema." } catch { Write-Warning "No se pudo restaurar LastAccess: $($_.Exception.Message)" }
        }
    }
}

$script:AskedChoices = $false
$script:DisableOneDriveChoice = $false
$script:KeepGameBarChoice = $false
function Ask-AggressiveGamingChoices {
    if (-not $script:AskedChoices) {
        $script:DisableOneDriveChoice = Ask-YesNo "¿Deshabilitar OneDrive y bloquear la sincronización para máximo rendimiento?" 'S'
        $script:KeepGameBarChoice = Ask-YesNo "¿Mantener Game Bar y capturas en segundo plano?" 'N'
        $script:AskedChoices = $true
    }
}

function Apply-GamingAggressiveProfile {
    Write-Log "Aplicando perfil combinado GAMING + AGRESIVO..."
    Ask-AggressiveGamingChoices
    Apply-GamingTweaks -KeepGameBar:$script:KeepGameBarChoice
    Apply-AggressiveTweaks -DisableOneDrive:$script:DisableOneDriveChoice
}