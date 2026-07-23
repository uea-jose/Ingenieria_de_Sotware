# Documentacion de API - Aromas Store

Proyecto: Aromas Store  
Tipo: API REST  
Backend: Node.js + Express  
Base de datos: PostgreSQL  
ORM: Prisma  
Autenticacion: JWT  
Version: 1.0.0

## 1. Objetivo

Esta documentacion describe los puntos de conexion principales de la API REST de Aromas Store. La API permite gestionar catalogo de productos, marcas, categorias, clientes, ventas, pagos, inventario, facturas y promociones.

La documentacion sirve como referencia para:

- Integracion con el frontend Flutter Web.
- Pruebas con Thunder Client, Postman o Swagger.
- Evidencia academica del diseno e implementacion de la API.
- Mantenimiento futuro del backend.

## 2. URL base

Servidor local:

```txt
http://localhost:3000
```

Prefijo general de la API:

```txt
http://localhost:3000/api
```

## 3. Documentacion visual Swagger

Para abrir Swagger UI:

```txt
http://localhost:3000/api/docs
```

Para ver la especificacion OpenAPI en JSON:

```txt
http://localhost:3000/api/docs.json
```

Comando para levantar el backend:

```powershell
cd C:\Users\Jose\Documents\proyectospERFUMES\aromas-store\backend
npm run dev
```

## 4. Autenticacion

Los endpoints privados usan token JWT.

Para iniciar sesion:

```http
POST /api/auth/login
```

Cuerpo JSON:

```json
{
  "correo": "admin@aromasstore.com",
  "contrasena": "Admin12345"
}
```

Respuesta esperada:

```json
{
  "token": "TOKEN_JWT",
  "usuario": {
    "id": 1,
    "correo": "admin@aromasstore.com",
    "nombres": "Administrador",
    "apellidos": "Aromas Store",
    "rol": "Administrador"
  }
}
```

Para consumir rutas protegidas se debe enviar el token en Headers:

```txt
Authorization: Bearer TOKEN_JWT
```

## 5. Roles del sistema

| Rol | Descripcion |
|---|---|
| Administrador | Gestiona usuarios, catalogo, inventario, ventas, pagos, facturas, promociones y reportes. |
| Vendedor | Registra clientes, ventas, pagos, facturas, productos, categorias, marcas y promociones. |
| Bodeguero | Gestiona inventario, stock, alertas y movimientos. |
| Cliente | Puede registrarse, iniciar sesion y crear ventas desde el carrito. |

## 6. Endpoints de sistema

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| GET | `/api` | Lista los endpoints disponibles de la API. | Publico |
| GET | `/api/health` | Verifica si la API esta activa. | Publico |
| GET | `/api/docs` | Abre Swagger UI. | Publico |
| GET | `/api/docs.json` | Devuelve especificacion OpenAPI. | Publico |

## 7. Endpoints de autenticacion

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| POST | `/api/auth/login` | Inicia sesion y genera token JWT. | Publico |
| GET | `/api/auth/me` | Devuelve el usuario autenticado. | JWT |

Ejemplo para consultar perfil:

```http
GET /api/auth/me
Authorization: Bearer TOKEN_JWT
```

## 8. Endpoints de clientes

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| POST | `/api/clientes/registro` | Registra un cliente comprador. | Publico |
| GET | `/api/clientes` | Lista clientes registrados. | Administrador, Vendedor |

Ejemplo de registro de cliente:

```json
{
  "nombres": "Cliente",
  "apellidos": "Prueba",
  "correo": "cliente@aromasstore.com",
  "contrasena": "Cliente12345",
  "telefono": "0999999999",
  "cedula": "1723456789",
  "direccion": "Av. Amazonas",
  "ciudad": "Quito"
}
```

## 9. Endpoints de catalogo

### Productos

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| GET | `/api/productos` | Lista productos con marca, categoria e inventario. | Publico |
| GET | `/api/productos/:id` | Consulta un producto por ID. | Publico |
| POST | `/api/productos` | Crea un producto con inventario inicial. | Administrador, Vendedor |
| PUT | `/api/productos/:id` | Actualiza producto e inventario. | Administrador, Vendedor |
| PATCH | `/api/productos/:id/estado` | Activa o desactiva un producto. | Administrador, Vendedor |

Filtros disponibles:

```txt
/api/productos?nombre=vanilla
/api/productos?marcaId=2
/api/productos?categoriaId=1
/api/productos?precioMin=50&precioMax=70
/api/productos?activo=true
```

Ejemplo de creacion:

```json
{
  "nombre": "Royal Vanilla",
  "codigo": "AS-PERF-001",
  "descripcion": "Perfume con notas de vainilla, madera y almizcle.",
  "precio": 59.99,
  "volumenMl": 100,
  "imagenUrl": null,
  "categoriaId": 1,
  "marcaId": 2,
  "stock": 25,
  "stockMinimo": 5,
  "ubicacion": "Bodega principal"
}
```

### Categorias

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| GET | `/api/categorias` | Lista categorias. | Publico |
| GET | `/api/categorias/:id` | Consulta una categoria por ID. | Publico |
| POST | `/api/categorias` | Crea una categoria. | Administrador, Vendedor |
| PUT | `/api/categorias/:id` | Actualiza una categoria. | Administrador, Vendedor |
| PATCH | `/api/categorias/:id/estado` | Activa o desactiva una categoria. | Administrador, Vendedor |

Ejemplo:

```json
{
  "nombre": "Perfumes",
  "descripcion": "Fragancias personales en presentacion liquida.",
  "activo": true
}
```

### Marcas

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| GET | `/api/marcas` | Lista marcas o casas fabricantes. | Publico |
| GET | `/api/marcas/:id` | Consulta una marca por ID. | Publico |
| POST | `/api/marcas` | Crea una marca. | Administrador, Vendedor |
| PUT | `/api/marcas/:id` | Actualiza una marca. | Administrador, Vendedor |
| PATCH | `/api/marcas/:id/estado` | Activa o desactiva una marca. | Administrador, Vendedor |

Ejemplo:

```json
{
  "nombre": "Carolina Herrera",
  "paisOrigen": "Estados Unidos",
  "descripcion": "Casa fabricante de fragancias.",
  "activo": true
}
```

## 10. Endpoints de carrito

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| POST | `/api/carrito/validar` | Valida stock, calcula subtotal, IVA 15% y total. | Publico |

Ejemplo:

```json
{
  "items": [
    {
      "productoId": 1,
      "cantidad": 2
    }
  ]
}
```

Respuesta esperada:

```json
{
  "valido": true,
  "subtotal": 119.98,
  "impuesto": 18,
  "total": 137.98,
  "porcentajeImpuesto": 0.15,
  "alertasStock": [],
  "errores": [],
  "items": []
}
```

## 11. Endpoints de ventas

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| POST | `/api/ventas` | Crea una venta pendiente desde un carrito validado. | Administrador, Vendedor, Cliente |
| GET | `/api/ventas` | Lista ventas registradas. | Administrador, Vendedor |

Ejemplo:

```json
{
  "clienteId": 1,
  "items": [
    {
      "productoId": 1,
      "cantidad": 1
    }
  ]
}
```

Regla importante:

- La venta se crea en estado `PENDIENTE`.
- El inventario se descuenta cuando el pago queda en estado `PAGADO`.

## 12. Endpoints de pagos

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| POST | `/api/pagos` | Registra pago simulado. | Administrador, Vendedor |
| GET | `/api/pagos` | Lista pagos registrados. | Administrador, Vendedor |

Ejemplo:

```json
{
  "ventaId": 3,
  "metodo": "EFECTIVO",
  "estado": "PAGADO",
  "monto": 68.99,
  "referencia": "PAGO-001"
}
```

Regla importante:

- Si el pago queda `PAGADO`, la venta pasa a `PAGADA`.
- El inventario se descuenta automaticamente.
- Se registra un movimiento de inventario tipo `SALIDA`.

## 13. Endpoints de inventario

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| GET | `/api/inventario` | Lista stock actual. | Administrador, Bodeguero |
| GET | `/api/inventario/alertas` | Lista productos con stock bajo. | Administrador, Bodeguero |
| GET | `/api/inventario/movimientos` | Lista movimientos de inventario. | Administrador, Bodeguero |
| POST | `/api/inventario/movimientos` | Registra entrada, salida o ajuste. | Administrador, Bodeguero |

Ejemplo de ajuste:

```json
{
  "productoId": 4,
  "tipo": "AJUSTE",
  "cantidad": 2,
  "motivo": "Prueba de alerta de stock bajo"
}
```

Tipos permitidos:

```txt
ENTRADA
SALIDA
AJUSTE
```

Regla de stock:

- El sistema genera alerta cuando el stock queda menor que 3 unidades.
- Tambien compara el stock contra el stock minimo del producto.

## 14. Endpoints de facturas

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| POST | `/api/facturas` | Genera factura para una venta pagada. | Administrador, Vendedor |
| GET | `/api/facturas` | Lista facturas registradas. | Administrador, Vendedor |
| GET | `/api/facturas/:id` | Consulta una factura por ID. | Administrador, Vendedor |

Ejemplo:

```json
{
  "ventaId": 3
}
```

Reglas:

- Solo se factura una venta pagada.
- Una venta no puede tener facturas duplicadas.
- El numero de factura se genera automaticamente.

## 15. Endpoints de promociones

| Metodo | Ruta | Descripcion | Seguridad |
|---|---|---|---|
| GET | `/api/promociones` | Lista promociones registradas. | Publico |
| GET | `/api/promociones/:id` | Consulta una promocion por ID. | Publico |
| POST | `/api/promociones` | Crea una promocion. | Administrador, Vendedor |
| PUT | `/api/promociones/:id` | Actualiza una promocion. | Administrador, Vendedor |
| PATCH | `/api/promociones/:id/estado` | Activa o desactiva una promocion. | Administrador, Vendedor |

Ejemplo:

```json
{
  "productoId": 1,
  "nombre": "Promo verano",
  "descripcion": "10% de descuento en Royal Vanilla",
  "tipo": "PORCENTAJE",
  "valor": 10,
  "fechaInicio": "2026-07-08T00:00:00.000Z",
  "fechaFin": "2026-07-31T23:59:59.000Z",
  "activo": true
}
```

Tipos permitidos:

```txt
PORCENTAJE
MONTO
```

## 16. Codigos de respuesta comunes

| Codigo | Significado |
|---|---|
| 200 | Solicitud procesada correctamente. |
| 201 | Recurso creado correctamente. |
| 400 | Datos invalidos o incompletos. |
| 401 | Token no enviado, invalido o expirado. |
| 403 | Usuario sin permisos suficientes. |
| 404 | Recurso no encontrado. |
| 500 | Error interno del servidor. |

## 17. Prueba rapida del backend

Para validar los endpoints principales:

```powershell
cd C:\Users\Jose\Documents\proyectospERFUMES\aromas-store\backend
npm run test:api
```

Resultado esperado:

```txt
Resultado: 17/17 pruebas correctas.
```

## 18. Observaciones de mantenimiento

- Si se agrega una nueva ruta, debe actualizarse Swagger.
- Si se agrega un nuevo modulo, debe documentarse en este archivo.
- Si cambia un cuerpo JSON, debe actualizarse el ejemplo correspondiente.
- La bitacora debe registrar cada cambio importante con su RF o RNF.
