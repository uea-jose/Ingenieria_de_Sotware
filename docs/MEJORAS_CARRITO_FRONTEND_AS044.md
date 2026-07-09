# AS-044 - Mejora del Carrito Web

## Objetivo

Fortalecer el modulo de carrito de compras de Aromas Store para que el visitante pueda agregar productos, revisar cantidades, validar stock y preparar la compra con una experiencia clara, rapida y accesible.

## Usuario Principal

- Visitante/cliente: revisa productos y arma su carrito antes de iniciar o finalizar una compra.
- Vendedor/administrador: puede usar el flujo como base para ventas asistidas y validacion de stock.

## Decisiones de Diseno e IHC

| Decision implementada | Principio aplicado | Beneficio para el usuario | Beneficio para el negocio |
|---|---|---|---|
| Agregar producto sin recargar la pagina | Feedback inmediato, eficiencia, baja carga cognitiva | El usuario entiende que la accion funciono al instante | Reduce abandono y friccion |
| Si el producto ya existe, se incrementa la cantidad | Reconocimiento sobre memoria, consistencia | Evita duplicados confusos en el carrito | Mejora claridad del pedido |
| Badge con cantidad total | Visibilidad del estado del sistema | El usuario sabe cuantos productos lleva | Incentiva continuidad de compra |
| Panel inferior del carrito | Control y libertad del usuario | Permite revisar el carrito sin perder el catalogo | Mantiene al usuario dentro del flujo |
| Aumentar, disminuir y eliminar productos | Mapping natural, flexibilidad de uso | El usuario corrige cantidades facilmente | Reduce errores antes de generar venta |
| Deshacer eliminacion | Tolerancia al error, recuperacion sencilla | Se puede recuperar un producto borrado por accidente | Disminuye frustracion |
| Confirmar vaciado completo | Prevencion de errores | Evita perder todo el carrito por un clic accidental | Protege conversiones |
| Persistencia local del carrito | Continuidad de tarea | Si se recarga la pagina, el carrito se recupera | Reduce perdida de intencion de compra |
| Validacion contra backend | Seguridad y confiabilidad | El usuario ve stock y precios validados | Evita ventas inconsistentes |
| Resumen con subtotal, IVA 15%, descuentos y total | Informacion perceptible, transparencia | El usuario comprende cuanto va a pagar | Aumenta confianza |
| Placeholder visual cuando no hay imagen | Consistencia visual, accesibilidad | La tarjeta no queda rota ni confusa | Permite avanzar sin bloquearse por assets |

## Reglas de Accesibilidad

- Botones grandes, visibles y con iconos reconocibles.
- Mensajes de estado con texto, no solo color.
- Validaciones con lenguaje claro.
- Contraste consistente con la identidad actual.
- Flujo compatible con teclado mediante controles nativos de Flutter.

## Estado Tecnico

- La persistencia definitiva del carrito en base de datos queda preparada para una fase posterior.
- La validacion actual usa el backend mediante `/api/carrito/validar`.
- El flujo de `Finalizar compra` queda preparado para conectarse al checkout/pedido.

