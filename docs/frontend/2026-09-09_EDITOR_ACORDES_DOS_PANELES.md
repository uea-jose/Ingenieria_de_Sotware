# Editor de acordes: biblioteca y perfil en dos paneles

Fecha: 2026-09-09
Rama de trabajo: backup/acordes-antes-split
Estado: implementado; validaciones automáticas aprobadas y diseño de escritorio confirmado en captura del usuario.

## Problema y solución

El selector para agregar acordes usaba un DropdownButtonFormField que abría una capa flotante sobre las barras del perfil. Se sustituyó por una división estructural dentro de la página /#/admin/acordes.

- Panel izquierdo: biblioteca, búsqueda por nombre, slug y alias, punto de color, lista con desplazamiento interno y acción de añadir.
- Los acordes presentes se identifican con una marca y el texto «En el perfil», y no pueden añadirse de nuevo.
- La búsqueda puede limpiarse y muestra un mensaje cuando no hay coincidencias.
- Panel derecho: perfil actual con las barras compactas, colores, eliminación mediante ×, ajuste de intensidad por arrastre y orden existente.
- Escritorio: biblioteca de 300 px, separación de 20 px y perfil ocupando el espacio restante.
- Cuando el ancho disponible del editor es inferior a 760 px, los paneles se apilan.
- La lista tiene altura de 280 px, o 200 px para ventanas de menos de 650 px de alto.
- Se bloquean las interacciones de edición mientras hay una operación en curso.

## Alcance técnico

Archivo de implementación modificado:
frontend/lib/features/admin/accord_editor/accord_editor_page.dart

Se reutilizan _masterAccords, _accords, normalizeAccordOrder y las acciones existentes. La selección de la biblioteca se deriva del perfil actual; no se crea una segunda copia del estado del perfil. El selector temporal se sustituye por controladores de búsqueda y desplazamiento, liberados en dispose.

Se conservan API, modelos, autenticación, guardado, copiar perfil de referencia, restaurar maestro, deshacer cambios y las reglas de intensidad y orden. No se modificaron backend ni la página pública /#/acordes.

Referencia revisada:
docs/frontend/2026-09-08_ACORDES_FRAGRANTICA_STYLE.md

## Validaciones realizadas

- flutter analyze: sin observaciones.
- flutter test: 3 pruebas aprobadas, incluidas las de orden estable y actualización de intensidad.
- flutter build web: compilación exitosa en build/web.
- git diff --check: sin errores.

Advertencia preexistente de compilación: el ensayo de compatibilidad Wasm detecta dart:html en frontend/lib/data/storage/cart_storage.dart. No impidió la compilación web estándar y no se modificó en esta tarea.

## Confirmación visual del usuario

El 2026-09-09 el usuario compartió una captura del editor ejecutándose en http://127.0.0.1:8080/#/admin/acordes y dio conformidad al resultado visual.

La captura muestra el producto «Producto Prueba RF11», seis acordes, la biblioteca filtrada, puntos de color, indicadores de acordes presentes y barras visibles en el panel derecho. También se observan las acciones Deshacer cambios, Restaurar maestro y Guardar.

La captura indica «cambios sin guardar»: constituye evidencia visual del diseño de escritorio, pero no confirma persistencia en el servidor. La revisión inicial del agente en navegador no pudo realizarse porque el servidor local no estaba activo en ese momento.

## Punto de continuación

La implementación y este documento permanecen en la rama de trabajo, sin merge a main. Al guardar esta documentación, la implementación seguía como cambio local sin commit.

Para la siguiente sesión quedan como comprobaciones manuales recomendadas:

- Probar el diseño apilado en móvil y el desplazamiento interno con una lista extensa.
- Verificar añadir, eliminar y cambiar intensidad, incluido el orden resultante.
- Comprobar deshacer, guardar y recargar para confirmar persistencia.
- Comprobar copiar perfil y restaurar maestro sobre un producto de prueba apropiado.

No se programó ninguna continuación automática; se retomará cuando el usuario vuelva.