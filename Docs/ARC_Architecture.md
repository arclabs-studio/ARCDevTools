# ARC Labs - Guía de Arquitectura

**Versión:** 1.0.0
**Última actualización:** 2024-11-14

---

## 🏛️ Arquitectura Base: MVVM + Clean Architecture

Todos los proyectos de ARC Labs siguen una arquitectura MVVM (Model-View-ViewModel) con principios de Clean Architecture para garantizar:

- ✅ **Separación de responsabilidades**
- ✅ **Testabilidad**
- ✅ **Mantenibilidad**
- ✅ **Escalabilidad**

---

## 📊 Capas de la Arquitectura

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  (Views, ViewModels, Coordinators)      │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│           Domain Layer                  │
│  (Use Cases, Entities, Protocols)       │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│           Data Layer                    │
│  (Repositories, Network, Database)      │
└─────────────────────────────────────────┘
```

---

## 🎨 Presentation Layer

### View (SwiftUI)

Responsabilidades:
- Renderizar UI
- Responder a interacciones del usuario
- Observar cambios en ViewModel
- **NO** contener lógica de negocio

```swift
import SwiftUI

struct UserProfileView: View {

    @State private var viewModel = UserProfileViewModel()

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Profile")
        }
        .task {
            await viewModel.loadProfile()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            placeholderView
        case .loading:
            ProgressView()
        case .loaded(let user):
            profileContent(user: user)
        case .error(let message):
            errorView(message: message)
        }
    }

    private func profileContent(user: User) -> some View {
        VStack {
            AsyncImage(url: user.avatarURL)
            Text(user.name)
            Text(user.email)
        }
    }
}
```

### ViewModel

Responsabilidades:
- Gestionar estado de la UI
- Coordinar casos de uso (Use Cases)
- Transformar datos del dominio para presentación
- Manejar errores

```swift
import Foundation
import Observation

@MainActor
@Observable
final class UserProfileViewModel {

    // MARK: - State

    enum State: Equatable {
        case idle
        case loading
        case loaded(User)
        case error(String)
    }

    private(set) var state: State = .idle

    // MARK: - Dependencies

    private let fetchUserUseCase: FetchUserUseCase

    // MARK: - Initialization

    init(fetchUserUseCase: FetchUserUseCase = FetchUserUseCaseImpl()) {
        self.fetchUserUseCase = fetchUserUseCase
    }

    // MARK: - Actions

    func loadProfile() async {
        state = .loading

        do {
            let user = try await fetchUserUseCase.execute()
            state = .loaded(user)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

**Reglas para ViewModels:**
1. Siempre usar `@Observable` (Swift 6)
2. `@MainActor` para operaciones de UI
3. Inyección de dependencias via inicializador
4. Estado inmutable desde fuera (`private(set)`)

---

## 🎯 Domain Layer

### Entities

Modelos de negocio puros, sin dependencias de frameworks.

```swift
struct User: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let email: String
    let avatarURL: URL?
    let createdAt: Date
}
```

### Use Cases

Encapsulan lógica de negocio específica.

```swift
// Protocol
protocol FetchUserUseCase: Sendable {
    func execute() async throws -> User
}

// Implementation
final class FetchUserUseCaseImpl: FetchUserUseCase {

    private let userRepository: UserRepository

    init(userRepository: UserRepository = UserRepositoryImpl()) {
        self.userRepository = userRepository
    }

    func execute() async throws -> User {
        // Lógica de negocio (validaciones, transformaciones, etc.)
        let user = try await userRepository.fetchCurrentUser()

        guard user.isActive else {
            throw UserError.accountInactive
        }

        return user
    }
}
```

**Cuándo crear un Use Case:**
- Operaciones que combinan múltiples repositorios
- Lógica de negocio compleja
- Casos que requieren validación
- Operaciones reutilizables entre features

---

## 💾 Data Layer

### Repositories

Abstraen la fuente de datos (red, base de datos, caché).

```swift
// Protocol (en Domain Layer)
protocol UserRepository: Sendable {
    func fetchCurrentUser() async throws -> User
    func updateUser(_ user: User) async throws
}

// Implementation (en Data Layer)
final class UserRepositoryImpl: UserRepository {

    private let networkService: NetworkService
    private let databaseService: DatabaseService

    init(
        networkService: NetworkService = NetworkServiceImpl(),
        databaseService: DatabaseService = DatabaseServiceImpl()
    ) {
        self.networkService = networkService
        self.databaseService = databaseService
    }

    func fetchCurrentUser() async throws -> User {
        // 1. Check cache
        if let cachedUser = try? await databaseService.fetchUser() {
            return cachedUser
        }

        // 2. Fetch from network
        let userDTO = try await networkService.request(
            endpoint: .currentUser,
            responseType: UserDTO.self
        )

        // 3. Map DTO to Domain Entity
        let user = userDTO.toDomain()

        // 4. Save to cache
        try? await databaseService.save(user)

        return user
    }

    func updateUser(_ user: User) async throws {
        let dto = UserDTO(from: user)
        try await networkService.request(
            endpoint: .updateUser,
            method: .put,
            body: dto
        )

        // Update cache
        try? await databaseService.save(user)
    }
}
```

### Data Transfer Objects (DTOs)

Modelos que mapean respuestas de API.

```swift
struct UserDTO: Codable {
    let id: String
    let name: String
    let email: String
    let avatar_url: String?
    let created_at: String

    // Mapeo a Domain Entity
    func toDomain() -> User {
        User(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            email: email,
            avatarURL: avatar_url.flatMap(URL.init(string:)),
            createdAt: ISO8601DateFormatter().date(from: created_at) ?? Date()
        )
    }
}

extension UserDTO {
    init(from user: User) {
        self.id = user.id.uuidString
        self.name = user.name
        self.email = user.email
        self.avatar_url = user.avatarURL?.absoluteString
        self.created_at = ISO8601DateFormatter().string(from: user.createdAt)
    }
}
```

---

## 🧪 Testing Strategy

### Unit Tests para ViewModels

```swift
import XCTest
@testable import App

@MainActor
final class UserProfileViewModelTests: XCTestCase {

    var sut: UserProfileViewModel!
    var mockUseCase: MockFetchUserUseCase!

    override func setUp() {
        super.setUp()
        mockUseCase = MockFetchUserUseCase()
        sut = UserProfileViewModel(fetchUserUseCase: mockUseCase)
    }

    func testLoadProfile_Success() async {
        // Given
        let expectedUser = User.mock()
        mockUseCase.result = .success(expectedUser)

        // When
        await sut.loadProfile()

        // Then
        if case .loaded(let user) = sut.state {
            XCTAssertEqual(user, expectedUser)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testLoadProfile_Failure() async {
        // Given
        mockUseCase.result = .failure(UserError.notFound)

        // When
        await sut.loadProfile()

        // Then
        if case .error = sut.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected error state")
        }
    }
}
```

### Mocks

```swift
#if DEBUG
final class MockFetchUserUseCase: FetchUserUseCase {

    var result: Result<User, Error> = .success(.mock())
    var executeCallCount = 0

    func execute() async throws -> User {
        executeCallCount += 1

        switch result {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
}

extension User {
    static func mock(
        id: UUID = UUID(),
        name: String = "John Doe",
        email: String = "john@example.com"
    ) -> User {
        User(id: id, name: name, email: email, avatarURL: nil, createdAt: Date())
    }
}
#endif
```

---

## 📁 Estructura de Carpetas

```
MyApp/
├── Sources/
│   ├── App/
│   │   └── MyAppApp.swift
│   ├── Features/
│   │   ├── UserProfile/
│   │   │   ├── Views/
│   │   │   │   └── UserProfileView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── UserProfileViewModel.swift
│   │   │   └── Models/
│   │   │       └── UserProfileState.swift
│   │   └── Settings/
│   │       └── ...
│   ├── Domain/
│   │   ├── Entities/
│   │   │   └── User.swift
│   │   ├── UseCases/
│   │   │   └── FetchUserUseCase.swift
│   │   └── Protocols/
│   │       └── UserRepository.swift
│   ├── Data/
│   │   ├── Repositories/
│   │   │   └── UserRepositoryImpl.swift
│   │   ├── Network/
│   │   │   ├── NetworkService.swift
│   │   │   └── DTOs/
│   │   │       └── UserDTO.swift
│   │   └── Database/
│   │       └── DatabaseService.swift
│   └── Core/
│       ├── Extensions/
│       ├── Utilities/
│       └── Theme/
└── Tests/
    ├── FeatureTests/
    ├── DomainTests/
    └── DataTests/
```

---

## 🔄 Flujo de Datos

```
User Action → View → ViewModel → Use Case → Repository → Network/DB
                ↑                    ↓
                └────── State ←──────┘
```

1. **Usuario interactúa** con la View
2. **View invoca método** del ViewModel
3. **ViewModel ejecuta** Use Case
4. **Use Case coordina** lógica de negocio usando Repository
5. **Repository obtiene datos** de fuente (Network/DB)
6. **Datos fluyen de vuelta** transformándose en cada capa
7. **ViewModel actualiza estado**
8. **View reactiva al cambio** y re-renderiza

---

## ✅ Checklist de Arquitectura

Al crear una nueva feature, verifica:

- [ ] View solo contiene UI, sin lógica de negocio
- [ ] ViewModel usa `@Observable` y `@MainActor`
- [ ] Dependencias inyectadas via inicializador
- [ ] Protocolos definidos para todas las dependencias
- [ ] Use Cases encapsulan lógica de negocio
- [ ] Repositories abstraen fuente de datos
- [ ] DTOs separados de Entities
- [ ] Tests con mocks para todas las capas
- [ ] Estado del ViewModel es enum con casos claros

---

**Mantenido por:** ARC Labs Studio
**Contacto:** dev@arclabs.studio
