# AS-040 - Mejora profesional de la pantalla publica de catalogo

Fecha: 2026-07-09  
Modulo: Frontend Flutter Web  
Pantalla: Inicio / Catalogo publico

## Objetivo

Evolucionar la primera pantalla publica de Aromas Store sin eliminar funcionalidad existente. La mejora mantiene el catalogo conectado al backend y refuerza usabilidad, accesibilidad, confianza comercial y experiencia visual premium.

## Mejoras Aplicadas

| Mejora | Problema detectado | Principio aplicado | Solucion implementada | Beneficio para el usuario | Beneficio para el negocio | Impacto esperado |
|---|---|---|---|---|---|---|
| Barra superior de confianza | La pagina no comunicaba rapidamente condiciones clave de compra. | Visibilidad del estado, reduccion de incertidumbre, ecommerce UX. | Se agrego una barra con entrega local, compra segura, IVA Ecuador 15% y stock visible. | Entiende datos importantes antes de comprar. | Aumenta confianza y reduce dudas. | Mejora conversion y credibilidad. |
| Navegacion responsive | El menu podia sentirse rigido en pantallas pequenas. | Flexibilidad de uso, responsive design, ISO 9241-110. | Se adapto la cabecera con `Wrap` para evitar desbordes. | Puede navegar mejor en laptop, tablet o movil. | Amplia compatibilidad del sitio. | Mejora accesibilidad y usabilidad. |
| Busqueda con semantica | La busqueda funcionaba, pero podia comunicar mejor su objetivo. | Accesibilidad WCAG, reconocimiento sobre recuerdo. | Se agrego etiqueta semantica y un icono de filtros. | Usuarios con lector de pantalla comprenden el campo. | Menos abandono por confusion. | Mejora accesibilidad y descubribilidad. |
| Seccion de accesos comerciales | La pagina no guiaba hacia tareas tipicas de ecommerce. | Arquitectura de informacion, escaneo visual, divulgacion progresiva. | Se agregaron tarjetas de Mas vendidos, Novedades, Ofertas y Stock bajo. | Encuentra caminos de exploracion rapidos. | Facilita futuras campanas y promociones. | Mejora navegacion y conversion. |
| Tarjetas de producto premium | Las tarjetas mostraban datos, pero faltaban senales visuales de comercio moderno. | Jerarquia visual, Gestalt, affordances, diseno emocional. | Se agregaron badges, favoritos, vista rapida, descripcion breve, sombras y hover. | Lee mejor el producto y entiende disponibilidad. | Aumenta intencion de compra y exploracion. | Mejora deseabilidad y claridad. |
| Comunicacion de stock | El stock bajo podia pasar desapercibido visualmente. | Prevencion de errores, informacion perceptible. | Se agrego etiqueta superior y badge textual, no solo color. | Evita comprar sin entender disponibilidad. | Reduce errores de venta y reclamos. | Mejora accesibilidad y prevencion de errores. |
| Microinteraccion hover | La interfaz se sentia estatica para escritorio. | Feedback inmediato, motion design moderado. | Se implemento elevacion y desplazamiento suave al pasar el mouse. | Percibe que el producto es interactivo. | Refuerza calidad percibida. | Mejora UX emocional y affordance. |
| Skeleton loading | La carga inicial solo mostraba indicador circular. | Visibilidad del estado, reduccion de ansiedad. | Se reemplazo por estructura de carga tipo skeleton. | Sabe que el catalogo se esta preparando. | Sensacion de sistema mas rapido. | Mejora satisfaccion postuso. |

## Criterios de calidad conservados

- Catalogo publico disponible sin inicio de sesion.
- Consumo de API real: productos, categorias y marcas.
- Filtros por texto, categoria y marca.
- Visualizacion de precio y stock.
- Mensajes de retroalimentacion para acciones.
- Placeholder elegante cuando no hay imagen real.
- Diseno responsive.
- Textos claros y lenguaje simple.

## Validacion pendiente

- Revisar visualmente en navegador despues de reiniciar Flutter Web.
- Probar ancho desktop y movil.
- Confirmar que no existan desbordes en tarjetas con nombres largos.
- Validar contraste final con una herramienta WCAG cuando se definan los colores definitivos de marca.
