# Diseno Tecnico de Auditoria y Logs

Proyecto: Aromas Store  
Fecha: 2026-07-22  
Estado: Diseno tecnico previo a implementacion

## Objetivo

Definir como Aromas Store podria guardar y consultar la traza de las operaciones realizadas contra el backend, sin redisenar los endpoints actuales.

La meta es que cada llamada importante a la API pueda verse despues en una tabla similar a:

| timestamp | path | metodo | datoIngreso | datoRespuesta | TraceId | GUIDSESION |
|---|---|---|---|---|---|---|
| fecha | `/api/carrito/validar` | POST | JSON recibido | JSON respondido | traza unica | sesion usuario |

## Alcance

Este diseno no cambia todavia:

- rutas existentes;
- logica de negocio;
- frontend;
- base de datos actual;
- respuestas actuales de la API.

Solo define la capa futura para registrar auditoria y trazas.

## Identificadores base

| Campo | Uso |
|---|---|
| GUIDSESION | Agrupa varias acciones realizadas por un usuario durante una misma sesion. |
| TraceId | Identifica una accion o llamada especifica dentro de una sesion. |

Ejemplo:

```txt
GUIDSESION: e45ff230-a42e-4569-9af4-57b4a1a1e388
  TraceId 1: POST /api/auth/login
  TraceId 2: GET /api/productos
  TraceId 3: POST /api/carrito/validar
  TraceId 4: POST /api/ventas
  TraceId 5: POST /api/pagos
```

## Tabla propuesta

Nombre sugerido:

```txt
auditoria_logs
```

Columnas recomendadas para Aromas Store:

| Columna | Tipo sugerido | Descripcion |
|---|---|---|
| id | entero autoincremental | Identificador interno del registro. |
| timestamp | fecha/hora | Momento exacto del evento. |
| path | texto | Ruta invocada, por ejemplo `/api/carrito/validar`. |
| metodo | texto | Metodo HTTP: GET, POST, PUT, PATCH o DELETE. |
| datoIngreso | JSON/texto | Request recibido. |
| datoRespuesta | JSON/texto | Response enviado. |
| TraceId | texto | Identificador unico de la accion. |
| GUIDSESION | texto | Identificador de la sesion del usuario. |
| usuarioId | entero opcional | Usuario autenticado, si existe. |
| clienteId | entero opcional | Cliente relacionado con carrito, venta o factura. |
| ventaId | entero opcional | Venta relacionada con pago o factura. |
| productoId | entero opcional | Producto principal relacionado cuando aplique. |
| estadoHttp | entero | Codigo HTTP de respuesta. |
| duracionMs | entero | Tiempo de procesamiento. |
| resultado | texto | OK, ERROR_NEGOCIO o ERROR_TECNICO. |
| codigoRespuesta | texto opcional | Codigo funcional o tecnico de respuesta. |
| mensajeRespuesta | texto | Mensaje corto para diagnostico o reporte. |

## Adaptacion al dominio de Aromas Store

Este diseno toma como referencia sistemas transaccionales profesionales, pero no copia campos que no pertenecen a una tienda de perfumes.

No se usaran campos como:

- CodigoAgencia;
- CodigoCentro;
- CodigoMedioInvocacion;
- HashMobil;
- Comision;
- CuentaOrigen.

En Aromas Store los campos utiles para trazabilidad y reportes son:

| Campo | Uso en el proyecto |
|---|---|
| usuarioId | Saber que usuario interno o cliente autenticado ejecuto la accion. |
| clienteId | Relacionar acciones con el cliente comprador. |
| ventaId | Seguir el ciclo de una venta desde creacion hasta pago/factura. |
| productoId | Analizar acciones asociadas a un producto. |
| codigoRespuesta | Clasificar OK, validacion o error. |
| mensajeRespuesta | Mostrar mensajes claros en reportes. |
| datoIngreso | Revisar el JSON recibido por la API. |
| datoRespuesta | Revisar el JSON devuelto por la API. |

## Ejemplo de registro

```json
{
  "timestamp": "2026-07-22T23:10:15-05:00",
  "path": "/api/carrito/validar",
  "metodo": "POST",
  "datoIngreso": {
    "Auditoria": {
      "GUIDSESION": "e45ff230-a42e-4569-9af4-57b4a1a1e388",
      "TraceId": "952b76601624b3de0b8d83a616c08d42",
      "Usuario": "GENERICO",
      "IpCliente": "127.0.0.1"
    },
    "Datos": {
      "items": [
        {
          "productoId": 1,
          "cantidad": 2
        }
      ]
    }
  },
  "datoRespuesta": {
    "Respuesta": {
      "Codigo": "00000",
      "Mensaje": "Operacion procesada correctamente",
      "OperacionProcesada": true
    }
  },
  "TraceId": "952b76601624b3de0b8d83a616c08d42",
  "GUIDSESION": "e45ff230-a42e-4569-9af4-57b4a1a1e388",
  "usuarioId": null,
  "clienteId": null,
  "ventaId": null,
  "productoId": 1,
  "estadoHttp": 200,
  "duracionMs": 84,
  "resultado": "OK",
  "codigoRespuesta": "00000",
  "mensajeRespuesta": "Carrito validado correctamente"
}
```

Ejemplo para una venta:

```json
{
  "timestamp": "2026-07-22T23:11:02-05:00",
  "path": "/api/ventas",
  "metodo": "POST",
  "TraceId": "0bd496d98bf2e2d7c7b4c367527d02c7",
  "GUIDSESION": "e45ff230-a42e-4569-9af4-57b4a1a1e388",
  "usuarioId": 1,
  "clienteId": 3,
  "ventaId": 15,
  "productoId": null,
  "estadoHttp": 201,
  "duracionMs": 126,
  "resultado": "OK",
  "codigoRespuesta": "00000",
  "mensajeRespuesta": "Venta creada correctamente"
}
```

## Middleware propuesto

La implementacion futura deberia usar un middleware de Express que se ejecute alrededor de las rutas.

Responsabilidades:

- leer `GUIDSESION` si viene en el request;
- generar `GUIDSESION` si no viene;
- generar un `TraceId` por cada request;
- capturar `path`, `metodo`, `datoIngreso`, `datoRespuesta`;
- medir duracion;
- guardar el resultado;
- no bloquear la respuesta al usuario si falla el registro del log.

## Endpoints que se deberian auditar primero

Prioridad alta:

| Endpoint | Motivo |
|---|---|
| `POST /api/auth/login` | Seguridad e inicio de sesion. |
| `GET /api/auth/me` | Validacion de usuario autenticado. |
| `POST /api/carrito/validar` | Validacion previa a compra. |
| `POST /api/ventas` | Creacion de transaccion comercial. |
| `POST /api/pagos` | Registro de pago. |
| `POST /api/facturas` | Generacion de documento de venta. |
| `POST /api/inventario/movimientos` | Cambios sensibles de stock. |

Prioridad media:

| Endpoint | Motivo |
|---|---|
| `GET /api/productos` | Consulta publica de catalogo. |
| `POST /api/productos` | Gestion administrativa. |
| `PUT /api/productos/:id` | Modificacion administrativa. |
| `PATCH /api/productos/:id/estado` | Activacion o desactivacion. |

## Datos que no deben guardarse

Por seguridad, la auditoria no debe almacenar:

- contrasenas;
- tokens JWT completos;
- secretos de configuracion;
- cabeceras sensibles;
- datos de tarjetas;
- informacion personal innecesaria.

Si aparece un campo sensible, debe guardarse oculto:

```json
{
  "password": "***",
  "token": "***"
}
```

## Endpoints futuros para consultar auditoria

Cuando se implemente, se recomienda exponer consultas solo para usuarios internos autorizados.

| Metodo | Ruta futura | Uso |
|---|---|---|
| GET | `/api/auditoria/logs` | Listar registros recientes. |
| GET | `/api/auditoria/logs?GUIDSESION=...` | Ver toda una sesion. |
| GET | `/api/auditoria/logs?TraceId=...` | Ver una accion especifica. |
| GET | `/api/auditoria/logs?usuarioId=...` | Buscar acciones por usuario. |
| GET | `/api/auditoria/logs?clienteId=...` | Buscar acciones por cliente. |
| GET | `/api/auditoria/logs?ventaId=...` | Seguir una venta completa. |
| GET | `/api/auditoria/logs?productoId=...` | Buscar acciones sobre un producto. |
| GET | `/api/auditoria/logs?path=/api/pagos` | Filtrar por endpoint. |

## Consulta esperada

Ejemplo de vista tecnica:

| timestamp | path | metodo | datoIngreso | datoRespuesta | TraceId | GUIDSESION |
|---|---|---|---|---|---|---|
| 2026-07-22 23:10:15 | `/api/carrito/validar` | POST | JSON | JSON | `952b...8d42` | `e45f...e388` |
| 2026-07-22 23:11:02 | `/api/ventas` | POST | JSON | JSON | `0bd4...02c7` | `e45f...e388` |
| 2026-07-22 23:12:30 | `/api/pagos` | POST | JSON | JSON | `fa8a...d5c6` | `e45f...e388` |

Ejemplo de vista para reportes:

| timestamp | path | usuarioId | clienteId | ventaId | productoId | codigoRespuesta | mensajeRespuesta |
|---|---|---:|---:|---:|---:|---|---|
| 2026-07-22 23:10:15 | `/api/carrito/validar` |  |  |  | 1 | `00000` | Carrito validado correctamente |
| 2026-07-22 23:11:02 | `/api/ventas` | 1 | 3 | 15 |  | `00000` | Venta creada correctamente |
| 2026-07-22 23:12:30 | `/api/pagos` | 1 | 3 | 15 |  | `00000` | Pago registrado correctamente |

## Orden recomendado de implementacion

1. Crear modelo Prisma `auditoria_logs`.
2. Crear migracion de base de datos.
3. Crear servicio backend para guardar logs.
4. Crear middleware de auditoria.
5. Aplicarlo primero a endpoints criticos.
6. Ocultar campos sensibles antes de guardar.
7. Crear endpoints internos de consulta.
8. Probar login, carrito, ventas, pagos y facturas.
9. Documentar ejemplos reales en `docs/backend/API_DOCUMENTACION.md`.

## Pruebas recomendadas

| Prueba | Resultado esperado |
|---|---|
| Request sin GUIDSESION | Backend genera uno nuevo. |
| Request con GUIDSESION | Backend conserva el mismo. |
| Varias llamadas de una sesion | Comparten GUIDSESION y tienen TraceId distinto. |
| Error de negocio | Se registra resultado `ERROR_NEGOCIO`. |
| Error tecnico | Se registra resultado `ERROR_TECNICO`. |
| Password en login | Se guarda oculto como `***`. |
| Consulta por TraceId | Devuelve la accion exacta. |
| Consulta por GUIDSESION | Devuelve todas las acciones de la sesion. |

## Decision actual

Este documento solo define el diseno tecnico.

La implementacion debe hacerse despues, de forma controlada, empezando por backend y sin afectar el frontend actual.
