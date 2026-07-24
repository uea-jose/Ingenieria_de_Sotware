# Bitacora Frontend - Refactorizacion Estructural

Proyecto: Aromas Store  
Modulo: Frontend Flutter Web  
Inicio: 2026-07-09  
Objetivo: ordenar el frontend por responsabilidades sin cambiar la pagina publica, el catalogo ni el carrito.

## 1. Proposito

Esta bitacora registra la reorganizacion del frontend de Aromas Store. La meta es que el codigo deje de depender de un unico `main.dart` gigante y pase a una estructura facil de leer, probar y extender.

La refactorizacion no agrega funcionalidades nuevas. Solo acomoda lo que ya existe.

## 2. Regla De Conservacion

Durante esta etapa se conserva exactamente:

- Pagina publica actual.
- Catalogo conectado a productos, categorias y marcas del backend.
- Busqueda y filtros.
- Carrito visual y funcional.
- Persistencia local del carrito.
- Validacion de carrito contra `/api/carrito/validar`.
- Botones pendientes como login, favoritos, vista rapida y finalizar compra sin conexion nueva.

## 3. Estado Inicial

Antes de la refactorizacion, casi todo vivia en:

```txt
frontend/lib/main.dart
```

Ese archivo concentraba:

- Arranque de la app.
- Tema visual.
- Pantalla publica.
- Estado de catalogo y carrito.
- Llamadas HTTP.
- Acceso a `localStorage`.
- Modelos de datos.
- Widgets de navegacion, catalogo, carrito, carga y error.

Esto funcionaba, pero hacia dificil avanzar con login, checkout y panel administrativo sin volver el archivo inmanejable.

## 4. Estructura Actual Del Frontend

Estado despues de las primeras etapas:

```txt
frontend/lib/
  main.dart
  app/
    app_theme.dart
    aromas_store_app.dart
  config/
    api_config.dart
    storage_keys.dart
  core/
    utils/
      parsing_utils.dart
      price_formatter.dart
  data/
    api/
      api_service.dart
    storage/
      cart_storage.dart
  models/
    brand.dart
    cart_validation.dart
    catalog_data.dart
    category.dart
    inventory.dart
    product.dart
  screens/
    home/
      home_page.dart
    product_detail/
      product_detail_page.dart
  widgets/
    cart/
      cart_panel.dart
      cart_preview_bar.dart
      cart_product_row.dart
      cart_validation_summary.dart
      product_thumbnail.dart
      quantity_stepper.dart
    catalog/
      catalog_filters.dart
      catalog_section_header.dart
      empty_catalog_view.dart
      product_badges.dart
      product_card.dart
      product_grid.dart
      product_image.dart
    feedback/
      error_view.dart
      loading_view.dart
    layout/
      brand_mark.dart
      cart_nav_button.dart
      premium_announcement_bar.dart
    product/
      product_detail_header.dart
      product_future_accords_placeholder.dart
      product_info_section.dart
      product_purchase_panel.dart

frontend/backups/
  main_catalogo_v1_respaldo.dart
      top_navigation.dart
```

## 5. Mapa Rapido De Responsabilidades

| Ruta | Responsabilidad | Impacto |
|---|---|---|
| `main.dart` | Punto de entrada de Flutter. | Arranca `AromasStoreApp` sin contener UI, API, storage ni modelos. |
| `app/` | Configura la aplicacion y el tema visual existente. | Centraliza `MaterialApp` y conserva colores/tipografia actuales. |
| `screens/home/` | Contiene la pagina publica actual. | Mantiene hero, catalogo, filtros, carrito y validacion. |
| `screens/product_detail/` | Contiene el detalle publico de producto. | Muestra informacion real del producto y prepara la futura seccion de acordes. |
| `config/` | Guarda constantes globales del frontend. | Evita valores sueltos dentro de la interfaz. |
| `core/utils/` | Contiene funciones pequenas reutilizables. | Reduce duplicacion y prepara modelos limpios. |
| `data/api/` | Concentra llamadas HTTP al backend. | La UI ya no sabe como se llama a la API. |
| `data/storage/` | Maneja persistencia local del carrito. | La UI ya no toca directamente `localStorage`. |
| `models/` | Define las clases de datos usadas por la app. | Facilita mantener el contrato entre API y frontend. |
| `widgets/` | Agrupa piezas visuales reutilizables por dominio. | Separa layout, catalogo, carrito y estados de carga/error. |
| `widgets/product/` | Agrupa piezas visuales del detalle de producto. | Evita que la pantalla de detalle concentre toda la composicion. |
| `frontend/backups/` | Conserva respaldos historicos fuera del codigo activo. | Evita que un respaldo dentro de `lib/` se confunda con la aplicacion vigente. |

## 6. Archivos Implementados

### `config/api_config.dart`

Define la URL base de la API:

```txt
http://localhost:3000/api
```

Uso actual:

- Catalogo.
- Categorias.
- Marcas.
- Validacion de carrito.

### `config/storage_keys.dart`

Define claves usadas en almacenamiento local.

Uso actual:

- `cartStorageKey`: identifica el carrito guardado en el navegador.

### `core/utils/parsing_utils.dart`

Convierte valores dinamicos de JSON a tipos seguros:

- `asInt`
- `asDouble`
- `asString`

Uso actual:

- Modelos recibidos desde la API.
- Restauracion de datos persistidos.

### `core/utils/price_formatter.dart`

Prepara una utilidad para formato de precios.

Estado actual:

- Creado para uso progresivo.
- Aun no reemplaza todos los `toStringAsFixed(2)` del frontend.

### `data/api/api_service.dart`

Contiene la comunicacion HTTP con el backend.

Funciones actuales:

| Funcion | Endpoint usado | Resultado |
|---|---|---|
| `loadCatalog()` | `/api/productos`, `/api/categorias`, `/api/marcas` | Carga el catalogo publico. |
| `loadProductById()` | `/api/productos/:id` | Carga el detalle de un producto. |
| `validateCart()` | `/api/carrito/validar` | Valida stock, subtotal, IVA y total. |

Beneficio:

- `main.dart` ya no importa `package:http/http.dart`.
- La pantalla usa `ApiService` sin conocer detalles HTTP.

### `data/storage/cart_storage.dart`

Maneja el carrito guardado en el navegador.

Funciones actuales:

| Funcion | Que hace |
|---|---|
| `load()` | Recupera productos y cantidades desde `localStorage`. |
| `save()` | Guarda el carrito actual. |
| `clear()` | Elimina el carrito persistido. |

Beneficio:

- `main.dart` ya no importa `dart:html`.
- La logica de persistencia queda aislada.

## 7. Modelos Implementados

| Archivo | Clase | Que representa |
|---|---|---|
| `models/product.dart` | `Product` | Producto del catalogo con marca, categoria, precio, imagen, estado e inventario. |
| `models/brand.dart` | `Brand` | Marca o casa fabricante. |
| `models/category.dart` | `Category` | Categoria del producto. |
| `models/inventory.dart` | `Inventory` | Stock, stock minimo y ubicacion. |
| `models/catalog_data.dart` | `CatalogData` | Agrupa productos, categorias y marcas para la pantalla publica. |
| `models/cart_validation.dart` | `CartValidation` | Resultado de validar carrito contra el backend. |

Estos modelos mantienen los mismos nombres y campos usados antes en `main.dart`.

## 8. Pantalla Publica Actual

La pagina visible del usuario se conserva.

Hoy esta ubicada en:

```txt
frontend/lib/screens/home/home_page.dart
```

El punto de entrada queda en:

```txt
frontend/lib/main.dart
```

La pantalla publica sigue controlando:

- Carga del catalogo.
- Busqueda.
- Filtros.
- Carrito en memoria.
- Apertura del panel del carrito.
- Validacion contra backend.

## 9. Carrito Actual

El carrito se conserva completo.

Actualmente:

- El estado sigue en `HomePage`.
- La persistencia ya esta en `CartStorage`.
- La validacion ya esta en `ApiService`.

Ubicacion visual actual:

```txt
frontend/lib/widgets/cart/
```

Componentes separados:

- `cart_preview_bar.dart`
- `cart_panel.dart`
- `cart_product_row.dart`
- `quantity_stepper.dart`
- `cart_validation_summary.dart`

## 10. Avance Por Etapas

| Etapa | Estado | Resultado |
|---|---|---|
| Etapa 0 - Preparacion | Completada | Se documento el plan y se limpiaron referencias incompletas de login/checkout. |
| Etapa 1 - Configuracion y utilidades | Completada | Se crearon `config/` y `core/utils/`. |
| Etapa 2 - Modelos | Completada | Se movieron los modelos a `models/`. |
| Etapa 3 - API y storage | Completada | Se movieron `ApiService` y `CartStorage`. |
| Etapa 4 - Layout y feedback | Completada | Se movieron navegacion, carga, error y skeletons. |
| Etapa 5 - Catalogo | Completada | Se movieron encabezado, filtros, grid, cards, imagenes, badges y vista vacia. |
| Etapa 6 - Carrito visual | Completada | Se movieron barra previa, panel, filas, miniaturas, stepper y resumen. |
| Etapa 7 - Pantalla principal | Completada | Se movieron `HomePage`, app y tema; `main.dart` quedo como entrada limpia. |
| Etapa 8 - Cierre no funcional | Completada | Se actualizo el reporte con la estructura real, pasos pendientes y limite antes de nuevas funcionalidades. |
| Etapa 9 - Orden de respaldo | Completada | Se movio el respaldo historico fuera de `lib/` sin modificar su contenido. |

## 11. Registro De Cambios

### 2026-07-09 - Etapa 0

- Se creo la bitacora de refactorizacion frontend.
- Se definio que la pagina publica actual se conservara.
- Se definio que el carrito no cambiara de comportamiento.
- Se establecio que no se implementaran login, checkout ni panel administrativo durante esta fase.

### 2026-07-09 - Etapa 1

- Se crearon:
  - `frontend/lib/config/api_config.dart`
  - `frontend/lib/config/storage_keys.dart`
  - `frontend/lib/core/utils/parsing_utils.dart`
  - `frontend/lib/core/utils/price_formatter.dart`
- Se movieron desde `main.dart`:
  - `apiBaseUrl`
  - `cartStorageKey`

### 2026-07-10 - Etapa 2

- Se crearon:
  - `frontend/lib/models/brand.dart`
  - `frontend/lib/models/category.dart`
  - `frontend/lib/models/inventory.dart`
  - `frontend/lib/models/product.dart`
  - `frontend/lib/models/catalog_data.dart`
  - `frontend/lib/models/cart_validation.dart`
- Se eliminaron de `main.dart` los modelos duplicados.
- Se reemplazaron helpers privados por utilidades reutilizables.

### 2026-07-10 - Etapa 3

- Se creo `frontend/lib/data/api/api_service.dart`.
- Se movio `ApiService`.
- Se creo `frontend/lib/data/storage/cart_storage.dart`.
- Se movio la persistencia del carrito.
- `main.dart` dejo de importar:
  - `package:http/http.dart`
  - `dart:convert`
  - `dart:html`

### 2026-07-10 - Etapa 4

- Se creo la carpeta `frontend/lib/widgets/layout/`.
- Se movieron widgets de navegacion y marca:
  - `frontend/lib/widgets/layout/top_navigation.dart`
  - `frontend/lib/widgets/layout/brand_mark.dart`
  - `frontend/lib/widgets/layout/cart_nav_button.dart`
  - `frontend/lib/widgets/layout/premium_announcement_bar.dart`
- Se creo la carpeta `frontend/lib/widgets/feedback/`.
- Se movieron estados visuales generales:
  - `frontend/lib/widgets/feedback/loading_view.dart`
  - `frontend/lib/widgets/feedback/error_view.dart`
- Se actualizo `frontend/test/widget_test.dart` para importar `LoadingView` desde su nueva ubicacion.
- `main.dart` conserva el uso de `TopNavigation`, `LoadingView` y `ErrorView`, pero ya no contiene su implementacion interna.

### 2026-07-10 - Etapa 5

- Se creo la carpeta `frontend/lib/widgets/catalog/`.
- Se movieron widgets propios del catalogo:
  - `frontend/lib/widgets/catalog/catalog_section_header.dart`
  - `frontend/lib/widgets/catalog/catalog_filters.dart`
  - `frontend/lib/widgets/catalog/product_grid.dart`
  - `frontend/lib/widgets/catalog/product_card.dart`
  - `frontend/lib/widgets/catalog/product_image.dart`
  - `frontend/lib/widgets/catalog/product_badges.dart`
  - `frontend/lib/widgets/catalog/empty_catalog_view.dart`
- Se conservaron textos, colores, tamanos, badges, hover, mensajes de favoritos y vista rapida.
- `main.dart` sigue coordinando el estado del catalogo, pero ya no contiene la implementacion visual de cards, filtros ni grilla.

### 2026-07-10 - Etapa 6

- Se creo la carpeta `frontend/lib/widgets/cart/`.
- Se movieron widgets propios del carrito:
  - `frontend/lib/widgets/cart/cart_preview_bar.dart`
  - `frontend/lib/widgets/cart/cart_panel.dart`
  - `frontend/lib/widgets/cart/cart_product_row.dart`
  - `frontend/lib/widgets/cart/product_thumbnail.dart`
  - `frontend/lib/widgets/cart/quantity_stepper.dart`
  - `frontend/lib/widgets/cart/cart_validation_summary.dart`
- Se conservaron cantidades, validacion, acciones de vaciar, continuar comprando, finalizar compra preparado, resumen de IVA y persistencia local.
- `main.dart` conserva el estado del carrito y sus callbacks, pero ya no contiene la implementacion visual del carrito.

### 2026-07-10 - Etapa 7

- Se creo la carpeta `frontend/lib/app/`.
- Se separo la configuracion principal de la aplicacion:
  - `frontend/lib/app/aromas_store_app.dart`
  - `frontend/lib/app/app_theme.dart`
- Se creo la carpeta `frontend/lib/screens/home/`.
- Se movio la pantalla publica actual:
  - `frontend/lib/screens/home/home_page.dart`
- `main.dart` quedo reducido al punto de entrada de Flutter.
- Se conservaron catalogo, busqueda, filtros, carrito, persistencia local y validacion contra backend.

### 2026-07-10 - Etapa 8

- Se reviso el estado posterior a la separacion estructural.
- Se corrigio el reporte para indicar que la pagina publica ya vive en `screens/home/home_page.dart`.
- Se dejo documentado que `main.dart` ya no contiene la pantalla, modelos, servicios ni widgets.
- Se agrego una lista de pasos pendientes no funcionales antes de iniciar login, checkout, panel administrativo o nuevas pantallas.
- No se modifico codigo Dart en esta etapa.

### 2026-07-10 - Etapa 9

- Se creo la carpeta `frontend/backups/`.
- Se movio el respaldo historico:
  - Desde `frontend/lib/main_catalogo_v1_respaldo.dart`
  - Hacia `frontend/backups/main_catalogo_v1_respaldo.dart`
- No se cambio el contenido del respaldo.
- La carpeta `frontend/lib/` queda reservada para codigo activo del frontend.

## 12. Validaciones

| Validacion | Estado | Observacion |
|---|---|---|
| Revision de referencias incompletas de login/checkout | Correcta | No quedaron `AuthSession`, `AuthPanel` ni `CheckoutPanel`. |
| Revision de modelos duplicados en `main.dart` | Correcta | Los modelos viven en `models/`. |
| Revision de acceso directo a API en `main.dart` | Correcta | HTTP vive en `ApiService`. |
| Revision de acceso directo a `localStorage` en `main.dart` | Correcta | Persistencia vive en `CartStorage`. |
| Revision de widgets layout duplicados en `main.dart` | Correcta | Navegacion vive en `widgets/layout/`. |
| Revision de widgets feedback duplicados en `main.dart` | Correcta | Carga y error viven en `widgets/feedback/`. |
| Revision de widgets catalogo duplicados en `main.dart` | Correcta | Catalogo vive en `widgets/catalog/`. |
| Revision de widgets carrito duplicados en `main.dart` | Correcta | Carrito vive en `widgets/cart/`. |
| Revision de pantalla principal en `main.dart` | Correcta | `HomePage` vive en `screens/home/home_page.dart`. |
| Revision de app/tema en `main.dart` | Correcta | App y tema viven en `app/`. |
| `git diff --check` | Correcta | Sin errores de espacios. |
| `flutter analyze` / `flutter test` | Pendiente | En esta terminal `flutter` no esta disponible en el PATH. Debe ejecutarse desde el entorno local donde Flutter este configurado. |
| Busqueda de `flutter` y `dart` en PATH | Pendiente externo | `where.exe flutter` y `where.exe dart` no encontraron ejecutables en esta terminal. |

## 13. Pasos Pendientes Sin Nueva Funcionalidad

Antes de iniciar login, checkout, panel administrativo o nuevas paginas, faltan solo pasos de cierre:

| Paso | Tipo | Objetivo |
|---|---|---|
| Revision visual local | Validacion | Confirmar que la pagina actual se ve igual: hero, catalogo, filtros, carrito y resumen. |
| Ejecutar `flutter analyze` | Validacion tecnica | Detectar errores de importacion, tipos o lints desde un entorno con Flutter disponible. |
| Ejecutar `flutter test` | Validacion tecnica | Confirmar que la prueba basica del estado de carga sigue pasando. |
| Revisar archivo de respaldo | Orden de archivos | Completado: el respaldo se conservo en `frontend/backups/main_catalogo_v1_respaldo.dart`. |
| Cierre de refactor | Documentacion | Marcar la refactorizacion estructural base como finalizada despues de validar visualmente. |

Estos pasos no agregan funcionalidades, no crean pantallas, no cambian colores y no incorporan imagenes.

## 14. Proximo Paso Funcional

La refactorizacion estructural base queda completada. Antes de desarrollar nuevas paginas o funcionalidades, se recomienda:

```txt
frontend/lib/app/
frontend/lib/screens/
frontend/lib/widgets/
frontend/lib/data/
frontend/lib/models/
```

Siguiente fase posible, solo con aprobacion:

- Conectar login en frontend.
- Crear checkout/pedido.
- Crear panel administrativo.
- Crear nuevas pantallas por rol.

Hasta este punto no se han agregado nuevas funcionalidades.

## 15. Evolucion Visual Controlada De HomePage

### 2026-07-11 - AS-052

Se inicio una fase distinta a la refactorizacion: mejora visual y comercial de la portada publica existente.

Alcance aplicado:

- Se mantuvo `HomePage` como unica pantalla publica.
- Se mantuvieron `ApiService`, `CartStorage`, `ProductGrid`, `ProductCard`, `CartPanel`, filtros y validacion de carrito.
- Se mejoro `TopNavigation` para incluir navegacion comercial: Inicio, Perfumes, Mujer, Hombre, Unisex, Marcas y Promociones.
- Se agrego un buscador visual con sugerencias locales, debounce y navegacion basica por teclado.
- Se agrego un fallback local de productos de demostracion para mostrar Paco Rabanne, Armani, Dior, Chanel, Versace y Carolina Herrera cuando el catalogo real sea insuficiente o el backend no responda.
- Se agregaron secciones de portada: categorias, productos destacados, promocion, mas vendidos, marcas, ocasiones, beneficios y footer.
- Se excluyo `frontend/backups/` del analisis porque contiene respaldo historico, no codigo activo.

Limites respetados:

- No se implemento login real.
- No se implemento checkout real.
- No se implementaron pagos, pedidos, facturacion ni panel administrativo.
- No se crearon endpoints.
- No se agregaron dependencias nuevas.
- No se agregaron assets externos ni imagenes remotas; se reutilizo el placeholder visual existente.

Validacion:

| Validacion | Estado | Observacion |
|---|---|---|
| `dart analyze` | Correcta | Sin errores ni avisos despues de excluir respaldos. |
| `git diff --check` | Correcta | Sin errores de espacios. |
| `flutter test` | Pendiente tecnico | El comando no finalizo por bloqueo/procesos Flutter/Dart activos. |

### 2026-07-11 - AS-053

Se refino unicamente el buscador predictivo de la HomePage.

Cambios aplicados:

- El panel dejo de ser una lista vertical larga.
- Se dividio en dos zonas:
  - Izquierda: sugerencias relacionadas.
  - Derecha: productos visuales encontrados.
- Los productos se muestran como mini tarjetas comerciales con imagen simulada, marca, nombre, precio, etiqueta y accion de vista rapida.
- Se mantiene una sola fuente de datos: los productos ya usados por la HomePage.
- Se conserva el comportamiento de busqueda, filtros, catalogo y carrito.
- El panel cierra con Escape, al limpiar el campo o al hacer clic fuera.
- El diseño se adapta a escritorio, tablet y movil sin crear una pagina nueva.

Validacion:

| Validacion | Estado | Observacion |
|---|---|---|
| `dart analyze` | Correcta | Sin issues. |
| `git diff --check` | Correcta | Sin errores de espacios. |

### 2026-07-11 - AS-054

Se aplico una nueva identidad visual pastel kawaii elegante en el frontend publico.

Cambios aplicados:

- Se creo `frontend/lib/app/app_design_tokens.dart`.
- Se centralizaron colores, radios y sombras.
- Se cambio el fondo general a `#FFF8FB`.
- Se reemplazaron verdes oscuros, dorados, borgoña y grises fuertes por rosa empolvado, lavanda, melocoton, menta y celeste.
- Se configuro DM Serif Display para titulos y Nunito para textos mediante `google_fonts`.
- Se aplico la identidad en tema global, HomePage, buscador predictivo, catalogo, carrito, layout y estados de feedback.
- Se dejaron listas de color `womanTheme` y `manTheme` para preparar futuros temas por categoria sin implementar logica nueva.

Limites respetados:

- No se cambio la logica de API.
- No se cambio la logica del carrito.
- No se implementaron nuevas pantallas.
- No se agregaron flujos de login, checkout, pagos ni administracion.

Validacion:

| Validacion | Estado | Observacion |
|---|---|---|
| Busqueda de colores antiguos principales | Correcta | No quedan `#145647`, `#E8C766`, `#102F29`, `#8A5A3B` ni equivalentes principales en `frontend/lib`. |
| `dart analyze` | Correcta | Sin issues. |
| `git diff --check` | Correcta | Sin errores de espacios. |
