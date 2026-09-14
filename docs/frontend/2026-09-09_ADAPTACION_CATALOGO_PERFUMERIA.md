# Adaptación del catálogo de perfumería a AromaStore

Fecha: 2026-09-09
Rama: backup/acordes-antes-split

## Objetivo

Aprovechar el catálogo de aromas-store-catalogo conservando la aplicación Flutter, los perfiles existentes, la API, autenticación, carrito y guardado de AromaStore. Incorporar imágenes, contenedores con bordes y vista previa a la izquierda, sin mostrar cifras de intensidad ni recuperar listas que tapen las barras.

## Implementado

- Ruta pública /#/catalogo-perfumeria con 634 referencias y sus imágenes locales, procedentes de data/catalog-admin.json y public del proyecto de referencia.
- Acceso desde Referencias en la navegación de escritorio y Catálogo de perfumería en el menú móvil.
- Búsqueda por perfume, casa, alias comercial y alias de casa, ignorando mayúsculas y acentos.
- Filtros combinables por género y presencia de acorde. Las referencias pendientes no aparecen al filtrar por acorde.
- Ficha de referencia con imagen, barras sin números, alias y procedencia del PDF.
- Se conservan los estados del origen: 30 perfiles marcados approved y 604 pending_review. No se inventan acordes para los pendientes.
- Editor con contenedores de bordes redondeados; vista previa del producto a la izquierda en escritorio amplio y apilada en pantallas menores.
- La vista previa utiliza directamente los acordes en edición, sin solicitudes adicionales ni copia independiente del perfil.
- Biblioteca y barras permanecen separadas; botones dentro del flujo de la página, sin barra de guardado flotante.
- Desde el editor se puede explorar el catálogo en una página independiente y consultar una referencia. Consultarla no modifica el perfil actual.
- Usar acordes en el borrador aplica únicamente un perfil aprobado. Resuelve los IDs y colores canónicos desde el servidor; si falta algún acorde, rechaza la aplicación completa con un mensaje, sin descartar acordes silenciosamente.
- Aplicar un perfil no guarda automáticamente. Deshacer recupera el perfil original y Guardar perfil conserva el endpoint actual.
- Productos sin acordes pueden completarse desde la biblioteca tras cargar su perfil.

## Alcance de datos y límites

La exportación se incorporó como recursos de consulta de Flutter, no mediante una importación masiva a la base de datos. No se ejecutaron migraciones ni semillas y no se sobrescribieron perfiles guardados.

Las referencias no equivalen a productos disponibles para compra: el catálogo lo explica y no inventa precios ni stock. Los perfiles pendientes pueden consultarse por nombre o casa, pero no se muestran como perfiles aromáticos completos.

Elegir una referencia no cambia automáticamente el nombre, la foto, la relación maestra o los datos comerciales del producto. La imagen de referencia se muestra en su ficha; la vista previa del producto usa su imagen ya guardada. El botón Usar acordes en el borrador copia únicamente los acordes. La edición de fotos comerciales y la importación de referencias a la base de datos quedan fuera de esta adaptación.

La búsqueda del nuevo catálogo filtra datos de referencia locales. No reemplaza ni corrige el endpoint de búsqueda de productos de /#/acordes, cuya integración de filtros por intensidad sigue pendiente.

## Archivos

- frontend/lib/models/catalog_reference.dart: modelo de referencia, carga, búsqueda y conversión a IDs del servidor.
- frontend/lib/screens/perfumery_catalog/perfumery_catalog_page.dart: catálogo y ficha de referencia.
- frontend/lib/widgets/product/aromatic_preview.dart: vista previa reutilizable, sin cifras.
- frontend/lib/features/admin/accord_editor/accord_editor_page.dart: distribución, consulta y aplicación al borrador.
- frontend/lib/app/aromas_store_app.dart: ruta pública.
- frontend/lib/widgets/layout/top_navigation.dart: enlaces y navegación que se ajusta al ancho.
- frontend/pubspec.yaml y frontend/assets/perfumery/: catálogo e imágenes empaquetados.
- frontend/test/catalog_adaptation_test.dart: pruebas de datos, resolución de acordes, búsqueda y editor responsive.

## Validaciones

- flutter analyze: sin observaciones.
- flutter test: 9 pruebas aprobadas. Incluyen 320, 390, 1024 y 1440 px; vista previa a la izquierda en escritorio; añadir, deshacer y guardar mediante API de prueba; búsqueda por alias; rechazo de perfiles pendientes o acordes sin ID canónico.
- flutter build web: exitoso. Persiste advertencia previa de dart:html en cart_storage.dart para Wasm, ajena a este cambio.
- Navegador sobre compilación web: catálogo con imágenes y 634 referencias; búsqueda VICARO devuelve 212 VIP Men; ficha revisada a 390 px con imagen y barras sin cifras ni desbordamientos visibles.
- No se ejecutaron operaciones de guardado sobre productos reales durante la validación.

## Cómo probar

Levantar backend y frontend como de costumbre. Abrir /#/catalogo-perfumeria para explorar referencias, o /#/admin/acordes para editar un producto existente. Desde el editor, Explorar catálogo de perfumería abre la selección. Elegir referencia permite consultarla y, si está aprobada, aplicar sus acordes al borrador. Revisar la vista previa, Deshacer o Guardar perfil según corresponda.

Los cambios quedan locales en la rama de trabajo. No se hizo commit, push ni merge en esta adaptación.