# ARCDevTools

<div align="center">

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**Tooling, calidad y estándares centralizados para ARC Labs Studio**

</div>

---

## 🚀 Instalación

### 1. Añadir dependencia al proyecto

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/arclabs-studio/ARCDevTools", from: "1.0.0")
]
```

### 2. Instalar herramientas (una vez)

```bash
brew install swiftlint swiftformat
```

### 3. Configurar proyecto

```bash
# Desde la raíz de tu proyecto (FavRes, FavBook, etc.)
swift run arc-setup
```

Esto instalará:
- ✅ Configuraciones de SwiftLint y SwiftFormat
- ✅ Git hooks (pre-commit)
- ✅ Makefile con comandos útiles
- ✅ Templates para generación de código

---

## 📖 Uso

### Comandos disponibles

```bash
make help          # Ver todos los comandos
make lint          # Verificar código con SwiftLint
make format        # Ver cambios de formato (dry-run)
make fix           # Aplicar formato automáticamente
make setup         # Re-instalar configuración
```

### Generar features desde templates

```bash
# TODO: Próximamente
swift run arc-generate Feature UserProfile
```

---

## 🛠️ Configuración Personalizada

### Override de reglas SwiftLint

```yaml
# .swiftlint.yml (tu proyecto)
parent_config: .swiftlint.yml  # Hereda de ARCDevTools

# Añade reglas específicas de tu proyecto aquí
custom_rules:
  my_rule:
    name: "My Custom Rule"
    regex: "..."
```

### Deshabilitar pre-commit hooks temporalmente

```bash
git commit --no-verify -m "mensaje"
```

---

## 📐 Estándares ARC Labs

### Arquitectura
- **MVVM + Clean Architecture**
- ViewModels con `@Observable` (Swift 6)
- Protocolos para todas las dependencias
- Testing con mocks

### Estilo de Código
- **Indentación:** 4 espacios
- **Ancho máximo:** 120 caracteres
- **Imports:** Agrupados y ordenados
- **Self:** Explícito siempre

Ver documentación completa en `/Docs`

---

## 🤝 Contribuir

Este package es interno de ARC Labs, pero acepta mejoras:

1. Crea branch: `feature/mi-mejora`
2. Commit: `git commit -m "feat: descripción"`
3. PR a `main`

---

## 📄 Licencia

Propietario © 2024 ARC Labs Studio
