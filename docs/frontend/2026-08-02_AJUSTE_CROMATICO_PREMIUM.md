# Ajuste Cromatico Premium - 2026-08-02

## Motivo

Despues de revisar el video de referencia `calagogoAromasSotoew13.mp4`, se identifico que la home todavia se percibia demasiado suave y pastel. La referencia visual transmite una tienda mas comercial mediante blanco limpio, negro/oscuro, rojo intenso y bloques con mayor contraste.

## Cambios aplicados

- Se reforzo el color primario hacia un rojo vino mas comercial.
- Se oscurecio el color promocional principal.
- Se redujo la presencia visual de tonos rosa/lavanda como fondos dominantes.
- Se cambio la barra superior informativa a color rojo primario.
- Se ajusto el hero para usar mas superficies blancas y menos degradados suaves.
- Se limpio el fondo de imagen de producto para que las tarjetas dependan menos del pastel decorativo.
- Se mantuvieron tokens centralizados para poder seguir afinando el color sin tocar cada widget manualmente.

## Funcionalidad conservada

No se modificaron rutas, API, busquedas, filtros, carrito, validacion, detalle de producto ni persistencia local.

## Archivos tocados

- `frontend/lib/app/app_design_tokens.dart`
- `frontend/lib/screens/home/home_page.dart`
- `frontend/lib/widgets/layout/premium_announcement_bar.dart`
- `frontend/lib/widgets/layout/brand_mark.dart`
- `frontend/lib/widgets/catalog/product_image.dart`

## Criterio visual pendiente

Validar en navegador y celular real si el resultado ya se acerca al tono buscado. Si aun falta fuerza visual, el siguiente ajuste recomendado es incorporar imagenes reales o fondos fotograficos en el hero, porque el color por si solo no logra el impacto comercial de la referencia.
