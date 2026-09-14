# Resumen de sesión — Branding Essenza Store & storefront de perfumería

Fecha final: 2026-09-14
Rama de trabajo: `backup/acordes-antes-split`
Ámbito: **frontend Flutter Web + backend Node/Express + Prisma/PostgreSQL**

Este documento consolida todo lo hecho en la ronda de trabajo iniciada
alrededor del 2026-09-08 y cerrada el 2026-09-14. Sirve como punto de
retomado para cualquier IA o desarrollador que continúe.

## 1. Producto y stack

- **Aromas Store** (branding "Essenza Store") — e-commerce de perfumería.
- Backend: Node.js + Express + Prisma en `backend/`.
  - Base de datos: PostgreSQL en Docker (`aromas-store-postgres`, puerto **5433**).
  - API: `http://localhost:3000/api`.
- Frontend: Flutter Web en `frontend/`.
  - Comando de desarrollo: `C:\javilar\flutter\bin\flutter.bat run -d web-server --web-hostname 127.0.0.1 --web-port 8080`.
- Rutas relevantes:
  - Storefront público: `http://127.0.0.1:8080/`
  - Admin catálogo (editor de acordes + productos): `http://127.0.0.1:8080/#/admin/acordes`
  - Buscador por acordes público: `http://127.0.0.1:8080/#/acordes`
- Credenciales admin desarrollo: `admin@aromasstore.com` / `Admin12345`.

## 2. Qué se hizo (agrupado por bloques)

### 2.1 Backend — endpoint atómico de productos + acordes

- Se añadió un endpoint que crea/actualiza un producto y su perfil de
  acordes en **una sola transacción Prisma**, con validación estricta
  de valores.
- Se añadió el enum **`GeneroPerfume`** (`MASCULINO | FEMENINO | UNISEX`)
  al schema Prisma y al modelo `Producto`, con default `UNISEX`.
- `mapearProductoData(...)` en `backend/src/modules/productos/productos.service.js`
  valida el campo `genero`.
- Migración aplicada con `npx prisma db push` (no `migrate dev` porque una
  migración vieja `20260726090000_integrar_catalogo_acordes` está rota en
  la shadow DB: `relation productos does not exist`).
- Se creó `backend/scripts/asignar-perfumes-catalogo.js` que reasigna
  productos existentes a perfumes reales del catálogo (La Vie Est Belle,
  Acqua Di Gio, Sauvage, Coco Mademoiselle, Bleu, Good Girl). Se ejecutó
  contra la base real.
- Se agregó `backend/scripts/product-profile-unit.test.js` con pruebas de
  perfil de producto.

Archivos:

```
backend/prisma/schema.prisma
backend/src/modules/productos/productos.service.js
backend/src/modules/productos/productos.acordes.service.js
backend/src/modules/productos/productos.routes.js
backend/scripts/asignar-perfumes-catalogo.js       (nuevo)
backend/scripts/product-profile-unit.test.js       (nuevo)
```

### 2.2 Frontend — editor de acordes estilo Fragrantica

Editor visual profesional para el admin, replicando la sensación de
Fragrantica al construir el perfil de acordes de un perfume.

- **`AccordPicker`**: selector flotante con `OverlayPortal` +
  `CompositedTransformTarget` / `CompositedTransformFollower`. Elegido
  frente a expansión inline para que la lista no empuje filas hacia abajo.
- Cursores `grab` / `grabbing` con `Listener.onPointerDown/Up` para que la
  mano cerrada se aplique al **presionar** (no al iniciar drag). El
  `GestureDetector` no era suficiente porque solo detectaba `onDragStart`.
- Bolitas de color por acorde y drop-shadow en la "X" para eliminar.
- Barras con relleno color-del-acorde, ordenables por intensidad en tiempo
  real, con handle vertical.

Archivos nuevos / modificados:

```
frontend/lib/features/admin/accord_editor/accord_editor_page.dart
frontend/lib/features/admin/accord_editor/accord_picker.dart      (nuevo)
frontend/lib/features/admin/accord_editor/catalog_admin_page.dart (nuevo)
frontend/lib/features/admin/accord_editor/product_form.dart       (nuevo)
frontend/lib/widgets/product/accord_bar_row.dart
frontend/lib/widgets/product/aromatic_preview.dart                (nuevo)
frontend/lib/data/api/catalog_admin_api.dart
frontend/lib/models/catalog_reference.dart                        (nuevo)
frontend/lib/screens/perfumery_catalog/perfumery_catalog_page.dart(nuevo)
frontend/test/catalog_admin_page_test.dart                        (nuevo)
frontend/test/product_form_test.dart                              (nuevo)
frontend/test/catalog_adaptation_test.dart                        (nuevo)
```

### 2.3 Frontend — modelo `Product` con `gender`

- Campo `gender` opcional (default `'UNISEX'`) en `frontend/lib/models/product.dart`
  y en `Product.fromJson`. Elegido opcional para no romper los 12
  constructores del `demo_home_catalog`.

### 2.4 Frontend — branding Essenza Store

- `BrandMark` unificado (`frontend/lib/widgets/layout/brand_mark.dart`)
  ahora usa `assets/img/essenza_logo.png` con `BoxFit.contain`. Se trata
  el logo como **wordmark horizontal**, no como icono cuadrado.
- Hero carousel en la home (`home_commercial_sections.dart`) usa 3
  imágenes JPG: Bleu de Chanel L'Exclusif, La Bomba Fragrance Women, Men
  Fragrances PLP.
- Filtro por género en la barra de navegación (`TopNavigation`) con
  botones Hombre / Mujer / Unisex. Callback opcional `onGenderSelected`
  con fallback a `onCatalogPressed`. Sin nuevas rutas.
- `_catalogForDisplay` en `home_page.dart`: los productos reales tienen
  prioridad; el catálogo demo se muestra solo como fallback si el server
  no devuelve nada.
- Se eliminó la etiqueta "Demo" del buscador (`home_search_box.dart`) —
  ahora muestra el stock real.

Archivos:

```
frontend/lib/app/aromas_store_app.dart
frontend/lib/widgets/layout/brand_mark.dart
frontend/lib/widgets/layout/top_navigation.dart
frontend/lib/screens/home/home_page.dart
frontend/lib/screens/home/home_commercial_sections.dart
frontend/lib/screens/home/home_search_box.dart
```

### 2.5 Frontend — vista pública del catálogo (tarjetas de producto)

Rediseño completo de `ProductCard` inspirado en Carolina Herrera, Primor
y Jomashop. Corrige de raíz el `BOTTOM OVERFLOWED BY 102 PIXELS`
reportado.

Estructura fija:

1. **Header** — chip "Disponible" + logo Essenza (wordmark) + botón favorito.
2. **Meta** — marca (primary color) · nombre · categoría (secondary).
3. **Imagen** — dentro de `Expanded`, se lleva todo el alto restante.
4. **Bottom** — precio, `StockBadge`, "Ver detalle", "Agregar al carrito".

Decisiones estructurales importantes:

- **`_FavoriteButton` propio** (`GestureDetector` + `Container`) en vez
  de `IconButton`. `IconButton` fuerza tap target ≥ 48 px y causaba
  `RenderFlex overflowed by 16-17 pixels on the right`. Se probó
  `visualDensity`, `constraints: BoxConstraints()`, `tapTargetSize` —
  ninguno resolvió.
- **`_AvailabilityChip`** con modo icon-only cuando el ancho es escaso
  (breakpoint `constraints.maxWidth < 250`).
- **Header responsive con `LayoutBuilder`**: badge completo /
  badge-solo-icono / badge oculto según ancho. Logo Essenza en `FittedBox`
  con altura fija 20-26 px. Rechazado `FittedBox` global (deforma texto),
  rechazado `SingleChildScrollView` (raro visualmente).
- **`ProductImage` sin altura fija**: cambio de `height 88/122` →
  `height 200/240` → **sin altura** (usa `Expanded` del padre). Un
  `SizedBox` interno con altura fija causaba `BOTTOM OVERFLOWED 102 px`.
- **`ProductGrid` con `mainAxisExtent` fijo** (390/334/348 según columnas
  1/2/otros) → `ProductCard` tiene altura conocida → `Expanded` funciona.
- Test regresivo `frontend/test/product_card_overflow_test.dart` cubre
  21 combinaciones (7 anchos × 3 alturas) sin overflow.

### 2.6 Frontend — imagen del perfume con drop shadow 3D

`_BottleShadow` widget en `product_image.dart` — Stack con
`Transform.translate` + `ImageFiltered.blur` + `ColorFiltered` produce
una sombra proyectada que sigue la silueta alpha del PNG. Da el look
"botella flotando sobre la tarjeta" que usan Jomashop / Carolina
Herrera.

Parámetros:

- `blur: 10-14` (según compact)
- `drop: 6-9` (offset vertical)
- `alpha: 0.38` (intensidad)

Rechazado `BoxShadow` (sombrea un rect, no la forma) y `box-shadow` CSS
(no aplica en Flutter).

### 2.7 Frontend — resolver de imágenes por catálogo

`CatalogImageResolver` singleton en
`frontend/lib/data/catalog/catalog_image_resolver.dart` que carga una
sola vez `assets/perfumery/catalog.json` (634 referencias) y busca
match por nombre + marca. Rechazadas alternativas:

- Carga por-widget: costoso en I/O.
- `FutureBuilder` por-card: causa redraws.

Widget `ProductImage` con fallback three-level:
1. `imageUrl` propio del producto (asset o URL http)
2. `CatalogImageResolver.findAsset(name, brand)`
3. `ProductPlaceholder` (logo Essenza sobre fondo blanco)

También se aplicó el patrón al carrito (`ProductThumbnail`).

### 2.8 Frontend — hover swap Good Girl (última iteración)

Prueba UI/UX aislada: al hacer hover sobre la foto de **Good Girl ·
Carolina Herrera**, la imagen cambia con cross-fade suave (180 ms) al
packshot secundario, y vuelve al salir el mouse. Sólo afecta ese
producto — el resto del catálogo intacto.

**Detalles completos** en `docs/frontend/2026-09-14_HOVER_SWAP_GOOD_GIRL.md`.

Archivos:

```
frontend/lib/widgets/catalog/hover_product_image.dart          (nuevo)
frontend/lib/widgets/catalog/product_image.dart                (+27 LoC)
frontend/pubspec.yaml                                          (+1 línea)
frontend/assets/productos/good_girl/good_girl_primary.jpg      (nuevo)
frontend/assets/productos/good_girl/good_girl_hover.jpg        (nuevo)
```

## 3. Comandos de verificación estándar

Desde `frontend/`:

```powershell
C:\javilar\flutter\bin\flutter.bat analyze --no-fatal-infos
C:\javilar\flutter\bin\flutter.bat test
C:\javilar\flutter\bin\flutter.bat run -d web-server --web-hostname 127.0.0.1 --web-port 8080
C:\javilar\flutter\bin\flutter.bat build web --no-source-maps
```

Desde `backend/`:

```powershell
npm run dev
npx prisma generate
npx prisma db push    # no usar 'migrate dev', tiene shadow DB rota
```

Al terminar la sesión, el análisis y los 14 tests pasan; el build web
compila y empaqueta correctamente los assets en `build/web/assets/`.

## 4. Estado pendiente / próximas iteraciones sugeridas

1. **Generalizar el hover swap** a todos los productos. Requiere:
   - Añadir `imagenSecundariaUrl` (o `imagenHoverUrl`) al schema Prisma
     y al modelo `Product`.
   - Actualizar `productos.service.js` para leer/escribir el campo.
   - Editor de producto en admin: permitir cargar dos imágenes.
   - En `ProductImage`, usar `HoverProductImage` cuando exista el
     campo, retirando el hardcode `_isGoodGirlCarolinaHerrera`.
2. **Aplicar el drop-shadow 3D al detalle de producto**
   (`ProductDetailHeader`) y al `ProductThumbnail` del carrito
   (parcialmente hecho, revisar consistencia).
3. **Auditoría rol Bodeguero**: no hay ninguna cuenta con ese rol en la
   base actual (sólo Administrador y Cliente). Las rutas del backend sí
   aceptan Bodeguero, pero no está verificado en la práctica. Crear una
   cuenta de prueba y probar.
4. Revisar el producto "Vela Lavanda Relax → Coco Mademoiselle" — se
   reasignó pero su categoría sigue como "Velas aromáticas". Ajustar.
5. Renombrar más productos manualmente para aumentar matches con el
   catálogo si el usuario quiere más imágenes ricas.
6. Corregir la migración `20260726090000_integrar_catalogo_acordes` para
   poder volver a usar `prisma migrate dev` en lugar de `db push`.

## 5. Historial de commits de esta sesión

Al momento del cierre:

```
<hash>  feat(storefront): branding Essenza, editor de acordes, catálogo público
        con drop shadow 3D, hover swap Good Girl y docs completos
<hash>  chore: ignorar .kiro/ (config IDE) y adicionales/ (materiales privados)
```

## 6. Convenciones y advertencias

- **No hacer commit ni push sin revisión visual del usuario** cuando se
  toca la UI. Este proyecto se avanza en pasos revisados.
- **Nunca usar `flutter run` sin `-d web-server`** en Windows; los otros
  targets no están instalados.
- **`prisma migrate dev` está roto** en este proyecto por una migración
  vieja que falla en shadow DB. Usar `db push` hasta que se arregle.
- **Precio, stock, favoritos, carrito, autenticación**: intactos en esta
  sesión. Todos los cambios visuales conservan la funcionalidad.
- **Assets pesados**: `frontend/assets/perfumery/` pesa ≈16 MB (635
  archivos WEBP). Es intencional — es el catálogo de referencia visual
  que consume `CatalogImageResolver`.
- **`.kiro/` y `adicionales/`**: ignorados en git (config IDE local y
  materiales privados del usuario — PDFs de catálogos, screenshots).
