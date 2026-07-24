# Pruebas del Backend Aromas Store

## Objetivo

Validar que la API REST de Aromas Store responda correctamente antes de iniciar el frontend Flutter Web.

## Alcance

Estas pruebas verifican:

- Disponibilidad del servidor.
- Documentacion Swagger.
- Login con JWT.
- Acceso a endpoints publicos.
- Acceso a endpoints protegidos con token.
- Consulta de catalogo.
- Validacion de carrito.
- Consulta de inventario, ventas, pagos, facturas y promociones.
- Consulta protegida de logs de auditoria.

## Requisitos previos

1. PostgreSQL debe estar activo con Docker.
2. El backend debe estar levantado.
3. Deben existir los datos semilla del proyecto.

Credenciales de prueba:

```txt
Correo: admin@aromasstore.com
Contrasena: Admin12345
Rol: Administrador
```

## Comandos de ejecucion

En una terminal:

```powershell
cd C:\Users\Jose\Documents\proyectospERFUMES\aromas-store\backend
npm run dev
```

En otra terminal:

```powershell
cd C:\Users\Jose\Documents\proyectospERFUMES\aromas-store\backend
npm run test:api
```

## Resultado esperado

El comando debe mostrar las comprobaciones con estado `OK` y un resumen similar a:

```txt
Resultado: 18/18 pruebas correctas.
```

## Rutas incluidas en la prueba

| Metodo | Ruta | Validacion |
|---|---|---|
| GET | `/api/health` | API activa |
| GET | `/api` | Indice de endpoints |
| GET | `/api/docs.json` | Swagger/OpenAPI disponible |
| POST | `/api/auth/login` | Generacion de token JWT |
| GET | `/api/auth/me` | Token valido |
| GET | `/api/auditoria/logs` | Auditoria protegida para Administrador |
| GET | `/api/productos` | Catalogo disponible |
| GET | `/api/categorias` | Categorias disponibles |
| GET | `/api/marcas` | Marcas disponibles |
| GET | `/api/promociones` | Promociones disponibles |
| POST | `/api/carrito/validar` | Validacion de carrito |
| GET | `/api/clientes` | Endpoint protegido |
| GET | `/api/ventas` | Endpoint protegido |
| GET | `/api/pagos` | Endpoint protegido |
| GET | `/api/inventario` | Endpoint protegido |
| GET | `/api/inventario/alertas` | Alertas de stock |
| GET | `/api/inventario/movimientos` | Historial de movimientos |
| GET | `/api/facturas` | Facturas disponibles |

## Observacion

Esta es una prueba de humo. No reemplaza pruebas unitarias ni pruebas completas de negocio, pero sirve como evidencia rapida de que el backend esta integrado y operativo.
