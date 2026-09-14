# Hover swap de imagen — Good Girl · Carolina Herrera (prueba UI/UX)

Fecha: 2026-09-14
Rama: `backup/acordes-antes-split`
Alcance: **frontend**, sin cambios en backend, base de datos, API ni modelo `Product`.

## Contexto

Estamos consolidando la vista pública del catálogo (`storefront`) para que
tenga acabado de e-commerce premium, siguiendo referencias visuales como
Carolina Herrera, Primor y Jomashop. Esta iteración añade una interacción
adicional que se ve mucho en esos sitios: al pasar el mouse sobre la foto
principal del perfume, la foto cambia a una vista alternativa (frasco +
caja, packshot secundario, etc.), y al salir vuelve a la foto principal.

En esta primera pasada la funcionalidad se activa **sólo** para un
producto — **Good Girl** de **Carolina Herrera** — como prueba controlada
de UX antes de generalizarla al resto del catálogo.

## Comportamiento

| Evento                          | Imagen visible                          |
|---------------------------------|-----------------------------------------|
| Estado normal (sin hover)       | `good_girl_primary.jpg` (frasco + caja) |
| `MouseRegion.onEnter` sobre foto| `good_girl_hover.jpg`   (frasco solo)   |
| `MouseRegion.onExit`            | Vuelve a `good_girl_primary.jpg`        |
| Touch / móvil                   | Siempre `good_girl_primary.jpg`         |

- Transición: `AnimatedSwitcher` de **180 ms** con `Curves.easeOut` /
  `Curves.easeIn`. Cross-fade puro, sin zoom / giro / desplazamiento /
  cambio de tamaño.
- El área activa es **solo** el contenedor de la foto. Pasar el mouse
  sobre marca, nombre, categoría, precio, stock, corazón, "Ver detalle"
  o "Agregar al carrito" **no** dispara el swap.
- El resto de tarjetas del catálogo (Dior Sauvage, Royal Amber, etc.)
  siguen funcionando exactamente como antes.

## Assets

Ambas imágenes están dentro del proyecto y se empaquetan por Flutter web:

```
frontend/assets/productos/good_girl/
  good_girl_primary.jpg   (49 944 bytes — frasco + caja)
  good_girl_hover.jpg     (35 244 bytes — frasco solo)
```

En `pubspec.yaml` se agregó una única línea:

```yaml
- assets/productos/good_girl/
```

**Nota importante sobre pubspec.yaml de Flutter**: las declaraciones de
carpeta **no son recursivas**. `- assets/productos/` sólo copia los
archivos que están directamente dentro de esa carpeta; los subdirectorios
requieren una entrada propia. Esto es por qué el primer intento de build
web dejó `Royal-Amber.png` empaquetado pero no `good_girl/*.jpg`.

## Arquitectura

Se creó un widget pequeño y reutilizable:

```
frontend/lib/widgets/catalog/hover_product_image.dart  (nuevo)
```

Parámetros:

- `primaryAsset` — path del asset visible en estado normal
- `hoverAsset`   — path del asset visible durante hover
- `fit`          — `BoxFit.contain` por defecto
- `compact`      — ajusta el radio de sombra 3D según el ancho de tarjeta
- `transitionDuration` — 180 ms por defecto
- `semanticLabel` — para accesibilidad

Aunque el widget está preparado para reutilizarse, actualmente **sólo lo
consume `ProductImage`** cuando detecta `brand == "Carolina Herrera"` +
`name == "Good Girl"`. Todos los demás productos siguen el flujo normal
(three-level fallback: `imageUrl` propio → `CatalogImageResolver` →
`ProductPlaceholder`).

### Cómo se detecta el mouse enter / exit

`MouseRegion` estándar de Flutter:

```dart
MouseRegion(
  onEnter: (_) => setState(() => _hovered = true),
  onExit:  (_) => setState(() => _hovered = false),
  child: ...,
)
```

En dispositivos táctiles Flutter no emite eventos `onEnter` / `onExit`, así
que en móvil `_hovered` queda siempre en `false` y se muestra la imagen
principal. Sin gestos artificiales, sin timers.

### Cómo se garantiza el mismo tamaño en ambas imágenes

- Ambas `Image.asset(...)` llevan `fit: BoxFit.contain`,
  `width: double.infinity`, `height: double.infinity`, `gaplessPlayback:
  true`.
- El `AnimatedSwitcher` usa un `layoutBuilder` con `Stack` +
  `StackFit.expand` para que el hijo entrante y el saliente ocupen el
  mismo bounding box durante el cross-fade.
- Cada frame lleva su `ValueKey<String>(asset)` distinto para que
  `AnimatedSwitcher` los trate como frames diferentes.

Resultado: la tarjeta **nunca** cambia de altura, precio / stock /
botones no se mueven, no se reintroduce ningún `BOTTOM OVERFLOWED` ni
`RIGHT OVERFLOWED`.

### Precarga

Ambos assets se precargan una única vez desde `didChangeDependencies`
con `precacheImage(AssetImage(...), context)` bajo una guarda booleana
`_precached`. El primer hover ya no muestra flash blanco ni load lag.

### Compatibilidad con la sombra 3D existente

`ProductImage` normalmente envuelve la imagen en un `_BottleShadow`
(Stack + Transform.translate + ImageFiltered.blur + ColorFiltered) para
lograr el efecto premium tipo Jomashop / Carolina Herrera. Ese widget
duplica el hijo internamente (una capa como sombra difuminada, otra como
imagen real), lo cual causaría "ghosting" si el hijo respondiera al
mouse porque cada capa tendría su propio `State`.

`HoverProductImage` resuelve esto reproduciendo la sombra internamente,
compartiendo el mismo `_hovered` bool para las dos capas. Así, cuando se
hace hover, la sombra también morphea al packshot del hover y no queda
la silueta antigua flotando detrás.

## Cómo se activa (código en `product_image.dart`)

```dart
bool _isGoodGirlCarolinaHerrera({String? name, String? brand}) {
  final n = name?.trim().toLowerCase();
  final b = brand?.trim().toLowerCase();
  return n == 'good girl' && b == 'carolina herrera';
}
```

Y en `build`:

```dart
if (_isGoodGirlCarolinaHerrera(name: productName, brand: brandName)) {
  return Container(
    width: double.infinity,
    color: Colors.white,
    padding: /* ... */,
    alignment: Alignment.center,
    child: HoverProductImage(
      primaryAsset: 'assets/productos/good_girl/good_girl_primary.jpg',
      hoverAsset:   'assets/productos/good_girl/good_girl_hover.jpg',
      compact: useCompact,
      semanticLabel: 'Good Girl de Carolina Herrera',
    ),
  );
}
```

## Validación

- ✅ `flutter analyze` — No issues found
- ✅ `flutter test` — 14/14 tests pasan, incluye
  `product_card_overflow_test.dart` (21 combinaciones ancho × alto)
- ✅ `flutter build web` — Built build/web con ambos JPG empaquetados en
  `build/web/assets/assets/productos/good_girl/`
- ✅ Manual en Chrome: hover cambia imagen, salir la revierte, no parpadea,
  no salta el layout, sin errores en consola

## Archivos tocados

| Archivo                                                                    | Cambio                    |
|----------------------------------------------------------------------------|---------------------------|
| `frontend/lib/widgets/catalog/hover_product_image.dart`                    | **nuevo**                 |
| `frontend/lib/widgets/catalog/product_image.dart`                          | +rama Good Girl (≈27 LoC) |
| `frontend/pubspec.yaml`                                                    | +1 línea (subcarpeta)     |
| `frontend/assets/productos/good_girl/good_girl_primary.jpg`                | asset nuevo (49 944 B)    |
| `frontend/assets/productos/good_girl/good_girl_hover.jpg`                  | asset nuevo (35 244 B)    |

Los `.png` de la misma carpeta (`good_girl_primary.png`, `good_girl_hover.png`)
son las fuentes originales antes de convertir a JPG. No están referenciados
por el código pero se conservan por si el usuario quiere volver al PNG en
el futuro.

## Cómo generalizar esto al resto del catálogo (siguiente iteración)

El widget `HoverProductImage` ya es genérico. Para llevarlo a todos los
productos hay que:

1. Añadir un campo opcional `imagenSecundariaUrl` (o `imagenHoverUrl`) al
   modelo `Product` y a `Product.fromJson`.
2. Reflejar el mismo campo en el schema Prisma
   (`backend/prisma/schema.prisma`) — string nullable en `Producto`.
3. Actualizar `productos.service.js` para leer/escribir el nuevo campo.
4. Actualizar `product_form.dart` en el admin para permitir cargar dos
   imágenes.
5. En `ProductImage`, cuando exista `imagenSecundariaUrl`, delegar a
   `HoverProductImage` con `primaryAsset = imageUrl`,
   `hoverAsset = imagenSecundariaUrl`, sin depender ya del hardcode
   marca+nombre.
6. Retirar el bloque `_isGoodGirlCarolinaHerrera(...)` de `product_image.dart`.

Esa generalización requiere migración de DB (`prisma db push`) y ajustes
en el UI de admin. Se dejó fuera de esta prueba porque el usuario pidió
validar el efecto visual antes de comprometer cambios de modelo.
