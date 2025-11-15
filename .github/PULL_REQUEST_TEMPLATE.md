# Descripción
Explica qué cambia este PR y por qué es necesario.

## Tipo de cambio
- [ ] feat (nueva funcionalidad)
- [ ] fix (corrección)
- [ ] docs (documentación)
- [ ] refactor (cambio interno)
- [ ] perf (rendimiento)
- [ ] test (pruebas)
- [ ] chore (tareas)

## Checklist
- [ ] Probado en `-DryRun` sin errores.
- [ ] Probado en aplicación real (si el cambio afecta al sistema).
- [ ] Documentado en `README.md` (si procede).
- [ ] Añadida reversión en `Restore-Defaults.ps1` (si aplica).
- [ ] Cumple el estilo de código y uso de `Write-Log`.
- [ ] Commits con Convencional Commits.

## Comandos de prueba
Dry-Run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "c:\\Users\\Tomas\\Documents\\Proyecto\\Optimizador de Windows\\Optimize-Windows.ps1" -AutoProfile <Perfil> [parámetros] -DryRun
```
Aplicación real (Administrador):
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "c:\\Users\\Tomas\\Documents\\Proyecto\\Optimizador de Windows\\Optimize-Windows.ps1" -AutoProfile <Perfil> [parámetros]
```

## Riesgos / Consideraciones
Describe impactos y cómo revertir.

## Referencias
Issues relacionados, discusiones o documentación externa.