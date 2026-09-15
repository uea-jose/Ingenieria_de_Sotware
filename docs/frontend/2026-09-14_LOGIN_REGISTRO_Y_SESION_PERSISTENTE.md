# Paso 1 — Autenticación real conectada al backend

Fecha: 2026-09-14
Rama: `backup/acordes-antes-split`
Alcance: **frontend** exclusivamente. Sin cambios en backend, base de datos ni modelo `Product`.

## Objetivo

Reemplazar la simulación visual del panel de cuenta por un flujo real que
consuma `POST /auth/login`, `GET /auth/me` y `POST /clientes/registro`.
La sesión persiste entre reloads en Flutter Web (localStorage) y el rol
del usuario se refleja en la UI (drawer, `/cuenta`, guards).

Es la piedra fundacional del resto del roadmap del frontend: sin sesión
real, el checkout no puede mandar `POST /ventas`, "Mis pedidos" no
podría filtrar por cliente, y el panel de administración no podría
distinguir roles.

## Endpoints consumidos

| Método | Ruta | Uso |
|---|---|---|
| `POST` | `/auth/login` | Login con `{correo, contrasena}` → `{token, usuario}` |
| `GET`  | `/auth/me` (Bearer) | Confirma que el token guardado sigue vigente y refresca los datos del usuario |
| `POST` | `/clientes/registro` | Crea `usuario + cliente` con `{nombres, apellidos, correo, contrasena, telefono?, cedula?, direccion?, ciudad?}` |

El token es JWT (HS256) con expiración `8h`. El backend responde los
errores como `{ "error": "mensaje" }` planos — no como `{error: {mensaje}}`.

## Estructura nueva

```
frontend/lib/
├── models/user.dart                      (nuevo)
├── data/
│   ├── api/auth_service.dart             (nuevo)
│   └── storage/
│       ├── auth_storage.dart             (nuevo — API pública)
│       ├── auth_storage_web.dart         (nuevo — impl dart:html)
│       └── auth_storage_stub.dart        (nuevo — impl in-memory)
├── state/auth_scope.dart                 (nuevo)
├── screens/
│   ├── auth/
│   │   ├── login_page.dart               (nuevo)
│   │   └── register_page.dart            (nuevo)
│   └── account/
│       └── account_page.dart             (nuevo)
├── widgets/layout/
│   └── account_drawer.dart               (refactor completo)
├── app/
│   └── aromas_store_app.dart             (refactor: rutas + AuthScope raíz)
├── config/
│   └── storage_keys.dart                 (agrega authTokenStorageKey y authUserStorageKey)
└── test/
    └── auth_pages_test.dart              (nuevo — 3 tests widget)
```

## Modelo `User`

`frontend/lib/models/user.dart` refleja tal cual el payload del backend:

```dart
class User {
  final int id;
  final String email;      // 'correo' en el JSON del server
  final String nombres;
  final String apellidos;
  final String rol;        // 'Administrador' | 'Cliente' | 'Bodeguero' | 'Vendedor'
  final bool activo;

  bool get isAdmin, isCliente, isBodeguero, isVendedor;
  bool get isStaff;  // isAdmin || isBodeguero || isVendedor
  String get displayName;  // "Nombres Apellidos", fallback a local-part del email
  String get initials;     // 1-2 chars para avatar
}
```

El rol se guarda como string plano (sin `enum`) porque el servidor lo
serializa así — mantenerlo string evita mapeos frágiles cada vez que se
lea el token.

## `AuthStorage` — persistencia web-safe

```
auth_storage.dart          ← API pública (loadToken / loadUser / save / clear)
   ├─ auth_storage_web.dart   ← usa dart:html + window.localStorage (Flutter Web)
   └─ auth_storage_stub.dart  ← in-memory (Flutter test VM y no-web)
```

La resolución la hace un **conditional import**:

```dart
import 'auth_storage_stub.dart'
    if (dart.library.html) 'auth_storage_web.dart'
    as backend;
```

Beneficios:
- El bundle web usa `localStorage` real → sesión persistente entre reloads.
- El test VM usa el stub → `dart:html` nunca se importa en test, así que
  `flutter test` compila sin flags especiales.
- Si en el futuro se agregan Android/iOS, el stub sigue funcionando en
  memoria y se puede sustituir por `shared_preferences` sin tocar
  `AuthStorage` ni `AuthService`.

Ambos backends implementan la misma API (`readToken`, `readUserJson`,
`writeBoth`, `writeUserJson`, `clearAll`) para que la fachada
`AuthStorage` sea trivial. La fachada además valida el JSON persistido
del usuario: si está corrupto, limpia ambas claves para no dejar estado
mixto.

## `AuthService` — cliente HTTP

`frontend/lib/data/api/auth_service.dart` maneja:

- **State interno**: `_token`, `_user`. Getters `currentToken`,
  `currentUser`, `isAuthenticated`.
- **`restoreSession()`**: lee `AuthStorage`, valida contra `GET /auth/me`.
  Si el server rechaza (401) hace `logout()` y retorna null. Si el
  server no está disponible (error de red) conserva la sesión cacheada
  para no dejar al usuario colgado offline.
- **`login({email, password})`**: `POST /auth/login`, guarda token+user,
  persiste. Rechaza vacíos localmente antes de mandar la request.
- **`register({...})`**: `POST /clientes/registro`. El backend NO
  devuelve token en registro, así que por defecto (`registerAutoLogin =
  true`) encadena un `login()` con las credenciales recién creadas —
  el usuario queda ya autenticado.
- **`me()`**: refresca el snapshot del usuario. Actualiza `AuthStorage`.
- **`logout()`**: limpia estado + storage.
- **`AuthException(message, statusCode)`**: única excepción que tira.
  El parser extrae el mensaje del backend en `{error: "..."}`, o cae a
  mensajes por status (`400`, `401`, `403`, `404`, `409`, otros).

El `http.Client` se inyecta en el constructor → testeable con
`package:http/testing.dart` cuando queramos.

## `AuthScope` + `AuthController`

`frontend/lib/state/auth_scope.dart` expone el estado a toda la app sin
librerías nuevas (sin `provider`, sin `riverpod`):

- **`AuthController extends ChangeNotifier`**: envuelve `AuthService` y
  agrega dos cosas que el UI necesita:
  - `AuthStatus status`: `initializing` / `unauthenticated` /
    `authenticated`, para render decisiones simples (splash vs
    contenido).
  - `AuthException? lastError`: se guarda cuando `login` o `register`
    fallan, para que el formulario pinte el banner rojo sin depender
    de `try/catch` en el UI.
  - `isBusy`: se pone a true durante mutaciones para desactivar botones
    y mostrar el spinner.
- **`AuthScope extends InheritedNotifier<AuthController>`**: descendientes
  se suscriben con `AuthScope.of(context)` (rebuilds al cambiar) o
  `AuthScope.read(context)` (sin rebuild — para callbacks).
- **`RequireAuth`**: widget guard para rutas privadas. Redirige a
  `/login` si no hay sesión, muestra un forbidden view si `requireStaff`
  está activo y el rol es Cliente, respeta `arguments` para que después
  del login el usuario aterrice en la página que iba a abrir.

Ubicación del árbol: la primera cosa que renderiza `AromasStoreApp` es
un `AuthScope` que envuelve todo el `MaterialApp`, así cualquier ruta
puede consumirlo. `bootstrap()` se dispara en `initState` del root para
restaurar la sesión antes del primer frame útil.

## Rutas

En `aromas_store_app.dart`:

```dart
routes: {
  '/':                    → HomePage,
  '/catalogo-perfumeria': → PerfumeryCatalogPage,
  '/acordes':             → AccordSearchPage,
  '/login':               → LoginPage,
  '/registro':            → RegisterPage,
  '/cuenta':              → RequireAuth(child: AccountPage),
  '/admin/acordes':       → RequireAuth(requireStaff: true, child: CatalogAdminPage),
  '/admin/catalogo':      → RequireAuth(requireStaff: true, child: CatalogAdminPage),
}
```

Consecuencias:
- Un cliente autenticado que intente entrar a `/admin/acordes` ve el
  forbidden view — no redirección — porque su sesión sí es válida, solo
  que le falta rol.
- Un usuario no autenticado que intente `/cuenta` o `/admin/*` es
  redirigido a `/login` con el `settings.arguments = 'ruta_original'`;
  al iniciar sesión aterriza directamente en la ruta original.

## Formularios

Ambos formularios (`login_page.dart` y `register_page.dart`) siguen las
mismas reglas:

1. `Form` + `TextFormField.validator` para validación local
   (correo con `@` y `.`, contraseña ≥ 8 chars en registro, no vacíos).
2. `onChanged` de cada campo llama `AuthController.clearError()` para
   que el banner rojo se desvanezca al empezar a corregir.
3. Botón principal `FilledButton.icon` con:
   - `onPressed: null` cuando `controller.isBusy` (deshabilita).
   - Icono reemplazado por `CircularProgressIndicator` durante la
     request.
4. Al éxito → `Navigator.pushNamedAndRemoveUntil` a la ruta guardada en
   `settings.arguments` o `/`.
5. Los errores del backend (401, 409, 400) se muestran en un `_ErrorBanner`
   inline **dentro** del formulario — no snackbars — para que persistan
   hasta que el usuario los resuelva.

`RegisterPage` divide el layout en dos columnas ≥ 600 px de ancho y
colapsa a una sola columna en móviles.

## `AccountDrawer` reactivo

El drawer lateral que abre el icono 👤 del header ahora **switchea** su
contenido según `AuthScope.of(context).isAuthenticated`:

- **Sin sesión** → `_LoginForm` inline conectado al `AuthController`
  real. Include botón "Crear cuenta" que navega a `/registro`.
- **Con sesión** → `_AuthenticatedView`: avatar con iniciales, nombre,
  correo, pill del rol, menú (Ver mi cuenta / Mis pedidos / Favoritos /
  Panel administración si `isStaff`) y botón "Cerrar sesión".

## Validaciones

| Comando | Resultado |
|---|---|
| `flutter analyze --no-fatal-infos` | **No issues found** |
| `flutter test` | **17/17 tests aprobados** (14 previos + 3 nuevos) |
| `flutter build web` | **Built build/web** en 100 s |
| `POST /auth/login` (admin) | 200, token 281 chars, usuario rol=Administrador |
| `GET /auth/me` (Bearer válido) | 200 con `{usuario}` |
| `GET /auth/me` (sin token) | 401 |
| `POST /clientes/registro` | 201 con `{usuario, cliente}`, rol=Cliente |

Tests nuevos en `frontend/test/auth_pages_test.dart`:

1. `LoginPage` renderiza título, ambos inputs, botón principal y "Crear cuenta".
2. Enviar el formulario vacío dispara los validadores de correo y
   contraseña, sin llamar a la API.
3. `RegisterPage` valida la regla "contraseña ≥ 8 caracteres" mientras
   los campos ya rellenados no re-disparan sus propios validadores.

Los tests se corren con `tester.view.physicalSize = Size(1000, 1600)`
para que el form quepa completo en el viewport virtual.

## Cuenta de prueba

Durante la validación manual se creó una cuenta cliente en la base real
(id=7, cliente id=3) que puede usarse para probar el flujo público:

```
Correo:    jose.prueba5458@example.com
Password:  Test12345
Rol:       Cliente
```

Junto con la del admin (`admin@aromasstore.com` / `Admin12345`), sirven
para verificar:

- Login como cliente → drawer muestra rol "Cliente", sin acceso a
  `/admin/*`.
- Login como admin → drawer muestra "Panel administración".
- Logout → sesión limpia, `/cuenta` redirige a `/login`.

## Decisiones y descartes

- **Sin `provider` / `riverpod`**: elegido `ChangeNotifier` +
  `InheritedNotifier` porque no requiere agregar dependencias al
  `pubspec.yaml` y el estado global es pequeño (un `User` + tres
  banderas). Rechazado `provider` para mantener el proyecto sin
  librerías extra hasta que la escala lo justifique.
- **`auth_storage_*.dart` con conditional imports**: rechazado
  `shared_preferences` (bundle más grande y requiere config extra por
  plataforma) y rechazado envolver `dart:html` en `try/catch` (no
  resuelve el problema de compilación en test VM). El conditional
  import es idiomatic Dart, cero deps.
- **Auto-login tras registro**: el backend no devuelve token en
  `POST /clientes/registro`. Encadenar un `login()` interno evita que
  el usuario tenga que reingresar credenciales que acaba de escribir.
  Se puede desactivar pasando `registerAutoLogin: false` al
  `AuthService` (para tests).
- **`AuthController.login` no lanza excepciones al UI**: retorna `bool`
  y guarda el error en `lastError`. Reduce boilerplate `try/catch` en
  cada formulario a un simple `if (ok) …`.
- **Row → Wrap en LoginPage**: el `Row(mainAxisAlignment: spaceBetween)`
  con "Olvidé mi contraseña" + "Crear cuenta" reventaba en anchos
  estrechos (`RenderFlex overflowed`). `Wrap` colapsa a segunda línea
  cuando no cabe.

## Próximo paso (Paso 2)

Con `AuthController` disponible en todo el árbol, el siguiente paso ya
tiene todo lo que necesita:

- **Página de checkout** (`/checkout`) que consuma `POST /ventas` +
  `POST /pagos` con `Authorization: Bearer ${AuthScope.of(context).token}`.
- Al no haber sesión → `RequireAuth` redirige a `/login`; al volver el
  usuario aterriza en `/checkout` (gracias al `arguments`).
- **Historial de pedidos** (`/mis-pedidos`) idéntico, `GET /ventas`
  filtrada por cliente.

Ambos flujos son puramente UI + fetch — ya no requieren decisiones de
arquitectura fundacional.
