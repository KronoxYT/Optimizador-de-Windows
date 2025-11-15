# Guía de Contribución

Gracias por tu interés en contribuir al Optimizador de Windows. Esta guía explica cómo preparar tu entorno, los estándares de código, y el flujo para proponer mejoras.

## Antes de Empezar
- Plataforma: Windows 10/11.
- PowerShell: usar PowerShell 5.1 o PowerShell 7+.
- Permisos: algunas acciones requieren ejecución como Administrador. Para pruebas, puedes usar el modo `-DryRun`.

## Ejecución Rápida
- Dry-Run (simulación, sin cambios):
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File "c:\Users\Tomas\Documents\Proyecto\Optimizador de Windows\Optimize-Windows.ps1" -AutoProfile GamingAgresivo -AutoDisableOneDrive true -AutoKeepGameBar false -DryRun
  ```
- Aplicación real (con elevación):
  ```powershell
  # Abre PowerShell como Administrador
  powershell -NoProfile -ExecutionPolicy Bypass -File "c:\Users\Tomas\Documents\Proyecto\Optimizador de Windows\Optimize-Windows.ps1" -AutoProfile GamingAgresivo -AutoDisableOneDrive true -AutoKeepGameBar false
  ```
- Revertir cambios:
  ```powershell
  # Abre PowerShell como Administrador
  powershell -NoProfile -ExecutionPolicy Bypass -File "c:\Users\Tomas\Documents\Proyecto\Optimizador de Windows\Restore-Defaults.ps1"
  ```

## Estándares de Código (PowerShell)
- Mantén funciones pequeñas y descriptivas.
- Usa `Write-Log` para registrar todas las acciones (incluye soporte de `-DryRun`).
- Evita interpolaciones problemáticas en cadenas: usa `${Variable}` cuando corresponda.
- Parametriza comportamientos para permitir ejecución no interactiva:
  - `-AutoProfile` (Seguro, Privacidad, Gaming, Agresivo, GamingAgresivo)
  - `-AutoDisableOneDrive` (true/false como cadena; el script convierte internamente)
  - `-AutoKeepGameBar` (true/false como cadena)
- No mezcles cambios funcionales con cambios de formato.
- Comentarios breves y útiles; documenta decisiones de diseño.

## Convenciones de Commits
Usa Convencional Commits:
- `feat:` nueva funcionalidad.
- `fix:` corrección de error.
- `docs:` documentación (README, CONTRIBUTING, etc.).
- `refactor:` refactor sin cambio de comportamiento.
- `perf:` mejoras de rendimiento.
- `test:` pruebas o validaciones.
- `chore:` tareas generales.

Ejemplo: `feat(profile): agregar perfil combinado Gaming + Agresivo con parámetros automáticos`

## Flujo de Trabajo para PRs
1. Crea una rama descriptiva: `feature/<breve-descripcion>` o `fix/<breve-descripcion>`.
2. Asegúrate de que tus cambios:
   - Pasan las pruebas de Dry-Run (ejecución sin errores).
   - Documentan el comportamiento en `README.md` si aplica.
3. Abre Pull Request con:
   - Descripción clara del cambio.
   - Comandos de prueba (Dry-Run y aplicación real si corresponde).
   - Riesgos y cómo revertirlos.
4. Un mantenedor revisará tu PR. Puede solicitar cambios.

## Pruebas y Validación
- Siempre prueba primero en `-DryRun`. Verifica `optimizer.log`.
- Si tu cambio afecta servicios del sistema, valida con ejecución real en entorno de pruebas.
- Asegúrate de que `Restore-Defaults.ps1` puede revertir tu cambio (añade la reversión si falta).

## Seguridad y Riesgos
- El perfil `Agresivo` puede desactivar componentes como Windows Search, HAGS, OneDrive y servicios Xbox. Documenta claramente el impacto.
- Evita cambios destructivos sin una reversión correspondiente.

## Reportar Problemas
- Usa las plantillas de Issues (bug/feature) cuando estén disponibles.
- Incluye versión de Windows, versión de PowerShell y el log `optimizer.log` relevante.

## Agradecimientos
Gracias por ayudar a mejorar este proyecto. Tu contribución es muy valorada.