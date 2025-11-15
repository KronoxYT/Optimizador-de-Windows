---
name: Solicitud de mejora
about: Propón una nueva funcionalidad o ajuste
title: "[FEATURE] Descripción breve"
labels: enhancement
assignees: ''
---

## Problema o necesidad
¿Cuál es la motivación o el problema que se busca resolver?

## Propuesta
Describe la solución propuesta. Si aplica, indica perfil(es) afectados (Seguro, Privacidad, Gaming, Agresivo, GamingAgresivo).

## Detalles técnicos
- Cambios en servicios, registro o políticas.
- Parámetros nuevos (ej.: `-AutoDisableOneDrive`, `-AutoKeepGameBar`).
- Impacto y riesgos.
- Reversión (qué añade a `Restore-Defaults.ps1`).

## Pruebas
Comandos de validación:
- Dry-Run:
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File "c:\\Users\\Tomas\\Documents\\Proyecto\\Optimizador de Windows\\Optimize-Windows.ps1" -AutoProfile <Perfil> [parámetros] -DryRun
  ```
- Aplicación real:
  ```powershell
  # Ejecutar como Administrador
  powershell -NoProfile -ExecutionPolicy Bypass -File "c:\\Users\\Tomas\\Documents\\Proyecto\\Optimizador de Windows\\Optimize-Windows.ps1" -AutoProfile <Perfil> [parámetros]
  ```

## Información adicional
Notas, referencias o ejemplos.