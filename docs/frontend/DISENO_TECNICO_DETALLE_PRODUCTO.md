# Diseno Tecnico de Pantalla Detalle de Producto

Proyecto: Aromas Store  
Fecha: 2026-07-24  
Estado: Diseno tecnico previo a implementacion  
Implementacion: Pendiente

## Objetivo

Definir la futura pantalla de detalle de producto para Aromas Store, manteniendo coherencia con el catalogo actual, el carrito existente y la identidad visual pastel ya implementada.

Esta pantalla sera la base natural para incorporar despues el modulo de acordes aromaticos y perfumes similares.

## Alcance Inicial

La primera version del detalle de producto debe enfocarse en mostrar informacion real ya disponible desde la API.

Incluye:

- imagen del producto;
- nombre;
- marca;
- categoria;
- precio;
- descripcion;
- volumen, si existe;
- disponibilidad;
- stock visible;
- accion de agregar al carrito;
- volver al catalogo;
- espacio preparado para futuras secciones.

No incluye todavia:

- acordes aromaticos reales;
- perfumes similares;
- reseñas;
- login;
- checkout;
- panel administrativo;
- scraping o datos externos.

## Relacion Con El Frontend Actual

| Elemento | Estado |
|---|---|
| HomePage | Implementada en `frontend/lib/screens/home/home_page.dart`. |
| Catalogo publico | Implementado con filtros y grilla. |
| ProductCard | Implementado en `frontend/lib/widgets/catalog/product_card.dart`. |
| Vista rapida | Simulada mediante snackbar. |
| Carrito | Funcional con persistencia local y validacion backend. |
| Rutas internas | Aun no hay navegacion formal a detalle. |

La pantalla de detalle debe reutilizar el modelo `Product`, el servicio `ApiService` y la logica actual de agregar al carrito.

## Ruta Futura Recomendada

Ruta conceptual:

```txt
/producto/:id
```

En Flutter Web podria resolverse inicialmente con navegacion interna simple. Si mas adelante se agrega un router formal, esta pantalla debe quedar preparada para integrarse sin reescritura.

## Archivos Futuros Probables

```txt
frontend/lib/screens/product_detail/product_detail_page.dart
frontend/lib/widgets/product/product_detail_header.dart
frontend/lib/widgets/product/product_purchase_panel.dart
frontend/lib/widgets/product/product_info_section.dart
frontend/lib/widgets/product/product_stock_summary.dart
frontend/lib/widgets/product/product_future_accords_placeholder.dart
```

## Informacion A Mostrar

| Dato | Fuente actual |
|---|---|
| Nombre | `Product.name` |
| Marca | `Product.brand.name` |
| Categoria | `Product.category.name` |
| Precio | `Product.price` |
| Descripcion | `Product.description` |
| Imagen | `Product.imageUrl` o placeholder actual |
| Volumen | `Product.volumeMl` si existe |
| Stock | `Product.inventory.stock` |
| Estado de stock | calculado en frontend |

## Experiencia De Usuario

La pantalla debe sentirse como una continuacion del catalogo, no como una pagina aislada.

Recomendaciones:

- mantener fondo pastel claro;
- usar tarjetas suaves solo para bloques funcionales;
- priorizar imagen, nombre, marca, precio y accion;
- mostrar stock con texto claro, no solo color;
- permitir volver al catalogo sin perder orientacion;
- mantener el boton de carrito accesible;
- conservar la accion de agregar al carrito con la misma validacion actual.

## Estructura Visual Recomendada

En escritorio:

```txt
Header / navegacion

Detalle de producto
  Columna izquierda:
    imagen del producto
    estado de disponibilidad

  Columna derecha:
    marca
    nombre
    categoria
    descripcion
    precio
    stock
    agregar al carrito

Secciones inferiores:
  informacion del producto
  espacio futuro para acordes principales
  espacio futuro para perfumes similares
```

En movil:

```txt
Header
Imagen
Nombre / marca / precio
Agregar al carrito
Descripcion
Disponibilidad
Secciones futuras
```

## Preparacion Para Acordes

La primera version no debe implementar acordes, pero si puede reservar un bloque estructural para integrarlos luego.

Cuando el modulo de acordes se implemente, la ubicacion recomendada sera debajo de la informacion principal:

```txt
Acordes principales
BarraAcorde 1
BarraAcorde 2
BarraAcorde 3
Boton: Ver perfumes similares
```

Este bloque no debe usar datos aleatorios ni simulados dentro de la pantalla real hasta que se apruebe esa etapa.

## Integracion Con Carrito

La pantalla debe reutilizar el flujo actual:

- validar stock antes de agregar;
- incrementar cantidad si el producto ya existe;
- persistir carrito localmente;
- validar carrito contra backend;
- mantener feedback claro.

No se debe duplicar una segunda logica de carrito.

## Backend Necesario

Actualmente existe:

```txt
GET /api/productos/:id
```

Ese endpoint deberia ser suficiente para la primera version del detalle.

No se requieren nuevos endpoints para esta etapa.

## Pruebas Recomendadas

| Prueba | Resultado esperado |
|---|---|
| Abrir detalle desde producto con stock | Muestra datos y permite agregar al carrito. |
| Abrir detalle desde producto sin stock | Muestra estado sin stock y deshabilita compra. |
| Producto inexistente | Muestra estado de error comprensible. |
| Navegacion movil | No hay desbordes ni texto cortado. |
| Agregar al carrito | Reutiliza persistencia y validacion existente. |
| Volver al catalogo | El usuario puede regresar sin perder contexto visual. |

## Riesgos

| Riesgo | Mitigacion |
|---|---|
| Duplicar logica de carrito | Reutilizar callbacks y servicios existentes. |
| Crear pantalla monolitica | Separar widgets desde el inicio. |
| Introducir acordes simulados antes de tiempo | Dejar acordes solo como etapa futura documentada. |
| Romper catalogo actual | Conectar detalle desde una accion controlada y probar catalogo. |
| Necesitar router formal | Empezar simple, pero no acoplar la pantalla a HomePage. |

## Orden De Implementacion Recomendado

1. Crear estructura `screens/product_detail`.
2. Crear pantalla `ProductDetailPage`.
3. Crear widgets de producto reutilizables.
4. Conectar `ProductCard` desde `Vista rapida` o una accion `Ver detalle`.
5. Reutilizar flujo de carrito existente.
6. Probar escritorio y movil.
7. Actualizar documentacion y bitacora.

## Decision Actual

La pantalla detalle de producto debe implementarse antes de acordes aromaticos y perfumes similares.

Primero se construye una vista estable con datos reales actuales. Despues se incorpora el modulo de acordes como seccion progresiva.
