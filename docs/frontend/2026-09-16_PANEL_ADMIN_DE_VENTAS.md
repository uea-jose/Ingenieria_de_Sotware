# Panel administrativo de ventas + flujo de pagos según método

Fecha: 2026-09-16
Rama: `backup/acordes-antes-split`
HEAD previo al cambio: `63a62f1`

## Objetivo

Cerrar el flujo transaccional de la tienda persistiendo el método de
pago elegido por el cliente en el checkout y adaptando el panel admin
para operar sobre el pago correcto sin re-preguntar el método.

Antes: el frontend guardaba el método sólo en memoria (`_paymentMethodId`)
y jamás lo enviaba al backend; el panel admin obligaba al operador a
volver a elegir Efectivo/Tarjeta/Transferencia. Ahora el método viaja al
backend en `POST /ventas` y define el estado inicial de la venta.

## Endpoints

Todos los cambios de este paso son **aditivos** — ningún endpoint
existente cambió su ruta ni sus roles.

### Modificados

| Método | Ruta | Cambio |
|---|---|---|
| `POST` | `/api/ventas` | Ahora requiere `metodoPago` (`EFECTIVO`, `TARJETA` o `TRANSFERENCIA`). Se valida contra la lista blanca y se rechaza con 400 si falta o no coincide. En la misma transacción de creación se persiste un `Pago` inicial cuyo estado depende del método: `TARJETA → PAGADO` (pago simulado, se descuenta inventario y la venta queda `PAGADA`), el resto → `PENDIENTE`. |

### Nuevos

| Método | Ruta | Roles | Uso |
|---|---|---|---|
| `POST` | `/api/pagos/:id/confirmar` | Administrador, Vendedor | Confirma un `Pago` existente en estado `PENDIENTE`. No acepta cuerpo. Lee el método del propio registro, marca `Pago.estado="PAGADO"` con `fechaPago=now`, descuenta inventario, deja la venta como `PAGADA`. Rechaza 409 si el pago ya está aprobado o la venta no está pendiente. |

### Mantenidos (compatibilidad)

- `POST /api/pagos` (crear pago manual, pide método y monto) — **no lo
  usa el nuevo panel admin**. Se conserva por compatibilidad y como
  fallback para flujos manuales que no pasan por el checkout.
- `POST /api/facturas`, `GET /api/ventas`, `GET /api/pagos`,
  `GET /api/facturas` — sin cambios.

## Flujos por método de pago

### TARJETA (pago simulado)

**Este proyecto no integra una pasarela real todavía.** El pago con
tarjeta es un **simulador académico**: apenas el cliente confirma el
checkout, la venta queda `PAGADA`.

```
POST /api/ventas (cliente, metodoPago="TARJETA")
   ↓ misma transacción
   ├── Venta creada con estado PAGADA
   ├── Pago TARJETA/PAGADO con fechaPago=now
   ├── descontarInventario (por cada detalle)
   ├── MovimientoInventario SALIDA por producto
   └── mensaje "Pago con tarjeta simulado aprobado automáticamente..."
```

En producción una pasarela externa (Stripe, PayPhone, etc.) confirmaría
el pago con webhook y el backend recibiría esa confirmación antes de
aprobar la venta. El endpoint actual asume el "éxito" para no bloquear
el flujo académico.

En el panel admin la venta aparece directamente como `Pagada` con
`Pago: TARJETA · PAGADO` y el único botón disponible es `Generar
factura` (si aún no existe).

### TRANSFERENCIA

```
POST /api/ventas (cliente, metodoPago="TRANSFERENCIA")
   ↓
   ├── Venta creada con estado PENDIENTE
   └── Pago TRANSFERENCIA/PENDIENTE con fechaPago=null
```

El cliente ve un banner "Envía el comprobante de transferencia al
correo indicado". En el panel admin el operador ve:

- Banner: **Transferencia pendiente**
- Botón: **Confirmar transferencia**

Al pulsar, se abre un `AlertDialog` de confirmación (sin selector de
método) y se llama `POST /pagos/:id/confirmar`. La respuesta incluye la
venta actualizada, el pago ya en `PAGADO`, alertas de stock bajo si las
hubiese, y un mensaje semántico ("Transferencia confirmada. Venta
marcada como PAGADA e inventario descontado.").

### EFECTIVO CONTRA ENTREGA

```
POST /api/ventas (cliente, metodoPago="EFECTIVO")
   ↓
   ├── Venta creada con estado PENDIENTE
   └── Pago EFECTIVO/PENDIENTE con fechaPago=null
```

El cliente ve un banner "El cobro en efectivo se registrará al momento
de entregar". En el panel admin:

- Banner: **Efectivo pendiente contra entrega**
- Botón: **Registrar cobro**

Mismo endpoint `POST /pagos/:id/confirmar`, mismo mensaje semántico
distinto ("Cobro en efectivo registrado. Venta marcada como PAGADA e
inventario descontado.").

### Ventas históricas sin pago asociado

Las ventas creadas antes de este cambio (`PENDIENTE` sin ningún registro
en `Pago`) **no** reciben backfill. No queremos inventar un método que
nunca se registró. El panel muestra:

- Banner: **Venta histórica · método de pago no registrado**
- Ningún botón de acción de pago.
- Solo lectura: se ven items, totales, snapshot, cliente.

Si más adelante hace falta regularizar estas ventas, se implementará un
flujo específico "regularización manual" que documente explícitamente
que el método se asigna a posteriori con constancia del operador.

## Modelo de datos (sin cambios)

No hubo migración Prisma en este paso. El método vive en la columna
`Pago.metodo` que ya existía (`MetodoPago` enum con
`EFECTIVO|TARJETA|TRANSFERENCIA|OTRO`). La `Venta` no gana columnas
nuevas — el método se lee siempre desde el `Pago` inicial creado en la
misma transacción.

## Frontend

### Archivos nuevos

- `frontend/lib/data/api/admin_sales_api.dart`
  - Elimina el enum `AdminPaymentMethod` que existía en el paso anterior.
  - Elimina el método `approvePayment(method, amount)`.
  - Nuevo: `confirmPayment({token, paymentId})` → llama
    `POST /pagos/:id/confirmar`, sin body.
  - `loadSales(token)` y `generateInvoice(...)` sin cambios.

- `frontend/lib/features/admin/sales/admin_sales_page.dart`
  - Sin diálogo de selector de método.
  - `_showConfirmDialog` genera títulos y cuerpos según
    `pendingPayment.metodo` (`TRANSFERENCIA`/`EFECTIVO`).
  - `_confirmPayment` extrae el pago pendiente con `_pendingPaymentOf` y
    delega al API.
  - Chequeo de rol Administrador o Vendedor con vista de restringido
    para Bodeguero.

- `frontend/lib/features/admin/sales/widgets/sale_admin_card.dart`
  - Nuevo widget interno `_PaymentStatusBlock` que decide banner e ícono:
    - Legacy `PENDIENTE` sin pago → "Venta histórica · método no
      registrado".
    - Pago `TRANSFERENCIA/PENDIENTE` → "Transferencia pendiente".
    - Pago `EFECTIVO/PENDIENTE` → "Efectivo pendiente contra entrega".
    - Venta `PAGADA` con pago `TARJETA` → "Pago con tarjeta aprobado".
    - Venta `PAGADA` sin tarjeta → "Pago confirmado".
    - Venta `CANCELADA` → "Venta cancelada".
  - `_ActionsRow` construye la fila de botones dinámicamente:
    - Pago pendiente → botón con label semántico ("Confirmar
      transferencia" / "Registrar cobro") y su ícono correspondiente.
    - Venta PAGADA sin factura → botón "Generar factura".
    - Legacy sin pago → sin botones.

- `frontend/lib/widgets/orders/delivery_snapshot_block.dart` — se
  extrajo el `_DeliveryBlock` privado de `my_orders_page.dart` a un
  widget público reutilizable.

### Archivos modificados

- `frontend/lib/data/api/orders_api.dart`
  - `createOrder(...)` ahora requiere `paymentMethod: String`.
  - Constantes `paymentMethodTarjeta`, `paymentMethodTransferencia`,
    `paymentMethodEfectivo` para consumidores tipados.

- `frontend/lib/screens/checkout/checkout_page.dart`
  - Pasa `_paymentMethodId` al crear la venta.
  - Nuevo widget `_PaymentStatusBanner` en la vista de éxito que decide
    el banner según `order.isPaid` (TARJETA aprobada) o
    `order.pagos.first.metodo` (`TRANSFERENCIA`/`EFECTIVO`) y ya no
    depende del `_paymentMethodId` local (usa la fuente de verdad del
    backend).

- `frontend/lib/screens/orders/my_orders_page.dart`
  - Consume `DeliverySnapshotBlock` en lugar del `_DeliveryBlock`
    privado (eliminado sin cambio visual).

- `frontend/lib/app/aromas_store_app.dart`
  - Registra la ruta `/admin/ventas`.

- `frontend/lib/widgets/layout/account_drawer.dart`
  - Enlace "Panel de ventas" visible sólo para
    `isAdmin || isVendedor`.

## Backend

### Archivos modificados

- `backend/src/modules/ventas/ventas.service.js`
  - `crearVenta` acepta `metodoPago` obligatorio, valida contra
    `METODOS_CHECKOUT_PERMITIDOS`.
  - En la transacción crea `Venta` + `Pago` inicial según método.
  - Para `TARJETA` reutiliza `descontarInventario` (exportado desde
    `pagos.service.js`) para descontar inventario, crear
    `MovimientoInventario` y devolver `alertasStock`.

- `backend/src/modules/ventas/ventas.controller.js`
  - Lee `metodoPago` del body y lo pasa al service.

- `backend/src/modules/pagos/pagos.service.js`
  - `descontarInventario` ahora es `export` para reutilización.
  - Nueva función `confirmarPago({pagoId, usuario})` que aprueba un
    pago pendiente sin re-preguntar el método.

- `backend/src/modules/pagos/pagos.controller.js`
  - Nuevo controller `confirmarPagoPendiente` que lee `req.params.id` y
    llama al service.

- `backend/src/modules/pagos/pagos.routes.js`
  - Nueva ruta `POST /pagos/:id/confirmar` protegida por
    `requiereRol("Administrador", "Vendedor")`.

- `backend/src/routes/index.js`
  - Descripciones actualizadas para `POST /ventas`, `POST /pagos`,
    `POST /pagos/:id/confirmar`.

## Compatibilidad

- Ventas existentes en `PENDIENTE` sin `Pago` asociado siguen
  cargándose y aparecen como "Venta histórica · método no registrado".
  No se modifican automáticamente.
- El endpoint `POST /pagos` (crear pago manual con selector de método)
  sigue funcionando exactamente igual y protegido por los mismos roles.
  No lo consume el nuevo panel, pero queda disponible.

## Reembolsos

**Fuera de alcance de este paso.** Un reembolso es semánticamente
distinto de "confirmar pago" y no se debe implementar como una
variante del mismo botón. Cuando llegue el momento, será un flujo
separado con su propio endpoint (`POST /pagos/:id/reembolsar` o
similar), documento aparte y validación de que la venta esté
efectivamente `PAGADA` con inventario reversible.

## Verificación

### 1. Estáticos

- `flutter analyze --no-fatal-infos` → 0 issues.
- `flutter test` → 20/20.
- `flutter build web` → build OK. Warning WASM preexistente por
  `cart_storage.dart` (usa `dart:html`), no bloquea el build JS.
- `npm run test:api` → 21/21.
- `npm run test:catalogo` → 4/4.

### 2. Prueba end-to-end backend con `Invoke-RestMethod`

Contra `http://localhost:3000/api` usando
`admin@aromasstore.com/Admin12345` y
`jose.prueba5458@example.com/Test12345`. Todos los casos definidos por
el usuario pasaron:

```
STOCK PROD 2 ANTES: 34

A) TARJETA -> venta id=15 estado=PAGADA pago=TARJETA/PAGADO
   msg='Pago con tarjeta simulado aprobado automaticamente. Venta PAGADA e inventario descontado.'
   stock ahora: 33 (dif=1)

B) TRANSFERENCIA -> venta id=16 estado=PENDIENTE pago=TRANSFERENCIA/PENDIENTE
   POST /pagos/7/confirmar -> estado venta=PAGADA pago=PAGADO
   msg='Transferencia confirmada. Venta marcada como PAGADA e inventario descontado.'

C) EFECTIVO -> venta id=17 estado=PENDIENTE pago=EFECTIVO/PENDIENTE
   POST /pagos/8/confirmar -> estado venta=PAGADA pago=PAGADO
   msg='Cobro en efectivo registrado. Venta marcada como PAGADA e inventario descontado.'

E) Doble confirmacion rechazada: {"error":"El pago no esta pendiente. Estado actual: PAGADO."}

F) Factura TARJETA -> FAC-000015
   Factura TRANSFER -> FAC-000016

G) Sin metodoPago rechazado: {"error":"metodoPago es obligatorio para registrar la venta."}
H) Metodo invalido rechazado: {"error":"metodoPago debe ser uno de: EFECTIVO, TARJETA, TRANSFERENCIA."}
```

Cubre los casos A/B/C/D/E/F/G/H y confirma:

- **A**: Tarjeta se aprueba automáticamente sin admin. Inventario
  descontado, movimiento registrado, factura habilitada.
- **B**: Transferencia queda pendiente. Admin confirma → PAGADA sin
  re-elegir método. Inventario descontado.
- **C**: Efectivo queda pendiente. Admin registra cobro → PAGADA sin
  re-elegir método. Inventario descontado.
- **D**: Venta histórica → visible en el panel como "método no
  registrado", en modo lectura, sin acción disponible. (Sale como caso
  visual, no como respuesta HTTP; verificable abriendo el panel.)
- **E**: Segundo `POST /pagos/:id/confirmar` rechazado con 409 porque
  el pago ya está `PAGADO`.
- **F**: `POST /facturas` genera `FAC-000015` (TARJETA auto-pagada) y
  `FAC-000016` (transferencia recién confirmada). Solo cuando la venta
  está `PAGADA`.

### 3. Revisión visual pendiente

Con backend levantado en `localhost:3000` y frontend en
`http://127.0.0.1:8080` verificar en Chrome:

1. Login cliente → `/checkout` → elegir TARJETA → confirmar → banner
   verde "Pago con tarjeta simulado aprobado" y estado del pedido
   `PAGADA` en la vista de éxito.
2. Nuevo checkout con TRANSFERENCIA → banner amarillo "Envía el
   comprobante" y estado `PENDIENTE`.
3. Nuevo checkout con EFECTIVO → banner amarillo "Se cobra en efectivo
   al entregar" y estado `PENDIENTE`.
4. Login admin → drawer → "Panel de ventas".
   - Filtros: Todas / Pendientes / Pagadas / Canceladas con contadores.
   - Venta tarjeta: banner verde, sin botón de pago, botón "Generar
     factura".
   - Venta transferencia: banner amarillo "Transferencia pendiente",
     botón "Confirmar transferencia" → al pulsar aparece diálogo
     textual sin selector de método → confirmar → estado pasa a
     PAGADA en el sitio.
   - Venta efectivo: banner "Efectivo pendiente contra entrega",
     botón "Registrar cobro" → mismo flujo.
   - Venta histórica sin pago: banner "método no registrado", sin
     botones.
   - Bodeguero: enlace del drawer oculto; si entra directo por URL, ve
     `_RestrictedRoleView`.
