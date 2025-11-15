# Optimizador de Windows 10/11 (PowerShell)

Este proyecto proporciona un script de PowerShell para optimizar Windows 10/11 con distintos perfiles (Seguro, Privacidad, Gaming y Agresivo). Incluye un modo Dry-Run para ver qué cambios se aplicarían sin modificar el sistema y un script de restauración para revertir ajustes comunes.

IMPORTANTE
- Ejecuta el script como Administrador.
- Usa primero el modo Dry-Run para revisar los cambios propuestos.
- Crea un punto de restauración del sistema antes de aplicar cambios (el script intentará hacerlo si la Protección del Sistema está habilitada).
- Algunos cambios requieren reiniciar o cerrar sesión para surtir efecto.
- Las optimizaciones agresivas pueden deshabilitar servicios y funcionalidades; úsalas solo si entiendes el impacto.

Requisitos previos
- Windows 10 u 11.
- PowerShell 5+.
- Permitir la ejecución de scripts (solo la primera vez):
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

Cómo usar
1) Abre PowerShell como Administrador.
2) Ve a la carpeta del proyecto:
   cd "c:\Users\Tomas\Documents\Proyecto\Optimizador de Windows"
3) Revisa en Dry-Run (no hace cambios):
   .\Optimize-Windows.ps1 -DryRun
4) Aplica cambios (elige el perfil desde el menú):
   .\Optimize-Windows.ps1
5) Reinicia el equipo si se indica.

Perfiles incluidos
- Seguro (recomendado):
  - Plan de energía Alto rendimiento / Ultimate Performance si disponible.
  - Desactiva animaciones visuales y acelera la interfaz (ajustes no destructivos).
  - Activa Storage Sense básico.
  - Reduce sugerencias y tips del sistema.
  - Limita apps en segundo plano mediante políticas.
  - Desactiva Startup Boost de Edge.

- Privacidad:
  - Reduce al mínimo la telemetría (AllowTelemetry=0 cuando es posible).
  - Desactiva el ID de publicidad y algunas experiencias sugeridas.
  - Desactiva Cortana por políticas.

- Gaming:
  - Habilita el Plan de energía de alto rendimiento.
  - Activa Hardware-Accelerated GPU Scheduling (si soportado; requiere reinicio). En modo Agresivo se desactiva por defecto.
  - Pregunta si quieres mantener Game Bar y capturas en segundo plano.

- Agresivo (usar con precaución):
  - Deshabilita servicios no esenciales para rendimiento (SysMain, Xbox, Windows Search).
  - Limita aplicaciones en segundo plano por políticas.
  - Optimiza NTFS deshabilitando la actualización de LastAccess.
  - Desactiva Hardware-Accelerated GPU Scheduling (HAGS).
  - Pregunta si quieres deshabilitar OneDrive y bloquear la sincronización por políticas.

- Gaming + Agresivo (combinado):
  - Aplica Gaming y Agresivo juntos.
  - HAGS se desactiva por defecto.
  - Te preguntará por OneDrive (bloquear o no) y por Game Bar (mantener o desactivar).

Restaurar cambios
- Para revertir a valores por defecto recomendados, usa:
  .\Restore-Defaults.ps1
- Nota: No todos los ajustes tienen un valor universal de "fábrica"; este script restaura configuraciones comunes a estados recomendados y quita políticas forzadas.

Notas y consideraciones
- En ediciones Home, algunas políticas pueden no aplicarse.
- La creación de puntos de restauración depende de que la Protección del Sistema esté activa en la unidad del sistema.
- Cambios en el Registro y servicios se aplican bajo tu responsabilidad.

Soporte
Si quieres personalizar el perfil (por ejemplo, mantener Game Bar pero activar GPU Scheduling), indícalo y ajustamos el script a tus preferencias.
 
## Ejemplos rápidos

- Dry-Run del perfil "Gaming + Agresivo" (full agresivo):

```powershell
# No aplica cambios, solo muestra qué se haría
powershell -ExecutionPolicy Bypass -File .\Optimize-Windows.ps1 -DryRun -AutoProfile GamingAgresivo -AutoDisableOneDrive $true -AutoKeepGameBar $false
```

- Aplicación directa (no interactiva) del perfil "Gaming + Agresivo":

```powershell
# Aplica cambios con decisiones ya definidas para máximo rendimiento
powershell -ExecutionPolicy Bypass -File .\Optimize-Windows.ps1 -AutoProfile GamingAgresivo -AutoDisableOneDrive $true -AutoKeepGameBar $false
```

Notas:
- -AutoDisableOneDrive $true bloquea la sincronización y elimina OneDrive del arranque del usuario actual.
- -AutoKeepGameBar $false desactiva Game Bar y la captura en segundo plano para evitar consumo.
- En perfiles agresivos, si no especificas estos parámetros, el script usará por defecto: deshabilitar OneDrive y desactivar Game Bar.