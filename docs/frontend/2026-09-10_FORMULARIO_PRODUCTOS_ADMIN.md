# Formulario de productos en el editor

Se agregaron Ingresar perfume y Editar datos del perfume en /admin/acordes.
El formulario usa POST /productos y PUT /productos/:id con el token de la sesion.
Campos: nombre, codigo, precio, unidades, volumen, URL de imagen, descripcion,
marca, categoria y estado activo. Los errores del servidor conservan el formulario.
La seleccion de una referencia local propone nombre y marca al crear el producto.
Los acordes siguen usando Aplicar perfil y Guardar perfil; no se modifica el catalogo maestro.
Editar datos comerciales conserva el borrador de acordes.

Se agrego Bodeguero a los permisos de las cinco rutas de escritura de productos,
manteniendo los roles Administrador y Vendedor y la autenticacion existente.
No se crean usuarios ni se cambian roles de cuentas existentes.

Verificacion: nueve pruebas existentes y dos pruebas nuevas del formulario aprobadas.
Las nuevas verifican edicion con API simulada, validacion de precio y ausencia de
overflow en 390 y 1000 px. Analisis Dart sin incidencias y sintaxis de rutas Node valida.
Pendiente: comprobar escritura con base de datos real y una cuenta Bodeguero.
El formulario recibe una URL de imagen; no incluye carga de archivos.
