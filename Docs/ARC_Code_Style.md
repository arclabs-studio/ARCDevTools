# ARC Labs - Guía de Estilo de Código Swift

**Versión:** 1.0.0
**Última actualización:** 2024-11-14

---

## 🎯 Principios Fundamentales

### 1. Claridad sobre Brevedad
El código debe ser legible y auto-documentado. Preferir nombres descriptivos sobre comentarios.

```swift
// ❌ Evitar
let d = Date()
func calc(a: Int, b: Int) -> Int { a + b }

// ✅ Preferir
let currentDate = Date()
func calculateSum(first: Int, second: Int) -> Int {
    return first + second
}
```

### 2. Consistencia
Mantener el mismo estilo en todo el proyecto. ARCDevTools garantiza esto mediante SwiftLint y SwiftFormat.

### 3. Seguridad de Tipos
Aprovechar el sistema de tipos de Swift para prevenir errores en tiempo de compilación.

---

## 📝 Convenciones de Naming

### Variables y Constantes

```swift
// Camel Case para propiedades
let userName: String
var isLoading: Bool
let maxRetryCount: Int

// Constantes globales: UpperCamelCase
let DefaultTimeout: TimeInterval = 30
```

### Funciones y Métodos

```swift
// Camel case, verbos descriptivos
func fetchUserProfile() async throws -> UserProfile
func validate(email: String) -> Bool
func configure(with viewModel: ViewModel)
```

### Tipos (Classes, Structs, Enums)

```swift
// UpperCamelCase (PascalCase)
class UserProfileViewModel { }
struct APIConfiguration { }
enum NetworkError { }
protocol DataService { }
```

### Enums

```swift
// Casos en lowerCamelCase
enum ViewState {
    case idle
    case loading
    case loaded(Data)
    case error(String)
}
```

---

## 🏗️ Estructura de Archivos

### Orden de Declaraciones

```swift
import Foundation
import SwiftUI

// MARK: - Type Definition

struct FeatureView: View {

    // MARK: - Properties

    // 1. @State, @Binding, etc.
    @State private var viewModel = ViewModel()

    // 2. Propiedades privadas
    private let configuration: Config

    // 3. Propiedades públicas
    public let identifier: String

    // MARK: - Initialization

    init(identifier: String) {
        self.identifier = identifier
    }

    // MARK: - Body

    var body: some View {
        content
    }

    // MARK: - Private Views

    private var content: some View {
        Text("Content")
    }

    // MARK: - Methods

    private func handleAction() {
        // Implementation
    }
}

// MARK: - Preview

#Preview {
    FeatureView(identifier: "test")
}
```

---

## 🎨 Formateo

### Indentación
- **4 espacios** (no tabs)
- Configurado en `.swiftformat`

### Longitud de Línea
- **Máximo 120 caracteres**
- Preferir líneas de ~80 caracteres cuando sea posible

### Llaves

```swift
// ✅ Estilo K&R (mismo línea)
func example() {
    if condition {
        doSomething()
    }
}

// ❌ Allman (nueva línea)
func example()
{
    if condition
    {
        doSomething()
    }
}
```

### Espaciado

```swift
// ✅ Espacios alrededor de operadores
let sum = first + second
let isValid = value > 0 && value < 100

// ✅ Sin espacios en paréntesis
let result = calculate(value)

// ✅ Espacio después de comas
func method(first: Int, second: Int, third: Int)
```

---

## 🔐 Seguridad y Opcionales

### Unwrapping

```swift
// ✅ Guard let para early returns
func process(user: User?) {
    guard let user = user else {
        return
    }
    // Usar user de forma segura
}

// ✅ If let para scope limitado
if let userName = user?.name {
    print("Hello, \(userName)")
}

// ❌ Evitar force unwrap
let name = user!.name  // Prohibido en producción
```

### Nil Coalescing

```swift
// ✅ Valores por defecto
let displayName = user.name ?? "Guest"
let count = items?.count ?? 0
```

---

## 📦 Organización de Código

### MARK Comments

```swift
class ViewModel {

    // MARK: - Properties

    private var data: [Item] = []

    // MARK: - Lifecycle

    init() { }

    // MARK: - Public Methods

    func load() { }

    // MARK: - Private Methods

    private func process() { }
}
```

### Extensions

```swift
// Separar conformance a protocolos en extensions
extension UserView: Equatable {
    static func == (lhs: UserView, rhs: UserView) -> Bool {
        lhs.id == rhs.id
    }
}

extension UserView: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

---

## 🧪 Testing

### Naming de Tests

```swift
// Patrón: test + WhatIsTested + ExpectedBehavior
func testLoginWithValidCredentials_ShouldSucceed()
func testFetchUsers_WhenNetworkFails_ShouldReturnError()
```

### Estructura Given-When-Then

```swift
func testExample() async {
    // Given
    let service = MockService()
    let sut = ViewModel(service: service)

    // When
    await sut.performAction()

    // Then
    XCTAssertEqual(sut.state, .success)
}
```

---

## 🚫 Anti-Patrones a Evitar

### 1. Magic Numbers

```swift
// ❌
if count > 5 {
    // ...
}

// ✅
let maxAllowedItems = 5
if count > maxAllowedItems {
    // ...
}
```

### 2. Nested Callbacks (Pyramid of Doom)

```swift
// ❌
fetchUser { user in
    fetchProfile(for: user) { profile in
        fetchSettings(for: profile) { settings in
            // ...
        }
    }
}

// ✅ Usar async/await
let user = try await fetchUser()
let profile = try await fetchProfile(for: user)
let settings = try await fetchSettings(for: profile)
```

### 3. God Objects

```swift
// ❌ Una clase que hace todo
class MassiveViewController {
    // 1000+ líneas
}

// ✅ Separar responsabilidades
class ViewController {
    private let viewModel: ViewModel
    private let dataSource: DataSource
    private let coordinator: Coordinator
}
```

---

## ✅ Checklist Pre-Commit

Antes de hacer commit, verifica:

- [ ] `make lint` pasa sin errores
- [ ] `make format` no reporta cambios
- [ ] No hay force unwraps (`!`)
- [ ] No hay `print()` statements
- [ ] Código está documentado con MARK
- [ ] Tests cubren nuevos casos

---

## 📚 Referencias

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [SwiftFormat Options](https://github.com/nicklockwood/SwiftFormat#options)

---

**Mantenido por:** ARC Labs Studio
**Contacto:** dev@arclabs.studio
