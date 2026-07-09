# Guia de Diseno IHC, DCU, UX/UI y Accesibilidad - Aromas Store

Proyecto: Aromas Store  
Modulo: Frontend Flutter Web  
Base academica: Interaccion Humano-Computador, Diseno Centrado en el Usuario, UX/UI, accesibilidad y comercio electronico  
Fecha: 2026-07-09

## 1. Proposito

Esta guia define los criterios que deben orientar el diseno del frontend de Aromas Store. Su objetivo es evitar construir pantallas solo "bonitas" y asegurar que cada interfaz sea util, usable, accesible, clara, eficiente y coherente con los principios de Interaccion Humano-Computador.

El sistema debe ayudar al usuario a cumplir sus objetivos con el menor esfuerzo cognitivo posible. La complejidad debe manejarla el sistema, no el usuario.

## 2. Fuentes de referencia usadas

Se toman como base:

- Material de teoria de Interaccion Humano-Computador compartido para el proyecto.
- Tecnicas de recoleccion de datos: entrevistas, encuestas, observacion, grupos focales y analisis de usuarios.
- Diseno Centrado en el Usuario.
- Usabilidad y evaluacion heuristica.
- Multiculturalidad e internacionalizacion en interfaces web.
- Accesibilidad y diseno universal.
- Principios de comercio electronico.
- Criterios de UX/UI para interfaces modernas y profesionales.

Archivos de referencia:

```txt
D:\5to\IHC\Teoria_interacion_humano_computador_p1.pdf
D:\5to\IHC\Teoria_interacion_humano_computador_p2.pdf
D:\5to\IHC\Teoria_interacion_humano_computador_p3.pdf
D:\5to\IHC\Teoria_interacion_humano_computador_p4.pdf
D:\5to\IHC\Teoria_interacion_humano_computador_p5.pdf
D:\5to\IHC\Teoria_interacion_humano_computador_p6.pdf
```

## 3. Principio rector

Toda pantalla debe responder:

1. Quien es el usuario.
2. Que quiere lograr.
3. Que informacion necesita.
4. Cual es la accion principal.
5. Que errores pueden ocurrir.
6. Como se reduce la friccion.
7. Como se mejora la accesibilidad.
8. Como se comunica el estado del sistema.
9. Como se justifica desde IHC.
10. Como se justifica desde DCU.

Si una pantalla no responde estas preguntas, no debe implementarse todavia.

## 4. Usuarios principales

| Usuario | Objetivo principal | Necesidad de diseno |
|---|---|---|
| Visitante | Explorar productos y promociones. | Catalogo claro, visual, rapido y confiable. |
| Cliente | Comprar productos y revisar su pedido. | Flujo de compra simple, carrito visible y mensajes claros. |
| Vendedor | Registrar clientes, ventas, pagos y facturas. | Formularios eficientes, validacion y reduccion de pasos. |
| Bodeguero | Controlar stock y movimientos de inventario. | Tablas claras, alertas visibles y acciones directas. |
| Administrador | Gestionar catalogo, usuarios, promociones y reportes. | Panel organizado por modulos, permisos claros y vistas resumidas. |

## 5. Criterios de Diseno Centrado en el Usuario

El diseno no debe organizarse segun la base de datos, sino segun las tareas del usuario.

Aplicacion en Aromas Store:

- El visitante ve primero productos, precios, disponibilidad y promociones.
- El cliente no necesita entender tablas como `ventas`, `detalle_ventas` o `pagos`.
- El vendedor debe tener accesos rapidos a clientes, venta, pago y factura.
- El bodeguero debe ver inmediatamente productos con stock bajo.
- El administrador debe ver una estructura modular y resumida.

## 6. Usabilidad

Cada pantalla debe ser:

- Clara.
- Predecible.
- Consistente.
- Rapida de aprender.
- Eficiente para tareas repetidas.

Reglas para el frontend:

- Una accion principal por pantalla.
- Maximo tres acciones secundarias visibles.
- Formularios divididos por secciones logicas.
- Mensajes de error cerca del campo afectado.
- Botones con verbos claros: `Agregar`, `Guardar`, `Confirmar pago`, `Generar factura`.
- No exigir que el usuario recuerde codigos internos.

## 7. Reduccion de carga cognitiva

La interfaz debe evitar sobrecargar al usuario.

Aplicacion:

- El catalogo debe mostrar primero nombre, marca, precio y disponibilidad.
- Los filtros deben ser visibles pero no invasivos.
- La informacion tecnica se muestra solo cuando sea necesaria.
- El carrito debe resumir cantidades, subtotal, IVA 15% y total.
- Las pantallas administrativas deben usar tablas y filtros, no bloques visuales excesivos.

## 8. Arquitectura de informacion

La navegacion propuesta para Aromas Store es:

```txt
Inicio / Catalogo
Promociones
Carrito
Iniciar sesion

Panel interno
  - Dashboard
  - Productos
  - Categorias
  - Marcas
  - Clientes
  - Ventas
  - Pagos
  - Facturas
  - Inventario
  - Promociones
  - Usuarios
```

La pagina publica no debe sentirse como un panel administrativo. Debe sentirse como una tienda.

El panel interno debe ser mas denso, ordenado y orientado al trabajo.

## 9. Jerarquia visual

Orden de importancia en catalogo:

1. Producto.
2. Imagen o placeholder.
3. Nombre.
4. Marca.
5. Precio.
6. Stock/disponibilidad.
7. Promocion si existe.
8. Boton agregar al carrito.

Orden de importancia en panel interno:

1. Estado del modulo.
2. Alertas.
3. Busqueda/filtros.
4. Tabla principal.
5. Acciones.

## 10. Accesibilidad

Todas las pantallas deben cumplir criterios basicos de accesibilidad.

Reglas:

- Contraste suficiente entre texto y fondo.
- Texto legible en escritorio y movil.
- No depender solo del color para comunicar estado.
- Botones con texto claro e icono cuando ayude.
- Campos con etiqueta visible.
- Mensajes de error comprensibles.
- Estados de foco visibles.
- Navegacion usable con teclado.
- Imagenes de producto con texto alternativo conceptual.

Ejemplos:

- No usar solo rojo para error; acompanar con texto.
- No usar solo verde para exito; acompanar con mensaje.
- No mostrar "Error 400"; mostrar "La cantidad solicitada supera el stock disponible".

## 11. Diseno universal e inclusion digital

La interfaz debe ser comprensible para usuarios con diferentes niveles de experiencia digital.

Aplicacion:

- Lenguaje sencillo.
- Evitar tecnicismos en el frontend publico.
- Confirmaciones antes de acciones importantes.
- Recuperacion facil ante errores.
- Botones y campos suficientemente grandes.
- Flujos guiados para compra, pago y factura.

## 12. Retroalimentacion del sistema

Toda accion debe tener respuesta visible.

Ejemplos:

| Accion | Retroalimentacion esperada |
|---|---|
| Agregar al carrito | "Producto agregado al carrito." |
| Stock insuficiente | "Solo hay 2 unidades disponibles." |
| Login correcto | Redireccion al panel o catalogo. |
| Pago registrado | "Pago aprobado. Inventario actualizado." |
| Factura generada | "Factura FAC-000003 generada correctamente." |
| Error de red | "No se pudo conectar con el servidor. Intenta nuevamente." |

## 13. Prevencion de errores

El sistema debe prevenir errores antes de que ocurran.

Aplicacion:

- No permitir cantidades menores que 1.
- No permitir comprar mas unidades que el stock.
- Desactivar acciones cuando faltan datos.
- Validar correo y contrasena antes de enviar.
- Confirmar acciones destructivas.
- Mostrar alertas de stock bajo cuando sea menor que 3.

## 14. Consistencia

Todos los modulos deben compartir patrones visuales.

Reglas:

- Mismo estilo de botones.
- Mismo estilo de formularios.
- Mismo estilo de mensajes.
- Mismo formato de precios.
- Mismo formato de tablas.
- Mismos estados: cargando, vacio, error, exito.

## 15. Comercio electronico

La tienda debe transmitir confianza, seguridad y profesionalismo.

La pagina publica debe mostrar rapidamente:

- Producto.
- Precio.
- Disponibilidad.
- Promocion.
- Boton de compra.
- Carrito visible.

Debe evitar:

- Demasiado texto.
- Colores excesivos.
- Animaciones innecesarias.
- Formularios largos antes de mostrar valor.

## 16. Diseno visual esperado

Estilo recomendado:

- Premium.
- Elegante.
- Moderno.
- Limpio.
- Profesional.

Inspiracion conceptual:

- Tiendas de belleza y fragancias.
- E-commerce de productos premium.
- Catalogos limpios con buena fotografia o placeholders elegantes.

Paleta inicial sugerida:

| Uso | Color sugerido |
|---|---|
| Fondo principal | Blanco o gris muy claro |
| Texto principal | Casi negro |
| Acento premium | Verde profundo, dorado suave o vino sobrio |
| Error | Rojo accesible con texto |
| Exito | Verde accesible con texto |
| Advertencia stock | Amarillo/ambar con texto oscuro |

La paleta final debe revisarse con contraste.

## 17. Responsive design

El diseno debe funcionar en:

- Movil.
- Tablet.
- Escritorio.

Reglas:

- En movil: catalogo en una columna.
- En tablet: catalogo en dos columnas.
- En escritorio: catalogo en tres o cuatro columnas.
- Panel administrativo: tablas con filtros y scroll horizontal controlado si es necesario.

## 18. Pantalla principal propuesta

Pantalla: Catalogo publico.

Usuario principal:

- Visitante.
- Cliente.

Problema que resuelve:

- Permite descubrir productos y decidir una compra.

Informacion necesaria:

- Producto.
- Marca.
- Categoria.
- Precio.
- Disponibilidad.
- Promocion.

Accion principal:

- Agregar al carrito.

Principios aplicados:

- Reconocimiento sobre memorizacion.
- Visibilidad del estado.
- Reduccion de carga cognitiva.
- Jerarquia visual clara.
- Diseno centrado en la tarea del usuario.

## 19. Pantalla de carrito propuesta

Usuario principal:

- Cliente.

Problema que resuelve:

- Revisar productos antes de crear la venta.

Informacion necesaria:

- Productos seleccionados.
- Cantidad.
- Precio unitario.
- Subtotal.
- IVA 15%.
- Total.
- Alertas de stock.

Accion principal:

- Confirmar pedido.

Principios aplicados:

- Prevencion de errores.
- Retroalimentacion inmediata.
- Control del usuario.
- Claridad en costos.

## 20. Panel interno propuesto

Usuarios:

- Administrador.
- Vendedor.
- Bodeguero.

Problema que resuelve:

- Gestion operativa de la tienda.

Reglas:

- Mostrar solo modulos permitidos por rol.
- Priorizar tareas frecuentes.
- Usar tablas para datos administrativos.
- Usar alertas para stock bajo y ventas pendientes.

## 21. Checklist obligatorio antes de implementar una pantalla

Antes de construir cualquier vista en Flutter, responder:

| Pregunta | Respuesta requerida |
|---|---|
| Quien usa la pantalla | Visitante, cliente, vendedor, bodeguero o administrador |
| Que tarea realiza | Objetivo principal |
| Cual es la accion principal | Boton o accion dominante |
| Que informacion necesita | Datos visibles |
| Que errores se previenen | Validaciones |
| Que feedback recibe | Mensajes y estados |
| Como es accesible | Contraste, teclado, textos, labels |
| Como reduce esfuerzo | Menos pasos, menos memoria |
| Que principio IHC aplica | Usabilidad, feedback, consistencia, etc. |
| Que principio DCU aplica | Diseno basado en necesidad del usuario |

## 22. Decision para el siguiente desarrollo

La primera implementacion del frontend debe ser el Catalogo Publico conectado al backend.

Debe incluir:

- Encabezado con nombre Aromas Store.
- Navegacion basica.
- Carga de productos desde `/api/productos`.
- Filtros iniciales por categoria y marca.
- Cards de producto.
- Placeholder visual cuando `imagenUrl` sea nulo.
- Estado de carga.
- Estado de error.
- Estado sin resultados.

No se implementara aun el diseno final completo del video. Primero se construira una version funcional y justificada por IHC; luego se refinara visualmente.
