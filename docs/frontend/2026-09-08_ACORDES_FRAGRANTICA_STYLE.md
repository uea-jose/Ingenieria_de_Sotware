# Implementación de Acordes — Estilo Fragrantica

**Fecha:** 2026-09-08  
**Referencia visual:** https://www.fragrantica.es/accords-search/  
**Estado:** Implementado, pendiente hot-restart para ver cambios visuales

---

## Resumen de lo implementado

Se rediseñaron los widgets de acordes para replicar las proporciones, densidad y
estética visual de Fragrantica, y se creó una nueva página pública de búsqueda
por acordes.

---

## Archivos modificados / creados

### 1. `frontend/lib/widgets/product/accord_bar_row.dart` *(modificado)*

Widget reutilizable de fila compacta de acorde. Usado en el editor admin y en
la página pública.

**Especificaciones visuales:**
- Altura total de fila: **26 px**
- Altura de barra: **22 px**
- Ancho columna nombre: **90 px**, alineado a la izquierda
- Track gris: `#3A3A3A`
- Color del acorde rellena desde la izquierda según `intensity` (1–100)
- Gap entre filas: **4 px** (gestionado por el padre)
- `×` de eliminación: color `#AA4444`, 16 px de ancho
- En `editMode: true` usa `GestureDetector` para drag/tap (evita el
  touch-target de 48 px del `Slider` nativo de Flutter que inflaba las filas)
- En `editMode: false` es solo lectura (usado en detalle de producto)

**Parámetros:**
```dart
AccordBarRow(
  name: 'dulce',
  colorHex: '#EE363B',
  intensity: 75,          // 1–100
  editMode: true,         // false = solo lectura
  onIntensityChanged: (v) => ...,
  onRemove: () => ...,
)
```

---

### 2. `frontend/lib/features/admin/accord_editor/accord_editor_page.dart` *(modificado)*

Editor admin en `/admin/acordes`.

**Cambios:**
- Eliminada la clase interna `_AccordRow` (tarjetas grandes de 76 px)
- Eliminados `_valueControllers` y `_valueFocusNodes` (ya no hay TextField numérico)
- Ahora usa `AccordBarRow(editMode: true)` dentro de un `Container` oscuro `#1A1A1A`
- Stack animado: 30 px por slot (26 fila + 4 gap)
- Padding del contenedor: `horizontal: 14, vertical: 12`

---

### 3. `frontend/lib/widgets/product/accord_profile_panel.dart` *(creado)*

Panel de lectura de acordes para la página de detalle de producto.

**Comportamiento:**
- Carga `/api/productos/:id/acordes` al montarse
- Si 404 o sin acordes → `SizedBox.shrink()` (no muestra nada)
- Normaliza intensidades al máximo para que la barra más intensa = 100% ancho
- Nombre del acorde centrado **dentro** de la barra (estilo detalle Fragrantica)
- Container `#1A1A1A`, filas 28 px, gap 3 px
- Título "acordes principales" encima en texto pequeño gris

---

### 4. `frontend/lib/screens/product_detail/product_detail_page.dart` *(modificado)*

- Reemplazado `ProductFutureAccordsPlaceholder` por `AccordProfilePanel(productId: product.id)`

---

### 5. `frontend/lib/data/api/api_service.dart` *(modificado)*

Nuevos métodos estáticos:

```dart
// Carga catálogo maestro de acordes desde /api/acordes
static Future<List<AromaAccord>> loadAccords()

// Busca productos por acordes (con fallback a todos los productos)
static Future<List<Product>> searchByAccords(Map<String, int> accordIntensities)
```

El `searchByAccords` construye query string `?slug=intensity&...` y tiene
fallback a `/productos` completo si el backend no soporta ese filtro.

---

### 6. `frontend/lib/screens/accord_search/accord_search_page.dart` *(creado)*

Nueva página pública en ruta `/acordes`.

**Layout:**
- Fondo oscuro `#1A1A1A` en toda la página
- Título "Buscar por acordes" + subtítulo en blanco/gris
- Desktop (≥ 680 px): dos columnas — izquierda 42% (panel acordes) + derecha 58% (resultados)
- Mobile (< 680 px): columna única

**Panel izquierdo (`_AccordPanel`):**
- Container `#242424` con padding 16 px
- Dropdown con **fondo oscuro** `#2E2E2E` + **bolita circular de color** por cada acorde
- Botón "+ Añadir" verde `#2B7A5E` (igual que Fragrantica)
- Botón "Reset" con borde gris
- Lista de barras usando `AccordBarRow(editMode: true)`
- Máximo 8 acordes
- Debounce de 450 ms antes de lanzar búsqueda

**Panel derecho (`_ResultsPanel`):**
- Cards oscuras `#242424` con borde `#333333`
- Thumbnail 64×64, nombre producto, marca, precio en teal `#4ECDC4`
- Click navega a `ProductDetailPage`

---

### 7. `frontend/lib/app/aromas_store_app.dart` *(modificado)*

Ruta registrada:
```dart
routes: {
  '/admin/acordes': (context) => const AccordEditorPage(),
  '/acordes':       (context) => const AccordSearchPage(),
}
```

---

### 8. `frontend/lib/widgets/layout/top_navigation.dart` *(modificado)*

Agregado enlace en la barra de navegación desktop:
```dart
_NavButton(
  label: 'Buscar por acordes',
  onPressed: () => Navigator.of(context).pushNamed('/acordes'),
),
```

---

## Pendiente / próximos pasos

- [ ] El backend no tiene endpoint dedicado de búsqueda por acordes — actualmente
      `searchByAccords` hace fallback a todos los productos. Implementar filtro
      real en `/api/productos?slug=intensity` en el backend.
- [ ] Verificar visualmente después de hot-restart completo (q + volver a ejecutar Flutter)
- [ ] Las barras del editor admin aún se ven grandes en pantalla — puede ser
      tema de device pixel ratio. Valores actuales: rowH=26, barH=22.
- [ ] Agregar filtros adicionales al panel derecho: género, año, marca
      (como los tiene Fragrantica a la derecha del panel de acordes)
- [ ] El `AccordProfilePanel` en detalle de producto solo se muestra si el
      producto tiene acordes asignados desde el editor admin

---

## Cómo probar

```powershell
# Levantar backend
cd backend
npm run dev

# Levantar frontend (compilación limpia)
cd frontend
C:\javilar\flutter\bin\flutter.bat run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

- **Editor admin:** `http://127.0.0.1:8080/#/admin/acordes`
  - Credenciales: `admin@aromasstore.com` / `Admin12345`
- **Búsqueda pública:** `http://127.0.0.1:8080/#/acordes`
  - O desde la barra de navegación → "Buscar por acordes"

---

## Referencia visual

La implementación toma como referencia directa la página de Fragrantica:
`https://www.fragrantica.es/accords-search/`

Se replicaron:
- Proporciones de columnas (42% / 58%)
- Densidad de filas
- Colores del tema oscuro
- Bolitas de color en el dropdown
- Barras con track gris + fill de color por intensidad
- Botones "+ Añadir" (verde) y "Reset" (gris outline)

**No se copió:** logotipo, textos propios, marca, publicidad, flores decorativas.
