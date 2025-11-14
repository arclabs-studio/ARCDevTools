# ARC Labs - Convenciones de Naming

**Versión:** 1.0.0
**Última actualización:** 2024-11-14

---

## 🎯 Principios Generales

1. **Claridad sobre Brevedad**: Nombres descriptivos que indiquen propósito
2. **Consistencia**: Mismo patrón en toda la codebase
3. **Convenciones Swift**: Seguir Swift API Design Guidelines
4. **Contexto**: Nombres deben ser claros fuera de contexto

---

## 📝 Tipos de Datos

### Classes

```swift
// UpperCamelCase (PascalCase)
// Sustantivos que describan qué ES el objeto

class UserProfileViewModel { }
class NetworkService { }
class AuthenticationManager { }
class DataCache { }
```

**Sufijos comunes:**
- `Manager`: Gestiona recursos o estado
- `Service`: Provee funcionalidad específica
- `Controller`: Coordina flujo de datos
- `Factory`: Crea instancias
- `Builder`: Construye objetos complejos

### Structs

```swift
// UpperCamelCase
// Sustantivos, preferir structs sobre classes cuando sea posible

struct User { }
struct APIConfiguration { }
struct ValidationResult { }
struct AppTheme { }
```

### Enums

```swift
// UpperCamelCase para el tipo
// lowerCamelCase para los casos

enum NetworkError {
    case timeout
    case invalidURL
    case serverError(code: Int)
    case unauthorized
}

enum ViewState {
    case idle
    case loading
    case loaded(Data)
    case error(String)
}

// Enums como namespaces
enum Constants {
    static let apiBaseURL = "https://api.example.com"
    static let timeout: TimeInterval = 30
}
```

### Protocols

```swift
// UpperCamelCase
// Terminación según propósito:

// -able/-ible: Capacidad
protocol Cancellable { }
protocol Configurable { }
protocol Refreshable { }

// -ing: Acción en progreso
protocol DataFetching { }
protocol ImageCaching { }

// Sin sufijo: Concepto o rol
protocol DataSource { }
protocol Delegate { }
protocol Repository { }
```

---

## 🔤 Variables y Propiedades

### Variables Locales

```swift
// lowerCamelCase
let userName: String
var isLoading: Bool
let maxRetryCount: Int

// Booleanos: usar prefijos is/has/should/will/did
let isValid: Bool
let hasChanges: Bool
let shouldRefresh: Bool
let willAppear: Bool
let didFinish: Bool
```

### Propiedades de Instancia

```swift
class ViewModel {
    // Privadas: prefijo sin guión bajo
    private let networkService: NetworkService
    private var cachedData: [Item]

    // Públicas
    let identifier: String
    var title: String
}
```

### Constantes

```swift
// Scope local: lowerCamelCase
let defaultTimeout: TimeInterval = 30

// Globales o estáticas: UpperCamelCase
struct Config {
    static let DefaultTimeout: TimeInterval = 30
    static let MaxRetries: Int = 3
}
```

### Computed Properties

```swift
// Usar sustantivos, no verbos
var fullName: String {
    "\(firstName) \(lastName)"
}

var isValid: Bool {
    email.contains("@")
}

// ❌ Evitar
var getFullName: String { }
var checkIsValid: Bool { }
```

---

## 🎬 Funciones y Métodos

### Reglas Generales

```swift
// lowerCamelCase
// Verbo + Objeto (cuando aplique)

func fetchUserProfile() async throws -> User
func validateEmail(_ email: String) -> Bool
func configure(with viewModel: ViewModel)
func save(user: User, to database: Database)
```

### Prefijos Comunes

```swift
// fetch: Obtener datos (puede ser async/network)
func fetchUsers() async throws -> [User]

// load: Cargar datos (local o sincrónico)
func loadConfiguration()

// save: Persistir datos
func saveUser(_ user: User)

// update: Modificar existente
func updateProfile(with data: ProfileData)

// delete/remove: Eliminar
func deleteUser(id: UUID)
func removeFromCache(key: String)

// validate: Verificar condición
func validateInput() -> Bool

// calculate/compute: Procesamiento
func calculateTotal(items: [Item]) -> Decimal

// handle: Responder a eventos
func handleButtonTap()
func handleError(_ error: Error)

// configure/setup: Inicialización
func configure()
func setupViews()
```

### Métodos Booleanos

```swift
// Usar prefijos: is/has/should/can/will/did
func isValid() -> Bool
func hasChanges() -> Bool
func shouldReload() -> Bool
func canEdit() -> Bool
```

### Parámetros

```swift
// Labels externos descriptivos
func move(from source: URL, to destination: URL)
func add(_ item: Item, to collection: Collection)

// _ para casos obvios
func validate(_ email: String) -> Bool
func sort(_ items: [Item]) -> [Item]

// with/for/by cuando mejore legibilidad
func configure(with theme: Theme)
func fetch(for userID: UUID)
func filter(by predicate: Predicate)
```

---

## 🎨 SwiftUI Específico

### Views

```swift
// Sufijo "View"
struct UserProfileView: View { }
struct LoginView: View { }
struct SettingsView: View { }

// Subviews: contexto + View
struct UserProfileHeaderView: View { }
struct UserProfileAvatarView: View { }
```

### ViewModels

```swift
// Sufijo "ViewModel"
@Observable
final class UserProfileViewModel { }

@Observable
final class SettingsViewModel { }
```

### Environment Keys

```swift
// Key + "Key"
struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .light
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
```

### @State, @Binding, etc.

```swift
struct ContentView: View {
    // Sin prefijo especial
    @State private var isPresented = false
    @Binding var text: String
    @Environment(\.theme) var theme
    @StateObject private var viewModel = ViewModel()
}
```

---

## 🗂️ Archivos y Carpetas

### Archivos Swift

```swift
// UpperCamelCase
// Coincidir con el tipo principal definido

UserProfileView.swift
UserProfileViewModel.swift
NetworkService.swift
User.swift  // Entity
```

### Carpetas

```swift
// UpperCamelCase para features
// PascalCase para agrupaciones técnicas

Features/
  UserProfile/
  Settings/
Domain/
  Entities/
  UseCases/
Data/
  Repositories/
  Network/
```

---

## 🧪 Testing

### Test Files

```swift
// Nombre + "Tests"
UserProfileViewModelTests.swift
NetworkServiceTests.swift
```

### Test Methods

```swift
// test + WhatIsTested + ExpectedBehavior
func testFetchUser_WhenNetworkSucceeds_ShouldReturnUser() async
func testValidateEmail_WithInvalidFormat_ShouldReturnFalse()
func testViewModel_WhenLoadCalled_ShouldUpdateState() async

// Separar con guiones bajos para legibilidad
func test_givenEmptyCart_whenAddingItem_thenCountIsOne()
```

### Mocks

```swift
// Mock + TipoPrincipal
class MockNetworkService: NetworkService { }
class MockUserRepository: UserRepository { }

// Stub para datos
struct StubUser {
    static let valid = User(...)
    static let invalid = User(...)
}
```

---

## 🔤 Acrónimos y Abreviaciones

### Reglas

```swift
// Acrónimos de 2 letras: uppercase
let userID: String
let urlString: String
let httpClient: HTTPClient

// Acrónimos de 3+ letras: solo primera mayúscula
let htmlParser: HTMLParser
let jsonDecoder: JSONDecoder
let apiKey: String

// ✅ Correcto
class URLValidator { }
class HTTPClient { }
class XMLParser { }

// ❌ Incorrecto
class UrlValidator { }
class HttpClient { }
class XmlParser { }
```

---

## 🚫 Anti-Patrones

### Evitar

```swift
// ❌ Abreviaciones no estándar
let usr: User  // ✅ user
let btn: Button  // ✅ button
let temp: Temperature  // ✅ temperature

// ❌ Prefijos húngaros
let strName: String  // ✅ name
let intCount: Int  // ✅ count

// ❌ Sufijos de tipo redundantes
let userArray: [User]  // ✅ users
let nameDictionary: [String: String]  // ✅ namesByID

// ❌ Nombres vagos
func doStuff()  // ✅ processUserData()
var data: Data  // ✅ profileImageData
let manager: Manager  // ✅ networkManager

// ❌ Negaciones en booleanos
var notValid: Bool  // ✅ isInvalid
var cantEdit: Bool  // ✅ isEditable (invertir lógica)
```

---

## ✅ Checklist

Antes de nombrar algo, pregúntate:

- [ ] ¿El nombre describe claramente el propósito?
- [ ] ¿Sigue las convenciones Swift?
- [ ] ¿Es consistente con código existente?
- [ ] ¿Será claro para otros desarrolladores?
- [ ] ¿Evita abreviaciones ambiguas?
- [ ] ¿Los booleanos usan prefijos is/has/should?
- [ ] ¿Las funciones comienzan con verbos?
- [ ] ¿Los tipos usan sustantivos?

---

## 📚 Referencias

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftLint identifier_name Rule](https://realm.github.io/SwiftLint/identifier_name.html)

---

**Mantenido por:** ARC Labs Studio
**Contacto:** dev@arclabs.studio
