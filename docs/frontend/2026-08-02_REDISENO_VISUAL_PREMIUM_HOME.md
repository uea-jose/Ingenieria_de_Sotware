# Rediseno Visual Premium de la Home - 2026-08-02

## Objetivo

Actualizar la primera pantalla publica de Aromas Store para que deje de verse como una maqueta pastel amplia y pase a una interfaz mas editorial, comercial y adaptable, manteniendo intactas las funciones existentes.

## Alcance aplicado

- Se centralizo una identidad visual premium con fondo claro, superficies blancas, texto oscuro, acento vino y detalles calidos.
- Se ajusto el header en tres niveles: barra informativa, cabecera principal y navegacion.
- Se adapto el header movil con menu, logo, carrito y buscador en una segunda linea.
- Se redisenaron hero, franja de confianza, tarjetas comerciales, banner de promociones, catalogo y footer.
- Se compactaron las tarjetas de producto para evitar tarjetas gigantes en escritorio, pantalla dividida y celular.
- Se redujo peso visual en sombras y bloques repetidos para mejorar desplazamiento en movil.

## Funcionalidades conservadas

- Carga de productos desde API y catalogo local de demostracion.
- Busqueda principal y busqueda del catalogo.
- Filtros por categoria y marca.
- Vista de detalle del producto.
- Carrito visual y funcional.
- Validacion de carrito contra backend.
- Persistencia local del carrito.
- Botones existentes de navegacion, promociones, favoritos e inicio de sesion visual.

## Archivos principales modificados

- `frontend/lib/app/app_design_tokens.dart`
- `frontend/lib/app/app_theme.dart`
- `frontend/lib/screens/home/home_page.dart`
- `frontend/lib/screens/home/home_commercial_sections.dart`
- `frontend/lib/widgets/layout/top_navigation.dart`
- `frontend/lib/widgets/layout/brand_mark.dart`
- `frontend/lib/widgets/layout/premium_announcement_bar.dart`
- `frontend/lib/widgets/layout/cart_nav_button.dart`
- `frontend/lib/widgets/catalog/product_grid.dart`
- `frontend/lib/widgets/catalog/product_card.dart`
- `frontend/lib/widgets/catalog/product_image.dart`
- `frontend/lib/widgets/catalog/product_badges.dart`
- `frontend/lib/widgets/catalog/catalog_section_header.dart`
- `frontend/lib/widgets/cart/cart_preview_bar.dart`

## Decisiones de diseno

- El ancho global queda controlado por `AppLayout.contentMaxWidth`, simulando el comportamiento de un container responsive.
- Las tarjetas reducen alto, imagen y textos para entrar mejor en grillas de 2, 3 y 4 columnas.
- Las imagenes de producto usan ajuste tipo `contain` para que una botella real no se recorte.
- En movil se prioriza lectura y control de overflow antes que efectos pesados.
- El estado visual premium queda centralizado en tokens para facilitar ajustes posteriores sin perseguir colores por todo el codigo.

## Verificacion realizada

- Formato aplicado con Dart.
- Analisis estatico ejecutado con `dart analyze`.
- Resultado: sin errores.

## Pendiente recomendado

- Revisar visualmente en navegador a 1366 px, pantalla dividida, 430 px, 390 px y desde celular real.
- Si el scroll movil sigue lento, reducir aun mas sombras, animaciones hover y cantidad de productos iniciales visibles.
- Documentar una prueba visual con capturas antes de continuar con nuevas paginas.
