# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Comando `arc-generate` para crear features desde CLI
- Soporte para configuración `.arcconfig.json` personalizada
- Swift Macros para boilerplate

---

## [1.0.0] - 2024-11-14

### Added
- 🎉 Lanzamiento inicial de ARCDevTools
- ✅ Configuraciones de SwiftLint y SwiftFormat
- ✅ Scripts shell para lint, format y git hooks
- ✅ Templates Stencil para Features (View, ViewModel, Service)
- ✅ Templates para Unit Tests
- ✅ Ejecutable `arc-setup` para configuración automática
- ✅ Generación automática de Makefile
- ✅ Pre-commit hooks para validación de código
- ✅ Soporte para Swift 6.0
- ✅ Documentación completa

### Features
- API pública a través de `ARCDevTools` enum
- Acceso a recursos vía `Bundle.module`
- Utilidades para copiar configuraciones
- Sistema de configuración extensible con `ARCConfiguration`

### Standards
- MVVM + Clean Architecture
- Swift 6 strict concurrency
- `@Observable` para ViewModels
- Protocol-oriented design

---

## [0.1.0] - 2024-11-14

### Added
- 🏗️ Estructura inicial del package
- 📦 Configuración básica de Swift Package Manager
- 📝 README inicial

---

[Unreleased]: https://github.com/arclabs-studio/ARCDevTools/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/arclabs-studio/ARCDevTools/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/arclabs-studio/ARCDevTools/releases/tag/v0.1.0
