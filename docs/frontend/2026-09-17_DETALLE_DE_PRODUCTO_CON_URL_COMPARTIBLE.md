# Detalle de producto con URL compartible

Fecha: 2026-09-17
Rama: `backup/acordes-antes-split`
HEAD previo al cambio: `466fdc0`

## Objetivo

Cerrar el "customer journey" del catálogo dando a cada producto una URL
propia (`/producto/:id`), estado explícito de "producto no encontrado" y
recomendaciones por marca y categoría. La página de detalle ya existía;
este paso la habilita como ruta nombrada, la refuerza con contenido y la
prepara como pieza pública compartible.

## Estado previo (auditoría)

La página `ProductDetailPage` ya vivía en
`frontend/lib/screens/product_detail/product_detail_page.dart` con un
layout completo (imagen grande, marca, nombre, categoría, precio, stock,
volumen, descripción, acordes con intensidades y botón "Agregar al
carrito"). Se abría desde `home_page.dart` y `accord_search_page.dart`
con `Navigator.push(MaterialPageRoute)` — navegación **imperativa**, no
por nombre.

Consecuencia: en Flutter Web la URL nunca cambiaba (`/#/` fijo), no era
compartible ni sobrevivía a un `F5`. Tampoco había ruta declarada en
`aromas_store_app.dart` para `/producto/:id`.

## Cambios

### Backend

Ninguno. Los filtros `marcaId=` y `categoriaId=` de `GET /api/productos`
ya existían (`backend/src/modules/productos/productos.service.js`
función `construirFiltros`). Se aprovecharon sin ampliar el backend.

### Frontend — routing (Fase A)

- `frontend/lib/app/aromas_store_app.dart`
  - Añade `onGenerateRoute: _onGenerateRoute`.
  - `_onGenerateRoute` parsea `/producto/:id` como `int`. Si el
    parámetro no es un entero positivo, entrega la ruta con
    `productId: -1`, que la propia página convierte en
    `_NotFoundScaffold`.
  - Acepta `RouteSettings.arguments` de tipo [Product] para permitir
    "seed" del detalle sin hacer un roundtrip de red cuando el caller
    ya tiene el producto en memoria.

- `frontend/lib/screens/product_detail/product_detail_page.dart`
  - `cartCount` y `onAddToCart` pasan a ser **opcionales**.
    - Cuando el usuario llega por URL directa (no hay `HomePage` viva
      pasando estado), el widget lee el contador desde `CartStorage` y
      escribe el "Agregar al carrito" también en `CartStorage`
      (fallback local + toast).
    - Cuando el caller pasa `onAddToCart`, se invoca tal cual (path
      original desde `HomePage`).
  - Nuevo `_NotFoundScaffold` para dos casos:
    - Id inválido (`_onGenerateRoute` no pudo parsear el `:id`).
    - `HTTP 404` desde `ApiService.loadProductById`.
    - Reutiliza `TopNavigation` y muestra CTA "Explorar catálogo" que
      resetea la pila con `pushNamedAndRemoveUntil('/')`.
  - "Volver": si `Navigator.canPop()` hace `pop`; en URL directa hace
    `pushNamedAndRemoveUntil('/')` para no dejar al usuario atrapado.

- `frontend/lib/screens/home/home_page.dart`
  - `_openProductDetail` migrado a `pushNamed('/producto/$id',
    arguments: product)`. Al volver, refresca `_cartQuantities` desde
    `CartStorage` — así los items agregados dentro del detalle via
    fallback quedan reflejados en el badge y el carrito de la home.

- `frontend/lib/screens/accord_search/accord_search_page.dart`
  - `_openProduct` migrado a `pushNamed`, pasa el `Product` en
    `arguments` para evitar el roundtrip inicial.

### Frontend — contenido (Fase B)

- `frontend/lib/widgets/product/brand_info_block.dart` (nuevo)
  - Panel "Sobre {marca}" que usa **solo** los campos del modelo
    `Brand`: `nombre`, `paisOrigen` (opcional), `descripcion`
    (opcional). No se inventa "fabricante" — semánticamente la marca
    cumple ese rol.
  - Método estático `hasInfo(brand)` para que la página lo renderice
    únicamente cuando existan datos reales.

- `frontend/lib/widgets/product/related_products_section.dart` (nuevo)
  - Dos carruseles horizontales:
    - "Más de {marca}" — `GET /productos?marcaId=X&activo=true`.
    - "También te podría gustar" — `GET /productos?categoriaId=Y&activo=true`.
  - Excluye el producto actual y elimina duplicados por id entre las
    dos listas (si un producto aparece por marca ya no aparece por
    categoría). Si ambas quedan vacías, la sección se oculta.
  - Reutiliza el `ProductCard` del catálogo — no se duplicó el widget.
  - Al tocar una tarjeta navega con `pushNamed('/producto/$id',
    arguments: product)`, mismo patrón que la home. Esto permite
    "chain browsing" con URLs coherentes.

- `frontend/lib/widgets/product/product_purchase_panel.dart`
  - Botón favorito circular al lado del "Agregar al carrito"
    (`OutlinedButton` con `CircleBorder`, icono `favorite_border`).
  - **Placeholder**: al tocar dispara `AppFeedback.info` con el mismo
    copy que ya usa `ProductCard` ("marcado como favorito para una
    siguiente iteración"). El módulo real de favoritos ship en el
    próximo paso; este botón queda visible y listo para cablearse.

- `frontend/lib/data/api/api_service.dart`
  - Nuevo método `loadRelatedProducts({excludeId, brandId?, categoryId?, limit=6})`
    que consulta `GET /productos` con los filtros server-side, excluye
    el `excludeId` y limita a `limit`. Devuelve `[]` en caso de error
    (los relacionados son no-críticos, la página no debe romperse por
    esto).

## URL routing en Flutter Web

Se mantiene el hash-routing por defecto (`/#/producto/1`). No se
introduce `usePathUrlStrategy()` porque eso requiere configurar el
servidor de hosting para servir `index.html` en cualquier ruta, y ese
cambio queda mejor acoplado al paso de deploy.

Con hash-routing:
- La URL cambia a medida que se navega.
- Un F5 no rompe la sesión.
- Compartir por chat o correo funciona sin configuración de servidor.

## Verificación

### Estáticos

- `flutter analyze --no-fatal-infos` → 0 issues.
- `flutter test` → 20/20.
- `flutter build web` → build OK. Warning WASM preexistente por
  `cart_storage.dart` (usa `dart:html`), no bloquea el build JS.

### Contra backend real (`http://localhost:3000`)

Verificado con `Invoke-RestMethod`:

- `GET /productos/1` (Lancome, La Vie Est Belle) → responde correcto.
  `marca.paisOrigen=''`, `marca.descripcion.Length=0`. La sección
  "Sobre la marca" **no se renderiza** — comportamiento esperado
  gracias a `BrandInfoBlock.hasInfo`.
- `GET /productos/2` (Giorgio Armani) → `paisOrigen='Italia'`,
  `descripcion` con 35 caracteres. Sección "Sobre la marca" **se
  renderiza** con datos reales.
- `GET /productos/99999` → 404 con `{"error":"El producto indicado no
  existe."}`. La página muestra `_NotFoundScaffold` (icono
  `search_off_outlined`, título "Producto no encontrado", CTA
  "Explorar catálogo").
- `GET /productos?categoriaId=1&activo=true` → 5 productos. Los
  carruseles se pueblan.

### Rutas frontend a revisar visualmente

Con `http://127.0.0.1:8080` levantado:

1. `/#/producto/1` — carga producto por URL directa, muestra imagen,
   marca, precio, stock, descripción, acordes, botones "Agregar al
   carrito" + favorito, y carrusel de relacionados por categoría.
2. `/#/producto/2` — muestra además el bloque "Sobre Giorgio Armani"
   con país e info real.
3. `/#/producto/99999` — vista dedicada de "Producto no encontrado".
4. `/#/producto/abc` — vista dedicada de "Producto no encontrado"
   (parse falla antes de tocar backend).
5. F5 en cualquier `/producto/N` — la URL persiste y la página vuelve a
   cargar.
6. Home → tocar "Ver detalle" en cualquier tarjeta → URL cambia a
   `/#/producto/N`, back vuelve a home preservando estado del carrito.
7. `/#/acordes` → seleccionar acordes → tocar producto → URL cambia,
   back devuelve al buscador.
8. Dentro del detalle: tocar una tarjeta relacionada → URL cambia,
   contenido cambia sin ir a home.

## Decisiones y no-goals

- **No se agregó campo `fabricante`**. El modelo Prisma `Marca` no
  tiene un campo separado para eso; en este dominio la marca cumple el
  rol. Se aprovecharon los campos existentes (`paisOrigen`,
  `descripcion`) sin inventar dato nuevo.
- **`ProductCard` no se tocó**. Su `onViewDetails` recibe una callback
  desde la Home y ese callback ahora hace `pushNamed`. La tarjeta sigue
  siendo agnóstica al mecanismo de navegación.
- **Favoritos**: solo botón visual + toast placeholder. El módulo real
  con `LocalStorage` + página `/favoritos` es el próximo paso.
- **Sin `usePathUrlStrategy()`**: se mantiene hash routing por
  simplicidad de deploy. Cambiar a paths limpios queda para el paso de
  hosting.
- **Cart en URL directa**: fallback contra `CartStorage`. No se
  introdujo un `CartScope`/`CartController` global porque el alcance
  eran las tres rutas descritas; ese refactor merece su propio paso.

## Roadmap posterior directo

- Módulo de favoritos real (localStorage → migración futura a backend).
- Búsqueda global en el header.
- `usePathUrlStrategy()` en el paso de deploy con la config del
  servidor.
