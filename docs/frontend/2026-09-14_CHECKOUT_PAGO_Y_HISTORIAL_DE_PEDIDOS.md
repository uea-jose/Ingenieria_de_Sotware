# Paso 2 — Checkout real, historial de pedidos y flujo de venta pendiente

Fecha: 2026-09-14
Rama: `backup/acordes-antes-split`
Alcance: **frontend + backend** (pequeño: 3 archivos del módulo `ventas` para añadir un endpoint que el cliente logueado necesita para ver sus propios pedidos).

## Objetivo

Cerrar el flujo comprador:

1. El usuario agrega productos al carrito (ya existía).
2. Pulsa **Finalizar compra** → si no hay sesión, va a `/login`, se autentica y
   vuelve automáticamente a `/checkout`.
3. En `/checkout` revisa items, elige método de pago (tarjeta / transferencia
   / efectivo) y confirma.
4. El backend crea la venta en estado `PENDIENTE` (no descuenta inventario
   todavía; espera a que un admin registre el pago aprobado).
5. Se muestra la confirmación con el número de pedido y accesos a
   **Mis pedidos** o **Seguir comprando**.
6. `/mis-pedidos` lista todos los pedidos del cliente autenticado con
   estado, ítems, pagos registrados y factura si el pago ya fue aprobado.

El botón "Finalizar compra" en `CartPanel` deja de mostrar el snackbar
"El siguiente módulo será checkout y pedido." y **navega a la página real**.

## Endpoints consumidos

| Método | Ruta | Rol requerido | Uso |
|---|---|---|---|
| `POST` | `/ventas` | Cliente / Admin / Vendedor | Crea venta con `{items:[{productoId, cantidad}]}` en estado PENDIENTE |
| `GET`  | `/ventas/mis` (**nuevo**) | cualquier sesión | Lista las ventas del cliente asociado al token |
| `GET`  | `/ventas` | Admin / Vendedor | Todas las ventas (se usará en el panel admin del Paso 9) |

El backend resuelve el `clienteId` automáticamente cuando el rol del token
es `Cliente` — el frontend nunca envía IDs de otras entidades a menos que
esté logueado como staff.

## Cambio backend (mínimo)

Se agregó un endpoint para que un cliente autenticado pueda ver **sus**
pedidos. El endpoint existente `GET /ventas` sigue restringido a
`Administrador` y `Vendedor`, así que los clientes necesitaban una ruta
específica.

Tres archivos tocados en `backend/src/modules/ventas/`:

- `ventas.routes.js` — nueva ruta `GET /mis` con solo `requiereAutenticacion`
  (sin `requiereRol`, así admins también la pueden usar si quieren ver
  las suyas como cliente).
- `ventas.controller.js` — `listarMisVentas(req, res)` que delega en el
  service.
- `ventas.service.js` — `obtenerVentasDelCliente(usuario)` busca el cliente
  por `usuarioId` del token y retorna las ventas filtradas por
  `clienteId`.

Sin cambios en schema Prisma ni migraciones.

## Estructura nueva del frontend

```
frontend/lib/
├── data/api/
│   └── orders_api.dart                  (nuevo)
├── models/
│   ├── order.dart                       (nuevo)
│   ├── order_item.dart                  (nuevo)
│   ├── payment.dart                     (nuevo)
│   └── invoice.dart                     (nuevo)
├── screens/
│   ├── checkout/
│   │   └── checkout_page.dart           (nuevo)
│   └── orders/
│       └── my_orders_page.dart          (nuevo)
├── screens/account/account_page.dart    (modificado — link a /mis-pedidos)
├── screens/home/home_page.dart          (modificado — botón Finalizar navega)
├── widgets/layout/account_drawer.dart   (modificado — menu link real)
├── app/aromas_store_app.dart            (modificado — rutas + guards)
└── test/checkout_flow_test.dart         (nuevo — 3 tests)
```

## Modelos

- **`Order`**: id, clienteId, usuarioId, estado (`PENDIENTE | PAGADA |
  CANCELADA`), subtotal, impuesto, total, items[], pagos[], factura?,
  fechaCreacion, clienteNombre, clienteCorreo.
  - Getters: `isPending`, `isPaid`, `isCancelled`, `itemsCount`.
- **`OrderItem`**: id, productoId, cantidad, precioUnitario, total,
  productoNombre, productoImagenUrl, marca?, categoria?
  (aplanados desde el `producto` embebido).
- **`Payment`**: id, ventaId, metodo, estado, monto, fechaPago.
  - Getters: `isApproved`, `isPending`, `isFailed`.
- **`Invoice`**: id, ventaId, numeroFactura (`FAC-######`), nombreCliente,
  cedulaCliente?, subtotal, impuesto, total, fechaEmision.

Todos con `fromJson` que tolera nulls y arrays vacíos.

## `OrdersApi`

Cliente HTTP para las dos operaciones necesarias en el flujo cliente:

- `createOrder({token, items})` → `POST /ventas`. Devuelve
  `OrderCreationResult { order, mensaje, alertasStock[] }`. Las alertas
  de stock son el mensaje del backend cuando un producto queda con
  inventario bajo tras validar (usando `carrito.service.validarCarrito`).
- `loadMyOrders({token})` → `GET /ventas/mis`. Devuelve `List<Order>`.

El token se pasa explícitamente en cada llamada (viene del `AuthScope`).
Reutiliza `AuthException` del `AuthService` para que los mensajes de error
lleguen homogéneos al UI. Cliente `http.Client` inyectable para tests.

## `CheckoutPage`

Máquina de estados simple:

| Estado | Qué muestra |
|---|---|
| `form` (default) | Layout de 2 columnas ≥900 px: resumen + panel de pago |
| `submitting` | Botón "Confirmar" con spinner, botón deshabilitado |
| `success` | Card centrada con check verde, # de pedido, total, método, warning "pendiente de aprobación", botones "Ver mis pedidos" y "Seguir comprando" |

**Panel resumen (izquierda)**: cada ítem del carrito muestra marca,
nombre, `cantidad × precio` y subtotal por línea. Al final subtotal y
nota "Impuestos y ajustes finales se calculan al confirmar la venta"
(porque el backend calcula impuestos server-side y devuelve el total real
en la response).

**Panel de pago (derecha)**:

- **Datos del comprador**: nombre y correo del usuario en modo readonly
  (viene de `AuthScope.currentUser`).
  - Si el rol NO es `Cliente` (por ejemplo un admin logueado), se
    muestra un banner naranja avisando que "Tu rol no tiene un perfil de
    cliente asociado. Inicia sesión con una cuenta cliente para completar
    la compra." — el backend rechaza el `POST /ventas` en ese caso y
    mostraríamos el error si el usuario insiste.
- **Método de pago**: 3 tiles clickeables (Tarjeta / Transferencia /
  Efectivo). Cada tile con icono, título, descripción corta y un ícono
  visual de estado seleccionado. Se cambió `Radio` por `Icon` porque en
  Flutter 3.32+ `Radio.groupValue`/`onChanged` están deprecados fuera de
  un `RadioGroup`.
- **Total** grande en el color primario + nota "La venta queda pendiente
  hasta que un vendedor confirme el pago."
- Banner de error inline si el backend rechaza el request (mismo patrón
  visual que login/registro).
- Botón "Confirmar pedido" full-width.

**Al éxito**: `CartStorage.clear()` para vaciar el carrito local, se guarda
el `Order` recibido y se cambia a estado `success`. El usuario puede
navegar a `/mis-pedidos` o volver a `/`.

**Guard de ruta**: `/checkout` está envuelta en
`RequireAuth(child: CheckoutPage())`. Sin sesión → redirige a `/login`
con `arguments = '/checkout'`. Tras iniciar sesión el usuario aterriza
directamente en el checkout.

## `MyOrdersPage`

Lista de pedidos con `FutureBuilder<List<Order>>`. Estados:

- **Loading**: `LoadingView`.
- **Error**: `ErrorView` con botón retry.
- **Empty**: card "Aún no tienes pedidos" con botón a `/`.
- **Data**: encabezado con conteo + cards `ExpansionTile`, uno por
  pedido.

Cada card muestra:

- Header colapsado: `Pedido #NN`, subtitle `Total $X.XX`, chip de estado
  (`PENDIENTE` naranja / `PAGADA` verde / `CANCELADA` rojo) con icono.
- Expandido:
  - Lista de ítems con marca, nombre, `cantidad × precio`, subtotal.
  - Bloque totales (subtotal, impuestos, total emphasised).
  - Pagos registrados (uno por línea con icono según `isApproved` /
    `isPending` / `isFailed`, método, monto, fecha).
  - Factura si existe: bloque verde con `Icon(receipt_long)` + número de
    factura + total.

En el `AppBar` hay un botón "Actualizar" para relanzar el
`FutureBuilder` (útil cuando un admin acaba de aprobar el pago mientras
el cliente tiene la página abierta).

## Wire-up en el resto de la app

- `CartPanel.onCheckout`: el callback ahora llama `_startCheckout()`
  (validación de carrito), y **si valida OK** cierra el bottom sheet con
  `Navigator.pop()` y navega `pushNamed('/checkout')`. **Si valida mal**
  refresca el sheet para que el usuario vea los errores.
- `AccountPage`: el tile "Mis pedidos" ahora navega a `/mis-pedidos` en
  vez de mostrar snackbar de placeholder.
- `AccountDrawer`: el `_MenuTile` "Mis pedidos" cierra el drawer con
  `pop()` y navega a `/mis-pedidos`.
- `aromas_store_app.dart`: registradas 2 nuevas rutas:

```dart
'/checkout':    (context) => const RequireAuth(child: CheckoutPage()),
'/mis-pedidos': (context) => const RequireAuth(child: MyOrdersPage()),
```

Ninguna requiere `requireStaff`. Los admins también las pueden abrir,
pero si un admin no tiene perfil de cliente asociado, `POST /ventas`
devuelve 400 y ese error se muestra en el banner del formulario.

## Validaciones

| Comando | Resultado |
|---|---|
| `flutter analyze --no-fatal-infos` | **No issues found** |
| `flutter test` | **20/20 aprobados** (17 previos + 3 nuevos de checkout) |
| `flutter build web` | **Built build/web** en ≈82 s |
| Backend live con `Invoke-RestMethod` | Ver tabla abajo |

Backend contract verificado en vivo con Node/Prisma corriendo:

| Escenario | Resultado |
|---|---|
| `POST /auth/login` con `jose.prueba5458@example.com` | 200 → token + `usuario:{rol:'Cliente'}` |
| `GET /productos` | 200 → 6 productos con stock |
| `POST /ventas` con `Bearer` cliente + 2 items | 201 → venta id=4 estado `PENDIENTE` total 195.47 |
| `GET /ventas/mis` con `Bearer` cliente | 200 → 1 venta con detalles, sin pagos |
| `GET /ventas` con `Bearer` cliente | 403 (correcto — solo admin/vendedor) |

Los 3 tests nuevos de `checkout_flow_test.dart`:

1. `Order.fromJson` parsea una response PENDIENTE con detalles y cliente.
2. `Order.fromJson` parsea una response PAGADA con `pagos` (fechaPago
   inclusive) y `factura` embebida.
3. `MyOrdersPage` monta sin excepciones y muestra el AppBar con acción
   "Actualizar" incluso cuando el fetch todavía está en vuelo.

## Decisiones y descartes

- **`POST /pagos` desde el cliente — descartado**. El endpoint requiere
  rol Administrador/Vendedor porque descuenta inventario cuando
  `estado=PAGADO`. Permitirlo desde el frontend cliente sería un vector
  para vaciar inventario a voluntad. En un ecommerce real la pasarela
  externa firma el pago; aquí el pago queda `PENDIENTE` hasta que un
  admin lo apruebe (Paso 9).
- **Endpoint nuevo `/ventas/mis` — mínimo, no destructivo**. Preferido a
  modificar `GET /ventas` para aceptar Cliente porque la ruta genérica
  devuelve TODAS las ventas del sistema. `/mis` es explícito y siempre
  filtra por el cliente del token.
- **Checkout guest (sin login) — descartado**. El backend requiere token
  en `POST /ventas`. El `RequireAuth` guarda el intento y trae al
  usuario de vuelta al checkout después de loguearse, así que el
  redirect es transparente.
- **`Radio` widget — reemplazado por `Icon`**. Flutter 3.32+ deprecó
  `Radio.groupValue` fuera de un `RadioGroup`. El `_PaymentTile` ya es
  clickable via `InkWell` en todo su área; el widget `Radio` era
  redundante. Mostrar `radio_button_checked` / `radio_button_off` cumple
  la función visual sin dependencias deprecadas.
- **Impuestos no calculados en el frontend antes del submit**. El backend
  calcula impuesto/subtotal/total al validar el carrito. Mostrar "16%
  IVA" hard-codeado en el frontend duplicaría lógica y podría divergir.
  La página muestra "Subtotal estimado" antes y el total REAL después
  del `POST /ventas`.

## Próximo paso (Paso 3)

Ya está la base para varios flujos:

- **Panel admin de ventas y pagos** (`Paso 9`): pantalla `/admin/ventas`
  con la lista de todas las ventas + botón "Registrar pago" que llama
  `POST /pagos` con estado PAGADO. Después del pago el cliente ve su
  venta en `PAGADA` y aparece la factura en `/mis-pedidos`.
- **Favoritos** (`Paso 6`): más pequeño y no depende de estos flujos.
  Podría hacerse en paralelo.
- **Promociones en home** (`Paso 7`): también independiente.

Recomiendo seguir con **Favoritos** por ser el más barato y visible al
cliente, o **Panel admin de ventas** para cerrar el ciclo completo del
ecommerce end-to-end.
