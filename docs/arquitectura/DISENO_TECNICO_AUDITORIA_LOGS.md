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

Columnas recomendadas:

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
| identificacion | texto opcional | Identificacion del cliente o usuario cuando aplique. |
| estadoHttp | entero | Codigo HTTP de respuesta. |
| duracionMs | entero | Tiempo de procesamiento. |
| resultado | texto | OK, ERROR_NEGOCIO o ERROR_TECNICO. |
| mensaje | texto | Mensaje corto para diagnostico. |

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
  "estadoHttp": 200,
  "duracionMs": 84,
  "resultado": "OK",
  "mensaje": "Carrito validado correctamente"
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
| GET | `/api/auditoria/logs?identificacion=...` | Buscar acciones por cliente o usuario. |
| GET | `/api/auditoria/logs?path=/api/pagos` | Filtrar por endpoint. |

## Consulta esperada

Ejemplo de vista o resultado:

| timestamp | path | metodo | datoIngreso | datoRespuesta | TraceId | GUIDSESION |
|---|---|---|---|---|---|---|
| 2026-07-22 23:10:15 | `/api/carrito/validar` | POST | JSON | JSON | `952b...8d42` | `e45f...e388` |
| 2026-07-22 23:11:02 | `/api/ventas` | POST | JSON | JSON | `0bd4...02c7` | `e45f...e388` |
| 2026-07-22 23:12:30 | `/api/pagos` | POST | JSON | JSON | `fa8a...d5c6` | `e45f...e388` |

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
