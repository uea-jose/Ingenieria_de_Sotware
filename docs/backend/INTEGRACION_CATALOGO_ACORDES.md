# Integración del catálogo de acordes

## Decisión final

El catálogo aromático forma parte del backend principal de Aromas Store:

```text
Flutter -> Express -> Prisma -> PostgreSQL
```

No se desplegará un segundo backend Next/Supabase para este módulo. El proyecto
`aromas-store-catalogo` se conserva como referencia de análisis y prototipo.

## Integración sin romper funciones existentes

- `Marca` y `Producto` siguen siendo las entidades existentes.
- Los identificadores continúan siendo enteros.
- Inventario, carrito, ventas, pagos y promociones no cambian.
- `Producto` puede asociarse opcionalmente con una `ReferenciaPerfume`.
- El perfil maestro vive en `ReferenciaPerfumeAcorde`.
- La copia editable vive en `ProductoAcorde`.
- Editar un producto nunca modifica el perfil maestro.

## Ordenamiento del editor

Al guardar el perfil editable:

1. Se valida que cada intensidad esté entre 1 y 100.
2. Se ordena por intensidad descendente.
3. En empates se conserva el orden recibido desde la interfaz.
4. `ordenVisual` se recalcula consecutivamente desde 1.
5. La base impide acordes y órdenes repetidos.

La interfaz Flutter debe aplicar el mismo orden inmediatamente durante el
arrastre. El backend vuelve a validarlo al guardar.

## Endpoints

```text
GET  /api/acordes
GET  /api/marcas/:id/referencias
GET  /api/referencias/:id
GET  /api/referencias/:id/acordes
GET  /api/productos/:id/acordes
PUT  /api/productos/:id/acordes
POST /api/productos/:id/restaurar-acordes
```

Las escrituras requieren el JWT existente y rol `Administrador` o `Vendedor`.

## Creación de un producto basado en una referencia

El cuerpo habitual de `POST /api/productos` admite `referenciaId`. Cuando se
envía:

1. se valida que la referencia maestra exista y esté activa;
2. se crea el producto y su inventario;
3. se copia el perfil maestro a `productos_acordes`;
4. las operaciones ocurren dentro de una transacción.

La referencia no puede reemplazarse posteriormente por otra. Sí se puede
editar libremente la copia del producto.

La marca comercial del producto puede ser diferente de la casa de la
referencia original. Esto permite productos propios o contratipos basados en
una fragancia de referencia.
