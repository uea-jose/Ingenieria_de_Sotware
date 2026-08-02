# Requerimiento - Gestion de Perfumes y Acordes

Fecha: 2026-08-02  
Codigo sugerido: AS-063  
Modulo: Frontend administrativo / gestion de catalogo  
Estado: Definido, pendiente de implementacion visual

## Objetivo

Definir una pantalla interna para registrar o editar perfumes junto con su perfil aromatico. La pantalla debe permitir que un usuario administrativo configure datos basicos del producto y ajuste acordes mediante barras de intensidad.

Esta pantalla no reemplaza el catalogo publico. Su uso principal es interno: preparar la informacion del perfume antes de mostrarla al cliente.

## Usuarios

- Administrador: puede crear y editar perfumes, acordes y datos comerciales.
- Bodeguero: puede apoyar con datos de inventario, unidades, stock y disponibilidad.

La definicion exacta de permisos se conectara despues con el login y los roles del backend.

## Alcance de la primera etapa

La primera etapa debe construir el molde visual y la interaccion local principal:

- formulario visual de producto;
- editor de acordes con barras;
- seleccion de genero;
- agregar y quitar acordes;
- reset visual;
- reordenamiento local por intensidad;
- vista responsive para escritorio y movil.

No se debe conectar todavia el guardado real contra backend en esta primera etapa.

## Campos del perfume

La pantalla debe considerar estos datos:

| Campo | Descripcion | Estado inicial |
|---|---|---|
| Nombre del perfume | Nombre comercial del producto. | Visual/local |
| Casa fabricante o marca | Marca asociada, por ejemplo Giorgio Armani. | Visual/local |
| Genero | Masculino, femenino o unisex. | Visual/local |
| Precio | Precio comercial del producto. | Visual/local |
| Unidades o stock | Cantidad disponible para inventario. | Visual/local |
| Volumen | Contenido en ml cuando aplique. | Visual/local |
| Descripcion | Texto descriptivo del perfume. | Visual/local |
| Imagen | Imagen futura del producto. | Visual/local |

## Perfil aromatico

Cada perfume podra tener varios acordes. Un acorde representa una familia o sensacion aromatica, por ejemplo:

- dulce;
- aromatico;
- citrico;
- fresco especiado;
- fresco;
- amaderado;
- mineral;
- salado;
- marino;
- avainillado;
- frutal;
- floral.

Cada acorde debe tener:

- nombre;
- color propio;
- intensidad de 0 a 100;
- barra deslizable;
- accion para quitarlo.

## Comportamiento esperado

### Barras

- El usuario debe poder mover la intensidad arrastrando la barra.
- La barra debe mostrar visualmente la intensidad actual.
- Cada acorde debe conservar su color propio.
- La interaccion debe sentirse directa, precisa y facil de entender.

### Orden automatico

- Los acordes deben ordenarse de mayor a menor intensidad.
- Si una barra baja, ese acorde puede bajar de posicion.
- Si una barra sube, ese acorde puede subir de posicion.
- En empates, el orden debe mantenerse estable para evitar saltos molestos.

### Agregar acorde

- Debe existir una accion para agregar acorde.
- El selector debe mostrar color + nombre del acorde.
- El acorde nuevo debe entrar a la lista con una intensidad inicial razonable.

### Quitar acorde

- Cada fila debe tener una accion clara para retirar el acorde.
- Al quitarlo, la lista debe reajustarse sin perder el resto de valores.

### Reset

- Debe existir una accion para volver al estado inicial.
- En la primera etapa, este reset puede restaurar los valores locales de demostracion.

## Responsive

En escritorio:

- contenedor central con espacio lateral;
- editor de acordes visible al lado del panel de datos;
- vista previa o datos secundarios a la derecha;
- resultados o tarjetas debajo.

En movil:

- primero debe aparecer el editor de acordes;
- despues genero y controles principales;
- los datos pesados del perfume deben ir en una seccion desplegable de datos avanzados;
- las tarjetas o resultados deben aparecer debajo;
- no debe depender de hover.

## Referencias analizadas

Se revisaron los videos:

- `videosPront/calagogoAromasSotoew10.mp4`
- `videosPront/calagogoAromasSotoew11.mp4`

Tambien se revisaron sus transcripciones:

- `videosPront/calagogoAromasSotoew10 (audio-extractor.net).txt`
- `videosPront/calagogoAromasSotoew11 (audio-extractor.net).txt`

La referencia visual se usa solo como inspiracion de comportamiento. Aromas Store debe mantener identidad propia, estilo pastel elegante y componentes adaptados a su dominio.

## Fuera de alcance por ahora

- Guardar acordes en PostgreSQL.
- Crear tablas nuevas para acordes.
- Conectar login real del frontend.
- Implementar panel administrativo completo.
- Crear busqueda real de perfumes similares.
- Copiar diseno exacto de un sitio externo.

## Proxima decision

Antes de implementar backend, se debe aprobar el molde visual en Flutter Web. Luego se definira el modelo de datos de acordes y su integracion con productos.
