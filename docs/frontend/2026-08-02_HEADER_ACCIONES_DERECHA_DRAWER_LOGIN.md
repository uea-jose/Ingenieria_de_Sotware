# Header Publico - Acciones Derecha y Drawer de Login - 2026-08-02

## Objetivo

Redisenar el bloque superior derecho del header publico para que Favoritos, Carrito y Cuenta se vean como un sistema unificado de iconos modernos, compactos y consistentes.

## Archivos modificados

- `frontend/lib/widgets/layout/top_navigation.dart`
- `frontend/lib/widgets/layout/cart_nav_button.dart`
- `frontend/lib/widgets/layout/brand_mark.dart`

## Archivos creados

- `frontend/lib/widgets/layout/header_action_button.dart`
- `frontend/lib/widgets/layout/account_drawer.dart`

## Cambios aplicados

- Se reemplazaron botones rectangulares por icon buttons lineales con area tactil minima de 44 x 44 px.
- Se unifico el lenguaje visual de Favoritos, Carrito y Cuenta.
- El carrito conserva su contador real y lo muestra como badge circular superpuesto.
- La cuenta muestra un badge discreto para llamar la atencion sin saturar.
- Favoritos queda como acceso visual preparado, sin introducir una funcionalidad nueva.
- El login publico ahora abre un drawer lateral derecho tipo offcanvas.

## Drawer de cuenta

El panel lateral:

- entra desde la derecha;
- usa overlay oscuro;
- se cierra con boton X;
- se cierra con clic exterior;
- se cierra con Escape;
- ocupa entre 420 y 520 px en escritorio;
- ocupa el ancho completo en movil;
- incluye formulario visual de email y contrasena;
- deja claro que la conexion real del login publico queda para una etapa posterior.

## Funcionalidad conservada

- El carrito sigue llamando al flujo actual.
- El contador del carrito sigue usando `cartCount`.
- No se tocaron APIs, backend, base de datos ni servicios.
- No se conecto login publico nuevo.
- No se agregaron dependencias externas.

## Validacion

- Formato Dart aplicado.
- `dart analyze` ejecutado.
- Resultado: sin errores.

## Pendiente visual

Revisar en navegador y celular real:

- alineacion de los tres iconos;
- tamano del badge;
- apertura y cierre del drawer;
- que el header movil no se desborde;
- que el icono de cuenta sea suficientemente visible.
