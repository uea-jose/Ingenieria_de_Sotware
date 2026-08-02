# Diseno Tecnico - Gestion de Perfumes y Acordes

Fecha: 2026-08-02  
Codigo sugerido: AS-063  
Area: Frontend Flutter Web  
Estado: Diseno aprobado para revision, pendiente de implementacion

## Proposito

Construir una pantalla administrativa para crear o editar el perfil aromatico de un perfume. La pantalla debe funcionar primero como molde visual e interactivo local, sin guardar todavia en backend.

La prioridad es validar la experiencia: barras, orden, formulario, responsive y vista previa.

## Ruta propuesta

Ruta visual futura:

```text
/admin/perfumes/acordes
```

Archivo principal sugerido:

```text
frontend/lib/screens/admin/product_accord_editor_page.dart
```

## Estructura de carpetas propuesta

```text
frontend/lib/screens/admin/
  product_accord_editor_page.dart

frontend/lib/widgets/admin/
  accord_editor_panel.dart
  accord_slider_row.dart
  accord_picker_field.dart
  product_admin_form_panel.dart
  product_admin_preview_card.dart
  admin_section_card.dart

frontend/lib/models/
  aroma_accord.dart
  product_accord_profile.dart
```

Esta estructura separa pantalla, widgets reutilizables y modelos locales. Si luego el modulo crece, se puede migrar a una carpeta `features/admin/product_accords/`.

## Layout escritorio

El ancho principal debe estar centrado y dejar aire lateral.

```text
Pantalla
  Header interno / navegacion
  Contenedor central maximo
    Titulo del modulo
    Grid principal
      Columna izquierda: editor de acordes
      Columna derecha: datos del perfume y vista previa
    Zona inferior: resultados o perfumes similares futuros
```

### Columna izquierda

Debe contener:

- buscador o selector de perfume base;
- boton agregar acorde;
- boton reset;
- listado de acordes;
- barras de intensidad;
- accion de eliminar acorde.

### Columna derecha

Debe contener:

- nombre del perfume;
- casa fabricante / marca;
- genero;
- precio;
- unidades;
- volumen;
- descripcion;
- vista previa de tarjeta.

## Layout movil

En pantallas pequenas, el orden cambia:

1. titulo breve;
2. editor de acordes;
3. genero y acciones rapidas;
4. seccion desplegable "Datos avanzados del perfume";
5. vista previa;
6. resultados o similares futuros.

La segunda parte del video confirma que en movil el foco debe estar primero en editar acordes. El formulario completo no debe empujar el editor hacia abajo.

## Componentes

### `ProductAccordEditorPage`

Pantalla contenedora. Maneja estado local de demostracion:

- perfume seleccionado;
- acordes actuales;
- genero;
- formulario local;
- estado de seccion avanzada en movil.

### `AccordEditorPanel`

Panel principal del perfil aromatico. Muestra:

- encabezado;
- accion agregar;
- reset;
- listado ordenado de acordes;
- mensaje vacio si no hay acordes.

### `AccordSliderRow`

Fila de acorde. Recibe:

- nombre;
- color;
- intensidad;
- callback de cambio;
- callback de eliminar.

Debe evitar cambios bruscos de alto mientras se mueve la barra.

### `AccordPickerField`

Selector visual para agregar acordes. Debe mostrar:

- bolita de color;
- nombre del acorde;
- lista de opciones disponibles.

### `ProductAdminFormPanel`

Formulario administrativo del perfume. En escritorio aparece visible a la derecha. En movil se ubica dentro de una seccion desplegable.

### `ProductAdminPreviewCard`

Vista previa visual del perfume. No guarda informacion; ayuda a validar como se vera el producto.

## Modelo local sugerido

```dart
class AromaAccord {
  const AromaAccord({
    required this.id,
    required this.name,
    required this.color,
    required this.intensity,
  });

  final String id;
  final String name;
  final Color color;
  final double intensity;
}
```

Para la primera etapa puede vivir en memoria. Despues se conectara con API y base de datos.

## Reglas de orden

- Ordenar por intensidad descendente.
- Mantener orden estable en empates.
- Recalcular al terminar o durante el movimiento, segun fluidez visual.
- Evitar que el usuario pierda el control del slider mientras arrastra.

Si el reordenamiento durante el arrastre se siente brusco, se puede aplicar al soltar la barra.

## Colores de acordes

Los colores deben estar definidos en un mapa central, no quemados dentro del widget.

Ejemplo:

```text
dulce: rosa intenso suave
aromatico: verde menta
citrico: amarillo luminoso
fresco especiado: verde lima
fresco: celeste
amaderado: marron suave
mineral: turquesa grisaceo
salado: azul muy claro
marino: azul
```

La paleta debe adaptarse a Aromas Store: pastel elegante, legible y no infantil.

## Estados visuales

- Estado inicial con perfume de demostracion.
- Estado sin acordes con mensaje claro.
- Estado con acorde seleccionado.
- Estado de slider activo.
- Estado responsive movil.
- Estado de formulario avanzado abierto/cerrado.

## Integracion futura

Cuando el molde visual sea aprobado, se podra conectar:

- `GET /api/productos` para seleccionar perfume;
- `GET /api/productos/:id` para cargar datos;
- endpoint futuro de acordes;
- endpoint futuro de perfil aromatico por producto;
- auditoria backend para guardar TraceId y GUIDSESION en cambios administrativos.

## Pruebas recomendadas

Primera etapa visual:

- `flutter analyze`;
- ejecutar Flutter Web en `127.0.0.1:8082`;
- revisar escritorio;
- revisar ancho movil aproximado de 400 px;
- mover barras;
- agregar acorde;
- quitar acorde;
- reset;
- abrir/cerrar datos avanzados.

Etapa futura con backend:

- pruebas de carga de producto;
- pruebas de guardado;
- pruebas de permisos por rol;
- pruebas de auditoria.

## Riesgos

- Reordenar mientras se arrastra puede generar saltos visuales.
- Demasiados campos visibles pueden saturar el modulo en movil.
- Colores de acordes con bajo contraste pueden afectar accesibilidad.
- Implementar backend demasiado pronto puede atrasar la validacion visual.

## Decision actual

Primero se implementara el molde visual local. No se agregaran nuevas tablas ni endpoints hasta validar la experiencia.
