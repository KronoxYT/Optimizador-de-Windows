# Restaurar ajustes comunes a valores por defecto recomendados
# Ejecutar como Administrador

$ErrorActionPreference = 'Stop'

function Ensure-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent())
        .IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warning "Este script requiere permisos de Administrador. Re-lanzando..."
        Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"") -Verb RunAs
        exit
    }
}

function Set-RegistryValue {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][ValidateSet('String','DWord','QWord')][string]$Type,
        [Parameter(Mandatory=$true)]$Value
    )
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
}

function Remove-RegistryValue {
    param([string]$Path,[string]$Name)
    if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue }
}

function Set-ServiceStartupType {
    param([string]$ServiceName, [string]$StartupType)
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($svc) { Set-Service -Name $ServiceName -StartupType $StartupType }
}

Ensure-Admin
Write-Host "Restaurando valores por defecto recomendados..."

# Visual FX: permitir que Windows decida
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Type DWord -Value 0
Set-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Type String -Value '400'
Set-RegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'DragFullWindows' -Type String -Value '1'
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Type DWord -Value 1

# Quitar políticas de apps en segundo plano
Remove-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\AppPrivacy' -Name 'LetAppsRunInBackground'

# Edge Startup Boost: quitar política (resta al estado por defecto del sistema)
Remove-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Edge' -Name 'StartupBoostEnabled'

# Privacidad: volver a telemetría estándar (3=Full en algunas ediciones; usa 1=Basic si prefieres)
Set-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Type DWord -Value 3
Remove-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo' -Name 'Disabled'
Remove-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana'

# Gaming: desactivar HAGS
Remove-RegistryValue -Path 'HKLM:\System\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode'
# Restaurar Game Bar
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'ShowStartupPanel' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'UseGameBar' -Type DWord -Value 1
Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Type DWord -Value 1

# Servicios: restaurar tipos comunes
Set-ServiceStartupType -ServiceName 'SysMain' -StartupType 'Automatic'
Set-ServiceStartupType -ServiceName 'WSearch' -StartupType 'Automatic'
Set-ServiceStartupType -ServiceName 'XblGameSave' -StartupType 'Manual'
Set-ServiceStartupType -ServiceName 'XboxGipSvc' -StartupType 'Manual'
Set-ServiceStartupType -ServiceName 'XboxNetApiSvc' -StartupType 'Manual'

# NTFS LastAccess: restaurar al valor por defecto del sistema
try { fsutil behavior set disablelastaccess 2 | Out-Null } catch { Write-Warning "No se pudo restaurar NTFS LastAccess: $($_.Exception.Message)" }

# OneDrive: quitar política de bloqueo
Remove-RegistryValue -Path 'HKLM:\Software\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC'

Write-Host "Hecho. Reinicia o cierra sesión para aplicar algunos cambios."