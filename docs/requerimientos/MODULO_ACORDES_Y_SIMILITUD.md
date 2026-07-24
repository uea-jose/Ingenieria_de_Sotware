# Modulo de Acordes Aromaticos y Perfumes Similares

Proyecto: Aromas Store  
Fecha: 2026-07-24  
Estado: Analizado y documentado  
Implementacion: Pendiente  
Prioridad: Por definir en el backlog

## Objetivo

Definir una funcionalidad diferenciadora para Aromas Store: permitir que los usuarios comprendan el perfil aromatico de un perfume mediante acordes principales y puedan descubrir perfumes similares segun dichos acordes.

Esta funcionalidad busca que el sistema no sea solamente una tienda generica de perfumes, sino una experiencia de exploracion guiada por preferencias aromaticas.

## Alcance Inicial

El modulo se plantea como una propuesta futura. En esta etapa no se implementa codigo, base de datos, endpoints ni pantallas.

El alcance conceptual incluye:

- visualizacion de acordes aromaticos por perfume;
- intensidad relativa de cada acorde;
- busqueda por un acorde especifico;
- busqueda de perfumes similares por perfil completo;
- administracion futura de acordes por usuarios autorizados;
- sugerencias controladas para facilitar el registro de perfumes.

## Concepto De Acorde Aromatico

Un acorde aromatico representa una caracteristica predominante de un perfume.

Ejemplos:

- Vainilla;
- Dulce;
- Amaderado;
- Afrutado;
- Floral;
- Aromatico;
- Citrico;
- Atalcado;
- Especiado;
- Cuero;
- Almizclado;
- Verde;
- Terroso;
- Balsamico;
- Pachuli;
- Iris;
- Floral blanco.

Cada perfume podra tener varios acordes. Cada acorde tendra una intensidad descriptiva en una escala de 0 a 100.

Ejemplo conceptual:

```txt
Perfume: 1 Million Elixir

Acordes:
- Vainilla: 100
- Afrutado: 72
- Rosa: 58
- Dulce: 55
- Amaderado: 43
- Verde: 39
- Atalcado: 35
- Balsamico: 30
```

Los valores son descriptivos y comparativos. No deben presentarse como una medicion quimica exacta.

## Actores

| Actor | Participacion futura |
|---|---|
| Cliente | Visualiza acordes, explora perfumes similares y filtra resultados. |
| Administrador | Gestiona productos y podria asociar acordes a perfumes. |
| Vendedor | Podria gestionar productos si se mantiene su permiso actual sobre catalogo. |
| Bodeguero | Gestiona inventario; no deberia editar acordes salvo decision futura. |

No se recomienda crear un rol nuevo para esta funcionalidad.

## Relacion Con El Proyecto Actual

Actualmente el sistema ya cuenta con:

- productos;
- marcas;
- categorias;
- inventario;
- carrito;
- ventas;
- pagos;
- facturas;
- promociones;
- roles y autenticacion backend.

La funcionalidad de acordes no existe todavia en el modelo de datos, API ni frontend.

## Requerimientos Funcionales Candidatos

Estos requerimientos son candidatos y deben revisarse antes de aprobarse formalmente.

| Codigo | Requerimiento |
|---|---|
| RF-AC-01 | El sistema debera mostrar los acordes aromaticos asociados a un perfume, ordenados de mayor a menor intensidad. |
| RF-AC-02 | El sistema debera representar visualmente la intensidad relativa de cada acorde. |
| RF-AC-03 | El cliente podra consultar perfumes similares a partir del perfil de acordes de un perfume. |
| RF-AC-04 | El cliente podra filtrar perfumes similares por genero y otros criterios disponibles. |
| RF-AC-05 | El usuario autorizado para gestionar productos podra asociar acordes a un perfume. |
| RF-AC-06 | El usuario autorizado podra modificar la intensidad de los acordes antes de guardar el producto. |
| RF-AC-07 | El sistema podra ofrecer datos sugeridos para facilitar el registro de un perfume. |
| RF-AC-08 | Las sugerencias deberan ser confirmadas o modificadas por el usuario autorizado antes de almacenarse. |
| RF-AC-09 | El sistema podra calcular un nivel orientativo de similitud entre perfumes segun sus acordes. |
| RF-AC-10 | El usuario podra seleccionar un acorde para explorar otros perfumes relacionados con el. |

## Requerimientos No Funcionales Candidatos

| Codigo | Categoria | Requerimiento |
|---|---|---|
| RNF-AC-01 | Usabilidad | La informacion de acordes debera ser comprensible sin conocimientos especializados de perfumeria. |
| RNF-AC-02 | Rendimiento | La consulta de perfumes similares debera responder en tiempos adecuados para navegacion web. |
| RNF-AC-03 | Accesibilidad | Los acordes no deberan diferenciarse unicamente por color; deben incluir texto y valores legibles. |
| RNF-AC-04 | Responsividad | La visualizacion de acordes debera adaptarse a escritorio, tableta y movil. |
| RNF-AC-05 | Mantenibilidad | La logica de calculo de similitud debera estar separada de la interfaz grafica. |
| RNF-AC-06 | Seguridad | Solo roles autorizados podran crear, modificar o eliminar asociaciones entre perfumes y acordes. |
| RNF-AC-07 | Trazabilidad | Los nuevos requerimientos deberan vincularse con historias, diseno, implementacion y pruebas futuras. |
| RNF-AC-08 | Consistencia | La intensidad debera validarse con las mismas reglas en frontend, backend y base de datos. |

## Historias De Usuario Candidatas

### HU-AC-01

Como cliente, quiero visualizar los acordes principales de un perfume para comprender mejor su perfil aromatico antes de comprarlo.

### HU-AC-02

Como cliente, quiero encontrar perfumes con acordes similares para descubrir alternativas acordes con mis preferencias.

### HU-AC-03

Como cliente, quiero seleccionar un acorde especifico para consultar perfumes donde ese acorde tenga relevancia.

### HU-AC-04

Como usuario autorizado para administrar productos, quiero recibir sugerencias de acordes al registrar un perfume para reducir el tiempo de ingreso de informacion.

### HU-AC-05

Como usuario autorizado para administrar productos, quiero modificar los acordes y sus intensidades para registrar informacion acorde con el catalogo de la tienda.

## Reglas De Negocio Candidatas

- Un perfume puede tener varios acordes.
- Un acorde puede estar asociado a varios perfumes.
- La intensidad debe estar entre 0 y 100.
- Los acordes de un perfume deben mostrarse de mayor a menor intensidad.
- La barra mas larga representa el acorde predominante.
- Una sugerencia no debe guardarse automaticamente sin confirmacion humana.
- Debe diferenciarse entre dato sugerido y dato confirmado.
- La similitud debe presentarse como orientativa, no como recomendacion cientifica.
- La busqueda de similares no debe excluir por genero salvo que el usuario aplique ese filtro explicitamente.

## Modelo Conceptual Futuro

Entidades probables:

```txt
acordes
- id
- nombre
- slug
- descripcion
- color
- activo
- creadoEn
- actualizadoEn

producto_acordes
- id
- productoId
- acordeId
- intensidad
- ordenVisual
- origenDato
- confirmado
- creadoEn
- actualizadoEn
```

Impacto esperado:

- se requiere una relacion muchos a muchos entre productos y acordes;
- se requiere validar intensidad entre 0 y 100;
- se requiere decidir si `genero` pertenece a `Producto`, `Categoria` u otra entidad;
- se requiere una migracion futura de base de datos;
- se requiere actualizar seeds o fixtures para datos iniciales.

## Backend Futuro

Rutas candidatas, no definitivas:

```txt
GET /api/acordes
GET /api/productos/:id/acordes
PUT /api/productos/:id/acordes
GET /api/productos/:id/similares
POST /api/recomendaciones/acordes
```

Consideraciones:

- usar nombres en espanol, coherentes con `productos`, `categorias` y `marcas`;
- proteger creacion y edicion para Administrador y, si se decide, Vendedor;
- mantener lectura publica para acordes de productos;
- documentar en Swagger;
- registrar operaciones sensibles en auditoria backend;
- separar controladores, rutas y servicios como el resto del backend.

## Frontend Futuro

Componentes conceptuales:

```txt
PerfilAromatico
BarraAcorde
TarjetaPerfumeSimilar
FiltroAcordes
EditorAcordesProducto
CampoSugerenciasPerfume
SeccionPerfumesRelacionados
```

Ubicacion futura probable:

```txt
frontend/lib/models/
frontend/lib/data/api/
frontend/lib/screens/product_detail/
frontend/lib/screens/recommendations/
frontend/lib/widgets/accords/
frontend/lib/widgets/product/
```

La implementacion debe evitar una pantalla monolitica y respetar la estructura ya refactorizada del frontend.

## Experiencia De Usuario Recomendada

Se evaluaron cuatro alternativas:

| Alternativa | Ventaja | Riesgo |
|---|---|---|
| Clic en cada acorde | Permite explorar un acorde especifico. | Puede no ser evidente para todos los usuarios. |
| Boton "Buscar por acordes" | Es claro como accion general. | Puede ser menos emocional o comercial. |
| Boton "Ver perfumes similares" | Es el texto mas comprensible para cliente final. | Requiere tener definido el algoritmo de similitud. |
| Solucion combinada | Permite exploracion simple y avanzada. | Requiere cuidar la carga visual. |

Recomendacion:

- mostrar barras de acordes con texto e intensidad;
- permitir clic en una barra para explorar perfumes con ese acorde;
- incluir un boton principal: `Ver perfumes similares`;
- mantener tooltips y foco por teclado para accesibilidad;
- no copiar el diseno de sitios externos.

## Flujo Del Cliente

1. El cliente entra al detalle de un perfume.
2. Revisa imagen, marca, precio, descripcion y disponibilidad.
3. Consulta la seccion `Acordes principales`.
4. Puede seleccionar un acorde especifico.
5. Puede presionar `Ver perfumes similares`.
6. El sistema muestra resultados ordenados por coincidencia orientativa.
7. El cliente puede filtrar y agregar productos al carrito.

## Flujo Del Usuario Autorizado

1. El usuario autorizado registra o edita un perfume.
2. Ingresa informacion base del producto.
3. El sistema puede mostrar sugerencias de acordes.
4. El usuario revisa, ajusta o elimina sugerencias.
5. El usuario confirma intensidades.
6. El sistema guarda solamente datos confirmados.

## Criterios De Aceptacion Preliminares

Visualizacion:

- Dado un perfume con acordes, cuando el cliente abre su detalle, entonces el sistema muestra los acordes ordenados de mayor a menor intensidad.
- Dado un perfume sin acordes, cuando el cliente abre su detalle, entonces el sistema muestra un estado vacio comprensible.
- Dado un usuario que navega con teclado, cuando llega a un acorde interactivo, entonces puede identificarlo y activarlo.

Gestion:

- Dado un usuario autorizado, cuando recibe sugerencias de acordes, entonces puede confirmarlas, editarlas o eliminarlas.
- Dado un valor de intensidad fuera de rango, cuando se intenta guardar, entonces el sistema rechaza el valor con un mensaje claro.

## Algoritmo De Similitud

No se implementa todavia.

Opciones futuras:

- coincidencia ponderada por intensidad;
- distancia entre vectores de acordes;
- similitud coseno;
- diferencia absoluta normalizada;
- peso adicional para acordes predominantes.

La estrategia elegida debera ser:

- determinista;
- explicable;
- documentada;
- testeable;
- separada de la interfaz;
- presentada al usuario como orientativa.

## Datos Simulados Y Datos Externos

Para la version academica inicial se podran usar datos controlados mediante seeds, fixtures o mocks.

Restricciones:

- no hacer scraping;
- no copiar disenos completos de sitios externos;
- no usar imagenes, marcas o descripciones sin revisar licencia y finalidad;
- separar datos simulados de logica real;
- evitar aleatoriedad incontrolada en la interfaz.

## Riesgos Y Dependencias

| Riesgo | Impacto |
|---|---|
| Datos externos sin licencia clara | Riesgo academico y legal. |
| Algoritmo poco explicable | Puede generar resultados dificiles de justificar. |
| Interfaz demasiado cargada | Reduce claridad para el cliente. |
| Datos simulados mezclados con datos reales | Dificulta mantenimiento. |
| Falta de campo genero en producto | Limita filtros de similitud. |
| Implementar antes del detalle de producto | Obliga a rehacer interfaz despues. |

## Decisiones Pendientes

- Confirmar si `genero` sera campo de producto, categoria o filtro separado.
- Definir roles autorizados para editar acordes.
- Definir formula inicial de similitud.
- Definir fuente de datos iniciales.
- Definir colores oficiales por acorde dentro de la identidad pastel de Aromas Store.
- Definir si la primera version incluira solo visualizacion o tambien busqueda de similares.

## Trazabilidad

| Elemento | Estado |
|---|---|
| Requerimientos candidatos | Documentados |
| Historias candidatas | Documentadas |
| Modelo conceptual | Propuesto |
| API futura | Propuesta |
| UI futura | Propuesta |
| Implementacion | Pendiente |
| Pruebas | Pendientes |

## Decision Actual

La funcionalidad de acordes aromaticos y perfumes similares queda registrada como propuesta candidata.

No se implementa en esta etapa. La recomendacion es desarrollar primero una pantalla de detalle de producto y, despues, incorporar el perfil aromatico como modulo visual y funcional.
