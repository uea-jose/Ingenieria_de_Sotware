# Mejoras UX transversales y entrega con GPS + snapshot inmutable en Venta

Fecha: 2026-09-15
Rama: `backup/acordes-antes-split`
Alcance: **frontend + backend** (schema Prisma + módulo nuevo `ubicacion` + `ventas` extendido).

## 1. Objetivo

Dos frentes que viajaron juntos porque comparten componentes:

1. **9 mejoras transversales de UX** (validadores reutilizables, banner de feedback unificado, snackbars consistentes, medidor de contraseña, teléfono Ecuador con formatter, toggle mostrar/ocultar contraseña también en admin).
2. **Checkout con dirección de entrega y GPS opcional** (Opción B aprobada): el cliente pulsa "Usar mi ubicación", el backend hace reverse geocoding y la dirección se guarda como *snapshot* junto a la venta. Si el cliente cambia luego su perfil, las ventas pasadas conservan la dirección original.

## 2. Fase 1 — Mejoras UX transversales

### 2.1 `core/validators.dart`

Único punto donde vive la lógica de validación reutilizable:

- `Validators.required(value, field:...)` — no vacío tras trim.
- `Validators.email(value)` — regex simple pero robusto.
- `Validators.password(value)` — devuelve el primer error específico entre las 4 reglas (≥ 8, mayúscula, dígito, símbolo).
- `Validators.passwordMatch(confirm, password:...)` — para el campo "Confirmar contraseña".
- `Validators.phoneEcuador(value, isRequired: bool)` — acepta `09XXXXXXXX`, `+593 9XXXXXXXX`, `593 9XXXXXXXX`.
- `PasswordChecks.hasMinLength / hasUppercase / hasDigit / hasSpecialChar / passesAll` — booleanos, consumidos por el meter.
- `normalizePhoneEcuador(raw)` — devuelve la forma canónica `09XXXXXXXX` o `null` si no es válido; se usa **antes** de persistir el teléfono en la venta.

### 2.2 `widgets/feedback/feedback_banner.dart`

Un solo `FeedbackBanner` con constructores nombrados `.success / .error / .warning / .info`. Sustituye los cuatro `_ErrorBanner` privados que existían en `login_page`, `register_page`, `account_drawer` y `checkout_page`. Cada variante usa los tokens del design system (`AppColors.successSoft`, `errorSoft`, `bgPeach`, `bgBlue`) con borde e icono coherentes.

### 2.3 `widgets/feedback/app_feedback.dart`

Helper `AppFeedback.success/error/warning/info(context, message)` que reemplaza los ~15 `ScaffoldMessenger.showSnackBar` dispersos. Todos los snackbars ahora comparten borde, icono, color y comportamiento flotante.

### 2.4 `widgets/forms/password_strength_meter.dart`

Checklist en vivo que consume `PasswordChecks` (sin duplicar regex). Se pinta bajo el campo contraseña en `RegisterPage`.

### 2.5 Formularios afectados

- **`RegisterPage`**: añadido campo "Confirmar contraseña", `PasswordStrengthMeter` en vivo, validators con reglas fuertes, teléfono con `TextInputFormatter` y hint del formato Ecuador, `FeedbackBanner.error` en lugar del banner privado, `AppFeedback.success` al confirmar. El teléfono se normaliza antes de mandar al backend.
- **`LoginPage`** y **`AccountDrawer`**: mismo banner compartido + `Validators.email`.
- **`CheckoutPage`**: banners de warning/error unificados; consolidamos las alertas de stock en un único `FeedbackBanner.warning` en la pantalla de éxito.
- **`catalog_admin_page`** (admin): el campo contraseña ahora tiene toggle de visibilidad + `autofillHints`.

## 3. Fase 2 — Entrega con GPS + snapshot en Venta

### 3.1 Esquema Prisma — 6 campos aditivos en `Venta`

```prisma
model Venta {
  // ...campos existentes intactos...

  // Delivery snapshot — capturado en el checkout, nunca mutado después.
  direccionEntrega  String?  @db.VarChar(255)
  ciudadEntrega     String?  @db.VarChar(80)
  referenciaEntrega String?  @db.VarChar(255)
  telefonoContacto  String?  @db.VarChar(30)
  latitudEntrega    Decimal? @db.Decimal(10, 7)
  longitudEntrega   Decimal? @db.Decimal(10, 7)
}
```

**Todos nullables** para preservar las ventas históricas sin backfill. `prisma db push` corrió con: `Your database is now in sync with your Prisma schema. Done in 199ms` — **sin warnings de data-loss**.

Verificación directa en Postgres tras la migración:

```
ciudadEntrega     | character varying(80)
direccionEntrega  | character varying(255)
latitudEntrega    | numeric(10,7)
longitudEntrega   | numeric(10,7)
referenciaEntrega | character varying(255)
telefonoContacto  | character varying(30)
```

Cliente Prisma regenerado con `prisma generate` (v7.8.0).

### 3.2 Nuevo módulo backend `ubicacion`

Reverse geocoding centralizado en el servidor — **el frontend nunca llama Nominatim directo**. Motivo: control de rate-limiting, User-Agent, caché y evitar acoplar al proveedor.

```
backend/src/modules/ubicacion/
├── ubicacion.routes.js        GET /api/ubicacion/reverse   (público)
├── ubicacion.controller.js    reverse(req,res,next)
└── ubicacion.service.js       reverseGeocode({ lat, lon })
```

Detalles del servicio:

- Validación estricta: `lat ∈ [-90, 90]`, `lon ∈ [-180, 180]` → **400** si algo no encaja.
- Caché en memoria (`Map`) con TTL de **24 h** y capacidad máxima de 500 entradas con eviction FIFO. Clave: coordenadas redondeadas a **4 decimales** (~11 m).
- Rate limit global de **1 request/segundo** mediante una cadena de promesas — cumple los ToS de Nominatim.
- `User-Agent: AromasStore/1.0 (https://github.com/uea-jose/Ingenieria_de_Sotware)` en cada llamada.
- Timeout de 8 s con `AbortController`; errores mapeados a 502/504 según causa.
- Idioma pedido: `accept-language: es`.
- **DTO devuelto al frontend** (jamás el JSON crudo de Nominatim):

```json
{
  "dato": {
    "direccion":  "Diego Noboa, Barrio Batán Alto",
    "ciudad":     "Quito",
    "provincia":  "Pichincha",
    "pais":       "Ecuador",
    "latitud":    -0.180653,
    "longitud":   -78.467838,
    "latitudSolicitada":  -0.180653,
    "longitudSolicitada": -78.467838,
    "fuente":      "nominatim",
    "cache":       false,
    "atribucion":  "© OpenStreetMap contributors — https://www.openstreetmap.org/copyright"
  }
}
```

Registrado en `routes/index.js` y aparece en la lista JSON del endpoint raíz (`GET /api`).

**Verificado con curl:** 1er request → hace fetch a Nominatim, `cache:false`. 2do request idéntico → `cache:true`. `lat=999` → 400 con `"lat debe estar entre -90 y 90."`.

### 3.3 `ventas.service.js` extendido

`crearVenta` acepta un objeto `entrega` con los 6 campos opcionales. Un helper local los normaliza:

- `textoOpcional(valor, maxLen)` — trim, `null` si vacío, truncado al ancho VARCHAR de la columna.
- `coordenada(valor, min, max, label)` — devuelve `null` si `undefined/null/""`, `Number` si es finito y está en rango; tira 400 en cualquier otro caso.

El snapshot se hace *spread* dentro de `tx.venta.create({ data: { ..., ...snapshotEntrega } })`. Ninguno de estos campos toca la tabla `Cliente` — el perfil del cliente **no se modifica jamás por el checkout**, tal como pediste.

`GET /ventas` y `GET /ventas/mis` usan `include` sin `select` restrictivo → Prisma devuelve automáticamente los 6 campos nuevos. Verificado con `curl` en las 3 formas: venta nueva con snapshot, venta legacy sin snapshot, venta con coordenada inválida rechazada.

### 3.4 Frontend

Nueva dependencia: `geolocator: ^14.0.3` (compatible con Dart 3.12 y Flutter 3.44 sin necesidad de actualizar el SDK). En web usa `navigator.geolocation` internamente.

Archivos nuevos:

- `frontend/lib/data/location/location_service.dart` — envuelve `Geolocator` y llama `GET /api/ubicacion/reverse`. Errores tipados con `LocationErrorCode { serviceDisabled, permissionDenied, permissionDeniedForever, timeout, reverseGeocodeFailed, network, unknown }`. Nunca dispara `requestPermission()` automáticamente — solo cuando el widget lo pide.
- `frontend/lib/widgets/checkout/delivery_address_panel.dart` — bloque UI dentro del checkout:
  - Botón **"Usar mi ubicación"** que ejecuta el flujo permiso → posición → reverse geocode → llenar campos.
  - 4 `TextFormField`: Dirección `*`, Ciudad `*`, Referencia (opcional), Teléfono `*` (con formatter Ecuador).
  - Al éxito del GPS: banner verde con la atribución `© OpenStreetMap contributors`.
  - Al fallo: banner adecuado (`serviceDisabled` → warning; `permissionDenied` → info; `network` → error). En **todos** los casos los campos siguen editables → el cliente escribe manualmente y compra igual.
  - Si el usuario edita Dirección o Ciudad después de un GPS OK, se descartan las coordenadas capturadas (ya no corresponden a lo que va a enviar).

Modelo:

- `frontend/lib/models/order.dart` — expone los 6 campos snapshot + getter `tieneSnapshotEntrega` que decide si `/mis-pedidos` renderiza el bloque de dirección.

Cliente HTTP:

- `frontend/lib/data/api/orders_api.dart` — nueva clase `DeliverySnapshotDraft` con serialización idempotente (sólo incluye claves no nulas), acoplada a `OrdersApi.createOrder`.

Página:

- `frontend/lib/screens/checkout/checkout_page.dart`:
  - Nuevos `TextEditingController` para los 4 campos + estado local `_latitudCapturada`, `_longitudCapturada`.
  - El contenido del layout ahora vive dentro de un `Form(key: _formKey)`. Antes de mandar el pedido llamamos `_formKey.currentState.validate()` — si falla, banner rojo y no se envía nada.
  - Se normaliza el teléfono con `normalizePhoneEcuador(...)` antes de armar `DeliverySnapshotDraft`.
  - Layout responsive: en pantallas ≥ 900 px el panel de dirección va en la columna derecha, encima del panel de pago.
- `frontend/lib/screens/orders/my_orders_page.dart` — nueva sección `_DeliveryBlock` dentro de cada tarjeta expandida, sólo visible cuando `order.tieneSnapshotEntrega` es `true`. Muestra dirección, ciudad, referencia, teléfono y coordenadas si están.

## 4. Los 6 casos de aceptación

Ejecutados con `Invoke-RestMethod` contra el backend en vivo:

| # | Caso | Resultado |
|---|---|---|
| 1 | GPS aceptado → ciudad/dirección detectada → venta guarda snapshot | Venta id=8 quedó con `direccion='Av. 10 de Agosto y Colón'`, `ciudad='Quito'`, `lat=-0.199`, `lon=-78.494`. |
| 2 | GPS falla / reverse falla → usuario llena manualmente → puede comprar | Venta id=9 con `direccion='Cdla. Kennedy Norte Mz 42'`, `ciudad='Guayaquil'`, sin lat/lon. |
| 3 | GPS rechazado → mensaje informativo, sin bloquear checkout | El panel muestra `FeedbackBanner.info`, los campos siguen escribibles y `POST /ventas` funciona igual que caso 2. |
| 4 | Edición manual sobrescribe la dirección detectada | Venta id=10 con `direccion='Sobrescrito manualmente por el usuario'`, `ciudad='Cuenca'` aunque las coordenadas eran de otra zona → el servidor guarda literalmente lo enviado, sin re-geocodificar. |
| 5 | Cliente cambia su perfil después → pedidos anteriores conservan su dirección | `UPDATE clientes SET direccion='DIRECCION NUEVA POST-CHECKOUT', ciudad='AMBATO'` → las ventas 6, 8, 9, 10 siguen mostrando su `direccionEntrega` original. |
| 6 | Ventas históricas sin snapshot no rompen `/mis-pedidos` | Ventas 4, 5 y 7 (creadas antes de la migración o sin snapshot) devuelven todos los campos en `null` y la UI las renderiza sin el bloque de dirección — sin excepciones. |

## 5. Validaciones automáticas

| Comando | Resultado |
|---|---|
| `flutter analyze --no-fatal-infos` | **No issues found** |
| `flutter test` | **20/20 tests aprobados** |
| `flutter build web --no-source-maps --no-wasm-dry-run` | **Built build\web** en 64.7 s |
| `node --test backend/scripts/product-profile-unit.test.js` | **2/2 tests aprobados** |
| `prisma db push` | *"The database is already in sync with the Prisma schema."* — sin warnings |

## 6. Decisiones y descartes

- **Reverse geocoding en el backend, no en el frontend** (ajuste #3 del usuario). Motivos concretos: control de rate limit para no exceder 1 req/s de Nominatim, poder cachear resultados repetidos, User-Agent consistente, evitar CORS del navegador, y dejar la arquitectura desacoplable si un día cambiamos de proveedor.
- **6 columnas planas en `Venta` vs modelo `DireccionEntrega`** — se optó por planas para no sobre-ingenierizar: son campos textuales cortos y siempre viajan juntos con la venta.
- **Nullable a nivel DB, requerido a nivel UI** (ajuste #1). Da compatibilidad total con las ventas históricas sin backfill mientras se garantiza validez en compras nuevas.
- **`Cliente` no se toca en el checkout** (ajuste #7). La regla de negocio de "guardar esta dirección en mi perfil" queda para una etapa futura como acción explícita del usuario, no como efecto colateral de comprar.
- **No implementamos mapa** (ajuste #4). El GPS + reverse geocoding cubre el 80 % del beneficio sin necesidad de agregar `flutter_map` o `google_maps_flutter`.
- **`geolocator ^14.0.3` en lugar de una versión reciente arbitraria** (ajuste #10). Se revisó la matriz de compatibilidad en pub.dev antes de fijar la versión.
- **`prisma db push` sin `--accept-data-loss`** (ajuste #8). Se ejecutó sin la bandera y Prisma reportó sync limpio; en cualquier warning de data-loss habría parado y consultado.
- **`GET /ventas/mis` verificado que devuelve los 6 campos nuevos** (ajuste #5). El código usa `include` sin `select` restrictivo, así que Prisma retorna todos los campos escalares del modelo automáticamente. Confirmado con `curl`.
- **Atribución OSM visible** (ajuste #4). Cuando el reverse geocoding tiene éxito, `_PanelBanner` pinta bajo el mensaje verde la línea `© OpenStreetMap contributors — …` para cumplir con el ToS.

## 7. Siguiente paso sugerido

- Panel admin (**Paso 9** del roadmap) que consuma `GET /ventas`, `POST /pagos` y `POST /facturas`. Ese panel debería mostrar el `_DeliveryBlock` en cada venta pendiente para que el vendedor sepa exactamente adónde despachar.
- Cuando exista un endpoint `GET /clientes/mi-perfil`, se puede prellenar el `DeliveryAddressPanel` con la dirección del perfil (ahora empieza vacío intencionadamente porque `AuthController.currentUser` sólo expone el `Usuario`, no el `Cliente`).
