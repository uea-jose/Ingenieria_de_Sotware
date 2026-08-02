# Ajuste Responsive - Contenedor Central Frontend

Fecha: 2026-08-02  
Codigo sugerido: AS-064  
Area: Frontend Flutter Web  
Estado: Implementado en segunda revision

## Motivo

Al revisar la Home pastel desde celular se detectaron dos problemas:

- algunas tarjetas de producto desbordaban verticalmente el boton de carrito;
- la pagina se sentia pesada al hacer scroll en telefono.

Tambien se definio una regla visual importante: las paginas principales deben comportarse como un `container` de Bootstrap, es decir, el contenido debe vivir dentro de un ancho maximo estable y dejar espacio lateral en pantallas grandes.

## Decision

Se centralizo una regla de layout en los tokens visuales con comportamiento equivalente a `.container` de Bootstrap 5:

```text
<576px: 100%
>=576px: 540px
>=768px: 720px
>=992px: 960px
>=1200px: 1140px
>=1400px: 1320px
padding movil: 16px
padding escritorio: 24px
```

Esta regla permite que las secciones mantengan un bloque central consistente en escritorio, tablet y celular, evitando que la Home se estire a todo el ancho disponible en monitores grandes.

## Cambios aplicados

- Se agrego `AppLayout` en los tokens de diseno.
- `AppLayout` ahora calcula el ancho maximo por breakpoint, siguiendo la tabla de Bootstrap 5.
- La grilla del catalogo ahora calcula su espacio lateral como un contenedor central.
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
