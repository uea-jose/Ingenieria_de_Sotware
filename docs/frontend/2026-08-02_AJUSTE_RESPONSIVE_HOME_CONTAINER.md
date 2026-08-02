# Ajuste Responsive - Contenedor Central Frontend

Fecha: 2026-08-02  
Codigo sugerido: AS-064  
Area: Frontend Flutter Web  
Estado: Implementado en tercera revision

## Motivo

Al revisar la Home pastel desde celular se detectaron dos problemas:

- algunas tarjetas de producto desbordaban verticalmente el boton de carrito;
- la pagina se sentia pesada al hacer scroll en telefono.

Tambien se definio una regla visual importante: las paginas principales deben comportarse como un `container` de Bootstrap, es decir, el contenido debe vivir dentro de un ancho maximo estable y dejar espacio lateral en pantallas grandes.

## Decision

Se centralizo una regla de layout en los tokens visuales con comportamiento inspirado en `.container` de Bootstrap, pero ajustado al objetivo visual del proyecto: dejar un panel claramente centrado en escritorio.

```text
<576px: 100%
>=576px: 540px
>=768px: 720px
>=992px: 960px
>=1200px: 1000px
>=1400px: 1000px
padding movil: 16px
padding escritorio: 24px
```

Esta regla permite que las secciones mantengan un bloque central consistente en escritorio, tablet y celular, evitando que la Home se estire a todo el ancho disponible en monitores grandes.

## Cambios aplicados

- Se agrego `AppLayout` en los tokens de diseno.
- `AppLayout` ahora calcula el ancho maximo por breakpoint, con tope visual de 1000px para que el contenido quede como una caja central mas compacta.
- La navegacion superior dejo de verse como una franja blanca completa y ahora se presenta como panel central con borde y sombra suave.
- Las tarjetas de producto se compactaron para el nuevo ancho: imagen menor, menos padding, texto y precio mas contenidos.
- Las grillas permiten cuatro columnas compactas desde 960px de ancho util.
- En viewport tipo celular de 400px, la grilla cambia a dos columnas para evitar perfumes gigantes de una sola columna.
- Se agrego un modo mini en las tarjetas de producto: badges, favoritos, textos, precio y boton de carrito mas pequenos.
- La grilla del catalogo ahora calcula su espacio lateral como un contenedor central.
- Se corrigio el header en laptop: marca, menu, favoritos, carrito e inicio de sesion se reorganizan en lineas limpias cuando no caben en una sola fila.
- Los filtros de catalogo dejaron de usar una fila rigida y ahora se distribuyen con `Wrap`, anchos controlados y desplegables expandidos.
- Se eliminaron el titulo y la descripcion redundantes de `Catalogo publico`, conservando contador, filtros y productos.
- Las etiquetas `Disponible`, `Ultimas unidades` y `Stock` se redujeron para quedar proporcionadas con las tarjetas compactas.
- Se corrigio el overflow vertical de tarjetas en pantalla dividida: la grilla de dos columnas gano alto controlado y la card usa imagen/descripcion/boton mas compactos cuando el ancho es intermedio.
- Se optimizo el scroll en telefono: el carrusel ya no captura gesto horizontal en movil, las sombras moviles son mas livianas y la grilla de dos columnas gano margen vertical para evitar repintados por overflow.
- Header, barra superior, hero, filtros, encabezado de catalogo, franjas comerciales y footer usan el mismo criterio de contenedor.
- La pagina de detalle de producto usa el mismo contenedor central.
- El molde interno de administracion de acordes usa el mismo contenedor central en login y editor.
- Las tarjetas de producto tienen mas alto en una columna movil.
- Las imagenes de producto son mas compactas en telefono.
- El hero reduce altura, padding y texto visible en movil.
- Las sombras en tarjetas moviles son mas livianas para mejorar el scroll.
- Los filtros y navegacion usan menos margen lateral en pantallas pequenas.
- `api_config.dart` ahora puede recibir la URL del backend por `--dart-define=API_BASE_URL`.

## Prueba desde celular

Comando recomendado para levantar Flutter Web en red local:

```powershell
cd C:\Users\Jose\Documents\proyectospERFUMES\aromas-store\frontend
C:\javilar\flutter\bin\flutter.bat run -d web-server --web-hostname 0.0.0.0 --web-port 8082 --dart-define=API_BASE_URL=http://192.168.100.229:3000
```

URL desde celular:

```text
http://192.168.100.229:8082
```

## Alcance

Este ajuste no agrega pantallas nuevas ni cambia funcionalidades. Solo mejora responsive, contenedor central, configuracion de API para red local y estabilidad visual de Home, catalogo, detalle de producto y molde de acordes.

## Pendiente

- Revisar visualmente en celular real despues de levantar con `API_BASE_URL`.
- Ajustar detalles finos de menu movil si todavia se siente alto.
- Aplicar el mismo criterio de `AppLayout` a futuras pantallas administrativas.
