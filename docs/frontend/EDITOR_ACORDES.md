# Editor Flutter de acordes

## Acceso

Ruta administrativa:

```text
/admin/acordes
```

En Flutter Web puede abrirse con:

```text
http://localhost:PUERTO/#/admin/acordes
```

El acceso usa el mismo inicio de sesión JWT del backend principal.

## Flujo implementado

1. Iniciar sesión como administrador.
2. Seleccionar el producto que se editará.
3. Seleccionar la casa y el perfume de referencia.
4. Copiar el perfil maestro si el producto todavía no tiene uno.
5. Modificar intensidades mediante mouse, pantalla táctil, teclado o campo
   numérico.
6. Agregar o eliminar acordes.
7. Guardar, deshacer cambios locales o restaurar el perfil maestro.

## Comportamiento de las barras

- Las intensidades admiten valores entre 1 y 100.
- El orden visible se actualiza durante la interacción.
- Los valores mayores aparecen arriba.
- Los empates conservan el orden relativo anterior.
- Cada fila mantiene una clave estable para conservar su control durante el
  movimiento.
- `ordenVisual` se recalcula desde 1 antes de guardar.
- La posición se anima durante 220 milisegundos.

## Archivos

```text
lib/features/admin/accord_editor/accord_editor_page.dart
lib/features/admin/accord_editor/accord_sorting.dart
lib/data/api/catalog_admin_api.dart
lib/models/aroma_accord.dart
lib/models/accord_profile.dart
lib/models/perfume_reference.dart
```

Los colores se obtienen de `colorHex` y `colorTextoHex` enviados por el
backend. No se escriben colores de acordes dentro del componente.

## Validación

- pruebas unitarias del ordenamiento estable;
- prueba de copia, edición, guardado y restauración contra PostgreSQL;
- compilación Flutter Web;
- revisión visual e interacción real en navegador.
