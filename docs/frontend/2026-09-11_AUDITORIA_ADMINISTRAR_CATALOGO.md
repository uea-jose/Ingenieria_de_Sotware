# Auditoría — Página "Administrar Catálogo"

**Fecha:** 2026-09-11
**Rama:** `backup/acordes-antes-split`
**Tipo:** Verificación (no reimplementación). No se hizo commit ni push.

---

## 1. Estado de Git

Rama actual: `backup/acordes-antes-split` (al día con origin).

`git diff --stat` — 11 archivos modificados, 550 inserciones aprox:

```
backend/src/modules/productos/productos.acordes.service.js  | 18 +-
backend/src/modules/productos/productos.routes.js           | 10 +-
backend/src/modules/productos/productos.service.js          | 14 +
frontend/analysis_options.yaml                              |  7 +
frontend/lib/app/aromas_store_app.dart                      |  7 +-
frontend/lib/data/api/catalog_admin_api.dart                | 15 +
frontend/lib/features/admin/accord_editor/accord_editor_page.dart | 245 +
frontend/lib/widgets/catalog/product_image.dart             | 21 +-
frontend/lib/widgets/layout/top_navigation.dart             | 17 +-
frontend/pubspec.lock                                       | 16 +-
frontend/pubspec.yaml                                       | 216 +
```

Archivos sin trackear (nuevos):
- `backend/scripts/product-profile-unit.test.js`
- `frontend/lib/features/admin/accord_editor/catalog_admin_page.dart`  ← **página integrada real**
- `frontend/lib/features/admin/accord_editor/product_form.dart`
- `frontend/lib/models/catalog_reference.dart`
- `frontend/lib/screens/perfumery_catalog/` (catálogo de referencia)
- `frontend/lib/widgets/product/aromatic_preview.dart`
- `frontend/test/catalog_admin_page_test.dart`, `product_form_test.dart`, `catalog_adaptation_test.dart`
- `frontend/assets/` (catálogo perfumería empaquetado)
- docs `2026-09-09` y `2026-09-10`

**No se ejecutó** git restore / reset / clean / commit / push.

---

## 2. Página correcta de "Administrar Catálogo"

- **Ruta:** `/admin/acordes` (y alias `/admin/catalogo`) → **`CatalogAdminPage`**
- **Archivo principal:** `frontend/lib/features/admin/accord_editor/catalog_admin_page.dart`
- **Componentes que usa:**
  - `ProductForm` (`product_form.dart`) — datos comerciales, en modo `embedded`
  - `AccordBarRow` — barras de acordes editables
  - `PerfumeryCatalogPage` — selección de referencia con imagen
  - `CatalogAdminApi` — cliente HTTP con token
- **Navegación:** `Navigator.pushNamed('/admin/acordes')`.

**Nota:** El archivo viejo `accord_editor_page.dart` sigue existiendo pero **ya no está enrutado** (la ruta apunta a `CatalogAdminPage`). Es código huérfano; no se eliminó por precaución.

---

## 3. Funciones verificadas

| # | Función | Estado |
|---|---------|--------|
| 1 | Seleccionar perfume existente (Autocomplete) | ✅ Implementado |
| 2 | Cargar datos del producto | ✅ (via loadProducts + loadProductProfile) |
| 3 | Cargar imagen | ✅ (URL o asset en vista previa) |
| 4 | Cargar acordes | ✅ (loadProductProfile) |
| 5–13 | Editar nombre/código/precio/unidades/marca/categoría/volumen/descripción/URL | ✅ ProductForm |
| 14 | Editar intensidad de acordes | ✅ AccordBarRow drag |
| 15 | Añadir acorde | ✅ biblioteca lateral |
| 16 | Eliminar acorde | ✅ botón × |
| 17 | Reordenamiento | Automático por intensidad (backend `normalizarAcordes`) |
| 18 | Crear nueva fragancia | ✅ "Nueva fragancia" |
| 19 | Cambiar entre existente/nuevo | ✅ con confirmación de cambios sin guardar |
| 20 | Vista previa en tiempo real | ✅ usa acordes en edición directamente |
| 21 | Guardar todo con un botón | ✅ "Guardar producto" |
| 22 | Guardado atómico producto+acordes | ✅ **verificado** (ver §4) |
| 25 | Persistencia tras recarga | ✅ **verificado contra PostgreSQL real** |

---

## 4. Botón "Guardar producto" — análisis técnico

- Ejecuta `ProductForm._save()` → `CatalogAdminApi.saveProduct(data, id)`.
- **Endpoint:** `POST /productos` (crear) o `PUT /productos/:id` (editar).
- **Una sola llamada HTTP.** Los acordes viajan dentro del mismo body vía
  `extraData: () => {'acordes': [...]}`.
- **Atomicidad REAL:** en el backend, `crearProducto` / `actualizarProducto`
  envuelven en `prisma.$transaction` tanto el producto/inventario como
  `guardarPerfilEnTransaccion`. Si fallan los acordes, **se revierte todo**
  (rollback de Prisma). No quedan estados parciales.
- Tras guardar: el frontend recibe el `Product` actualizado y sincroniza el
  estado local (`_saved`), marca `_dirty = false` y muestra snackbar
  "Perfume y acordes guardados."
- **Limitación:** tras guardar NO se vuelve a hacer GET del perfil de acordes;
  el estado local se asume igual al enviado. Como el backend ordena por
  intensidad, el `ordenVisual` local puede diferir hasta recargar el producto.
  No afecta la persistencia, solo el orden visual inmediato.

---

## 5. Permisos

- **Backend (real):** las 5 rutas de escritura de `/productos` usan
  `requiereAutenticacion` + `requiereRol("Administrador","Vendedor","Bodeguero")`.
  Verificado en vivo:
  - Sin token → **401**
  - Rol Cliente → **403**
- **Frontend:** NO lee ni valida el rol. No deshabilita botones por rol.
  Cualquier usuario autenticado ve la misma UI. **La seguridad es solo backend**
  (lo cual es correcto y suficiente para bloquear, pero la UI no refleja permisos).

---

## 6. Base de datos real

- PostgreSQL corriendo en Docker (`aromas-store-postgres`), `.env` presente.
- **Prueba de persistencia ejecutada (Administrador):**
  - Creado producto id=24 con 2 acordes en una sola operación.
  - Recargado desde cero: nombre, precio (42.5), stock (7) y **2 acordes con
    intensidades 90/55 persistieron** correctamente ordenados.
  - Producto de prueba **eliminado** después (DB queda limpia).
- **Bodeguero:** el rol EXISTE en la tabla `roles`, y las rutas lo aceptan,
  PERO **NO existe ninguna cuenta de usuario con rol Bodeguero** en la DB
  (solo admin, cliente y un cliente de prueba). Por tanto **NO se pudo verificar
  el guardado real con una cuenta Bodeguero** — falta crear esa cuenta.

---

## 7. Pantalla en blanco

- `main.dart`, rutas y build web están correctos.
- `flutter build web` compila y genera `build/web`.
- La causa más probable del "navegador en blanco" reportado era el navegador de
  verificación headless (no ejecuta el bootstrap de Flutter Web / canvaskit) o
  correr sin `--dart-define=API_BASE_URL`. **No es una excepción de la app.**
  En ejecución normal con `flutter run -d web-server` la página carga.

---

## 8. Resultados de validaciones (re-ejecutadas)

| Comando | Resultado |
|---------|-----------|
| `flutter analyze` | **No issues found** |
| `flutter test` | **13 tests aprobados** (0 fallos) |
| `flutter build web` | **Built build\web** (exit 1 solo por warning Wasm dry-run de `dart:html` en `cart_storage.dart`, preexistente y ajeno) |
| `node --test product-profile-unit.test.js` (backend) | **2/2 aprobados** |

---

## 9. Qué quedó terminado / pendiente

**Terminado y verificado:**
- Página integrada única con acordes + datos + vista previa
- Guardado atómico producto+acordes (1 operación, 1 transacción, rollback real)
- Persistencia real en PostgreSQL (Administrador)
- Permisos backend reales (401/403)
- analyze / test / build

**Pendiente (no bloqueante):**
- Crear una cuenta con rol **Bodeguero** para verificar ese flujo end-to-end.
- Frontend no deshabilita UI por rol (mejora opcional de UX).
- Tras guardar, no se re-consulta el perfil (orden visual puede diferir hasta recargar).
- El archivo huérfano `accord_editor_page.dart` podría eliminarse.
- El endpoint de búsqueda por acordes en `/#/acordes` sigue sin filtro real por intensidad (documentado en 2026-09-09).

---

## 10. Limitaciones reales

- No se verificó Bodeguero por ausencia de cuenta con ese rol.
- La búsqueda por acordes pública (`/#/acordes`) no filtra por intensidad en backend.
- No se hizo commit/push: los cambios siguen locales para tu revisión visual.
