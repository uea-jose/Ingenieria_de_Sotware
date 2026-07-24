# Bitacora del Proyecto Aromas Store

Proyecto: Aromas Store  
Materia: Ingenieria de Software  
Stack definido: Flutter Web, Node.js, Express, PostgreSQL, Prisma, Docker, JWT  
Repositorio local: `C:\Users\Jose\Documents\proyectospERFUMES\aromas-store`

## Resumen General

Aromas Store es un sistema web para una empresa ficticia de venta de perfumes y productos aromaticos. El sistema se plantea como una tienda publica para clientes y un panel interno para usuarios administrativos segun rol.

Roles principales:

- Administrador: gestiona usuarios, catalogo, inventario y reportes.
- Vendedor: registra clientes, ventas, pagos y facturas.
- Bodeguero: gestiona inventario, stock y ubicaciones.
- Cliente comprador: puede navegar la tienda publica y comprar sin necesidad inicial de cuenta.

## Requisitos Funcionales Base

| Codigo RF | Requisito funcional | Descripcion resumida | Estado |
|---|---|---|---|
| RF-01 | Registro de clientes | El sistema debe permitir registrar clientes con correo unico, datos personales basicos y contrasena cifrada con bcrypt. | Completado |
| RF-02 | Autenticacion de usuarios | El sistema debe permitir autenticar clientes, administradores y vendedores mediante credenciales validas y generar un token JWT. | En progreso |
| RF-03 | Consulta de catalogo | El sistema debe permitir consultar perfumes mostrando nombre, marca, categoria, volumen, precio, imagen, descripcion y disponibilidad. | En progreso |
| RF-04 | Busqueda y filtros | El sistema debe permitir buscar y filtrar perfumes por nombre, marca, categoria, rango de precio y estado activo. | Completado |
| RF-05 | Agregar al carrito | El sistema debe permitir agregar perfumes al carrito validando inventario disponible. | Completado |
| RF-06 | Modificar carrito | El sistema debe permitir modificar cantidades o retirar perfumes del carrito recalculando subtotal, impuesto y total. | Completado |
| RF-07 | Crear pedidos | El sistema debe permitir crear pedidos desde el carrito confirmado, registrando cliente, productos, cantidades, precios y total. | Completado |
| RF-08 | Registrar pagos simulados | El sistema debe permitir registrar pagos simulados asociados a pedidos. | Completado |
| RF-09 | Actualizacion automatica de inventario | El sistema debe actualizar automaticamente el inventario cuando una venta sea confirmada como pagada. | Completado |
| RF-10 | Movimientos de inventario | El sistema debe registrar entradas, salidas y ajustes de inventario con producto, cantidad, motivo, usuario y fecha. | Completado |
| RF-11 | Gestion de productos | El sistema debe permitir crear, actualizar, activar y desactivar perfumes asociados a marca, categoria e inventario. | Completado |
| RF-12 | Gestion de categorias | El sistema debe permitir administrar categorias con nombre unico, descripcion y estado. | Completado |
| RF-13 | Gestion de marcas | El sistema debe permitir administrar marcas con nombre, pais de origen, descripcion y estado activo. | Completado |
| RF-14 | Facturacion | El sistema debe generar factura para cada pedido pagado con numero unico, datos del cliente, subtotal, impuesto, total y fecha. | Completado |
| RF-15 | Promociones | El sistema debe permitir definir promociones aplicables a perfumes especificos con vigencia, tipo, valor y estado. | Completado |

## Requisitos No Funcionales Base

| Codigo RNF | Categoria | Descripcion resumida | Evidencia/Relacion |
|---|---|---|---|
| RNF-01 | Seguridad | El backend debe proteger los endpoints privados mediante JWT firmado, validando token, expiracion y rol del usuario. | Login JWT, middleware de autenticacion y rutas protegidas. |
| RNF-02 | Seguridad | Las contrasenas deben almacenarse unicamente como hash generado con bcrypt. | Registro de clientes y usuario administrador con contrasena cifrada. |
| RNF-03 | Seguridad | El despliegue productivo debe operar sobre HTTPS para proteger credenciales, tokens y datos de compra. | Pendiente para despliegue productivo. |
| RNF-04 | Rendimiento | Las consultas del catalogo deben responder en tiempos adecuados para navegacion web. | Consultas `GET /api/productos`, filtros y catalogo probados en backend local. |
| RNF-05 | Rendimiento | La validacion de carrito y actualizacion de inventario no debe degradar la confirmacion del pedido. | Validacion de carrito, pago simulado y descuento de inventario implementados. |
| RNF-06 | Usabilidad | La interfaz Flutter Web debe permitir completar registro, busqueda, carrito y pedido de forma guiada. | Pendiente hasta construir frontend Flutter Web. |
| RNF-07 | Disponibilidad | El sistema debe mantener disponibilidad para catalogo y pedidos durante el horario definido. | Endpoint `/api/health` disponible para verificacion de API. |
| RNF-08 | Escalabilidad | La arquitectura con Docker debe separar frontend, backend y base de datos para permitir crecimiento gradual. | PostgreSQL levantado con Docker y estructura separada `backend`, `frontend`, `docs`. |
| RNF-09 | Accesibilidad | La interfaz debe mantener contraste legible, textos comprensibles y navegacion compatible con teclado. | Pendiente hasta construir frontend Flutter Web. |
| RNF-10 | Mantenibilidad y compatibilidad | El backend debe conservar organizacion modular con Express y Prisma. | Backend organizado por modulos, rutas, controladores, servicios, Prisma ORM, Swagger, documentacion Markdown de API y guia de diseno IHC/UX/UI. |
| RNF-11 | Verificabilidad | El backend debe contar con una prueba rapida que permita verificar que los endpoints principales estan operativos antes de continuar con el frontend. | Script `npm run test:api` y documento `docs/backend/PRUEBAS_BACKEND.md`. |
| RNF-12 | Experiencia de usuario | El frontend debe disenarse bajo principios de IHC, DCU, UX/UI, accesibilidad, reduccion de carga cognitiva y comercio electronico. | Guia `docs/ux-ui/GUIA_DISENO_IHC_UX_UI.md` creada antes de iniciar las pantallas reales. |

## Bitacora de Avance por Requisito Funcional

| Fecha | RF relacionado | Tarea Jira | Actividad | Descripcion | Evidencia/Resultado | Estado |
|---|---|---|---|---|---|---|
| 2026-06-23 | RF-03, RF-05, RF-07, RF-08, RF-09, RF-11 | AS-001 | Analisis del proyecto original | Se reviso el proyecto Django original Eau Royal para entender su objetivo, estructura y tecnologia. | Se identifico que era un e-commerce de perfumes hecho con Django, PostgreSQL y plantillas web. | Completado |
| 2026-06-23 | RNF-08, RNF-10 | AS-002 | Decision de migracion tecnologica | Se definio migrar progresivamente a Flutter Web, Node.js/Express, PostgreSQL, Docker, Prisma, JWT y Swagger. | Stack aprobado para el nuevo proyecto Aromas Store. | Completado |
| 2026-06-23 | RNF-08, RNF-10 | AS-003 | Creacion de estructura base | Se creo la carpeta principal del proyecto con separacion por responsabilidades. | `aromas-store/backend`, `aromas-store/frontend`, `aromas-store/docs`. | Completado |
| 2026-06-23 | RF-07, RF-08, RF-09, RF-10, RF-14 | AS-004 | Configuracion de Docker y PostgreSQL | Se levanto una base de datos PostgreSQL en Docker para soportar los modulos transaccionales del sistema. | Contenedor `aromas-store-postgres` usando puerto local `5433`. | Completado |
| 2026-06-24 | RNF-08, RNF-10 | AS-005 | Inicializacion del backend | Se inicializo el backend con Node.js, Express y dependencias principales. | `package.json`, Express, CORS, dotenv, Prisma, bcrypt, JWT y Swagger instalados. | Completado |
| 2026-06-24 | RF-01, RF-02, RF-03, RF-07, RF-08, RF-09, RF-14 | AS-006 | Configuracion inicial de Prisma | Se configuro Prisma como ORM para conectarse a PostgreSQL. | Archivos `prisma/schema.prisma`, `prisma.config.ts` y `.env`. | Completado |
| 2026-06-24 | RF-01, RF-02, RF-03, RF-07, RF-08, RF-09, RF-10, RF-11, RF-12, RF-13, RF-14 | AS-007 | Primer modelo entidad-relacion | Se creo un modelo inicial con entidades principales del negocio. | Tablas: roles, usuarios, clientes, categorias, marcas, productos, inventario, ventas, detalle_ventas, pagos y facturas. | Completado |
| 2026-06-24 | RF-01, RF-03, RF-07, RF-08, RF-09, RF-14 | AS-008 | Primera sincronizacion de base | Se aplico el modelo de Prisma a PostgreSQL. | Base `aromas_store` sincronizada y visible en DBeaver. | Completado |
| 2026-06-24 | RF-02, RF-03, RF-11, RF-12, RF-13 | AS-009 | Datos semilla iniciales | Se creo un archivo seed para cargar datos de prueba. | Roles, usuario administrador, categorias, marcas, productos e inventario inicial. | Completado |
| 2026-06-24 | RNF-10 | AS-010 | API base del backend | Se creo la estructura modular del backend. | Carpetas `src/modules`, `src/routes`, `src/config`, `app.js`, `server.js`. | Completado |
| 2026-06-24 | RF-03 | AS-011 | Endpoint de productos | Se implemento la consulta de productos para catalogo y tienda publica. | `GET /api/productos` y alias `GET /api/products`. | Completado |
| 2026-06-24 | RF-12 | AS-012 | Endpoint de categorias | Se implemento la consulta de categorias. | `GET /api/categorias` y alias `GET /api/categories`. | Completado |
| 2026-06-24 | RF-13 | AS-013 | Endpoint de marcas | Se implemento la consulta de marcas/casas fabricantes. | `GET /api/marcas` y alias `GET /api/brands`. | Completado |
| 2026-06-24 | RF-01, RF-02, RF-03, RF-07, RF-08, RF-09, RF-10, RF-11, RF-12, RF-13, RF-14 | AS-014 | Espanolizacion del backend y base | Se cambio el modelo y parte del backend para usar nombres en espanol. | Entidades como `usuarios`, `productos`, `marcas`, `categorias`, `ventas`, `pagos`, `facturas`. | Completado |
| 2026-06-25 | RNF-10 | AS-015 | Revision de calidad del modelo | Se reviso si la base estaba demasiado simple o demasiado compleja. | Se decidio un modelo balanceado: profesional, normalizado y manejable. | Completado |
| 2026-06-25 | RF-01, RF-02, RF-03, RF-07, RF-08, RF-09, RF-10, RF-11, RF-12, RF-13, RF-14 | AS-016 | Ajuste profesional del modelo | Se agregaron campos necesarios sin sobrecargar la base. | Usuarios con nombres/apellidos, clientes con cedula/ciudad, marcas con paisOrigen, productos con volumenMl, inventario con ubicacion. | Completado |
| 2026-06-25 | RF-01, RF-03, RF-07, RF-08, RF-09, RF-14 | AS-017 | Recarga limpia de base de datos | Se recreo la base con el nuevo modelo balanceado. | PostgreSQL actualizado y datos semilla cargados correctamente. | Completado |
| 2026-06-25 | RF-02, RF-03, RF-11, RF-12, RF-13 | AS-018 | Validacion de datos | Se comprobo que existan datos principales en la base. | 3 roles, 1 usuario, 6 categorias, 16 marcas, 4 productos y 4 inventarios. | Completado |
| 2026-07-05 | RF-02, RNF-01 | AS-019 | Definicion de flujo de usuarios | Se definio que la tienda publica sera igual para todos, y el panel interno cambiara segun rol. | Se establecio control de acceso basado en roles: Administrador, Vendedor y Bodeguero. | Completado |
| 2026-07-05 | RF-02, RNF-01, RNF-02 | AS-020 | Implementacion de autenticacion | Se creo el modulo de login con JWT y comparacion de contrasena mediante bcrypt. | `POST /api/auth/login` y `GET /api/auth/me`. | Completado |
| 2026-07-05 | RF-02, RNF-01 | AS-021 | Validacion del login | Se probo el inicio de sesion con el usuario administrador. | Usuario `admin@aromasstore.com`, rol `Administrador`, token generado correctamente. | Completado |
| 2026-07-06 | RF-01, RF-02, RNF-02 | AS-022 | Registro de clientes | Se implemento el registro de clientes creando usuario con rol Cliente, perfil de cliente y contrasena cifrada con bcrypt. | `POST /api/clientes/registro` probado; el cliente registrado puede iniciar sesion y recibir JWT. | Completado |
| 2026-07-06 | RNF-10 | AS-035 | Indice de endpoints | Se agrego una ruta de apoyo para listar los endpoints actuales de la API durante pruebas y documentacion. | `GET /api` devuelve nombre del servicio, version y listado de rutas disponibles. | Completado |
| 2026-07-06 | RF-04 | AS-023 | Busqueda y filtros de catalogo | Se agregaron filtros al endpoint de productos por nombre, marca, categoria, rango de precio y estado activo. | `GET /api/productos?nombre=vanilla`, `?marcaId=2`, `?categoriaId=1`, `?precioMin=50&precioMax=70`, `?activo=true` probados correctamente. | Completado |
| 2026-07-06 | RF-05, RF-06 | AS-024 | Validacion de carrito | Se implemento un endpoint para validar productos del carrito, comprobar stock disponible, recalcular subtotal, impuesto y total, y alertar cuando el stock sea menor que 3 unidades. | `POST /api/carrito/validar` probado con carrito valido, stock insuficiente y alerta de stock bajo. | Completado |
| 2026-07-07 | RF-07 | AS-025 | Creacion de venta pendiente | Se implemento la creacion de ventas desde un carrito validado, registrando cliente, usuario, detalle de productos, cantidades, precios unitarios, subtotal, impuesto y total. | `POST /api/ventas` probado; crea venta en estado PENDIENTE y no descuenta inventario hasta que exista pago aprobado. | Completado |
| 2026-07-07 | RF-08, RF-09, RF-10 | AS-026 | Pago simulado y descuento de inventario | Se implemento el registro de pagos simulados. Cuando el pago queda PAGADO, la venta cambia a PAGADA, el inventario se descuenta automaticamente y se registra movimiento de salida. | `POST /api/pagos` probado; venta #3 paso a PAGADA, stock de producto 1 bajo de 25 a 24 y se creo 1 movimiento de inventario. | Completado |
| 2026-07-07 | RF-10 | AS-027 | Movimientos administrativos de inventario | Se implementaron endpoints para consultar inventario, ver alertas de stock bajo, listar movimientos y registrar entradas, salidas o ajustes manuales. | `POST /api/inventario/movimientos` probado con ENTRADA; stock de producto 1 subio de 24 a 34. Tambien se probo alerta con stock menor que 3. | Completado |
| 2026-07-07 | RF-11 | AS-028 | Gestion administrativa de productos | Se implementaron endpoints para consultar producto por ID, crear producto con inventario inicial, actualizar datos e inventario, y activar o desactivar productos. | `GET /api/productos/:id`, `POST /api/productos`, `PUT /api/productos/:id` y `PATCH /api/productos/:id/estado` probados correctamente. | Completado |
| 2026-07-07 | RF-12, RF-13 | AS-029 | Gestion administrativa de categorias y marcas | Se implementaron endpoints para consultar por ID, crear, editar, activar y desactivar categorias y marcas. | `GET/POST/PUT/PATCH /api/categorias` y `GET/POST/PUT/PATCH /api/marcas` probados correctamente con datos temporales. | Completado |
| 2026-07-08 | RF-14 | AS-030 | Generacion de facturas | Se implemento la generacion de facturas para ventas pagadas, con numero unico, datos del cliente, subtotal, impuesto, total y fecha de emision. | `POST /api/facturas` probado con venta pagada #3; genero factura `FAC-000003` y bloqueo la duplicacion de factura para la misma venta. | Completado |
| 2026-07-08 | RF-15 | AS-031 | Gestion de promociones | Se implemento el modulo de promociones para productos, permitiendo definir tipo de descuento, valor, vigencia, descripcion y estado activo. | `GET/POST/PUT/PATCH /api/promociones` probado correctamente; se creo, edito y desactivo una promocion de prueba para producto #1. | Completado |
| 2026-07-08 | RNF-10 | AS-032 | Documentacion Swagger | Se integro Swagger UI para documentar la API REST con rutas, grupos, seguridad JWT y ejemplos de cuerpos JSON. | `GET /api/docs` disponible para navegador y `GET /api/docs.json` probado con 22 rutas documentadas. | Completado |
| 2026-07-08 | RNF-11 | AS-036 | Prueba de humo del backend | Se creo un script de validacion automatica para comprobar disponibilidad, Swagger, login JWT, rutas publicas y rutas protegidas principales. | `npm run test:api` ejecutado correctamente con resultado `17/17 pruebas correctas`; se documento en `docs/backend/PRUEBAS_BACKEND.md`. | Completado |
| 2026-07-08 | RNF-10 | AS-037 | Documentacion Markdown de API | Se creo una documentacion formal de API con URL base, autenticacion JWT, roles, endpoints, seguridad, ejemplos JSON, codigos de respuesta y comandos de prueba. | Archivo `docs/backend/API_DOCUMENTACION.md` creado como evidencia documental complementaria a Swagger. | Completado |
| 2026-07-09 | RNF-09, RNF-12 | AS-038 | Guia de diseno IHC, DCU, UX/UI y accesibilidad | Se analizaron los conceptos compartidos sobre Interaccion Humano-Computador, Diseno Centrado en el Usuario, UX/UI, accesibilidad, carga cognitiva y comercio electronico para definir criterios antes de implementar el frontend. | Archivo `docs/ux-ui/GUIA_DISENO_IHC_UX_UI.md` creado con usuarios, principios, arquitectura de informacion, accesibilidad, checklist y decision de iniciar por catalogo publico. | Completado |
| 2026-07-09 | RF-03, RF-04, RF-05, RNF-09, RNF-12 | AS-039 | Rediseño inicial de pagina principal Flutter | Se reemplazo la pantalla tecnica inicial por una pagina publica mas cercana a un e-commerce: navegacion superior, buscador, carrusel hero, franja de beneficios, filtros y cards de producto sin desbordes. | `frontend/lib/main.dart` actualizado para consumir productos, categorias y marcas del backend, mostrar disponibilidad, placeholder visual y accion de agregar al carrito. | En progreso |
| 2026-07-09 | RF-03, RF-04, RF-05, RNF-09, RNF-12 | AS-040 | Evolucion premium de catalogo publico | Se mejoro la primera pantalla publica sin eliminar funcionalidad: barra de confianza, navegacion responsive, accesos comerciales, tarjetas con hover, favoritos visuales, vista rapida, badges de disponibilidad y skeleton loading. | `frontend/lib/main.dart`, `frontend/test/widget_test.dart` y `docs/frontend/MEJORAS_DISENO_FRONTEND_AS040.md` actualizados con criterios de IHC, DCU, accesibilidad, ecommerce UX y conversion. | En progreso |
| 2026-07-09 | RNF-10 | AS-041 | Preparacion de control de versiones | Se inicializo el repositorio Git local del proyecto, se conecto el remoto de GitHub y se creo una rama para subir backend, frontend y documentacion. | Rama local `feature/aromas-store-fullstack` conectada al remoto `https://github.com/uea-jose/Ingenieria_de_Sotware.git`; se agrego `.gitignore` raiz para excluir secretos, dependencias, compilados y archivos pesados. | Completado |
| 2026-07-09 | RNF-10 | AS-042 | Organizacion para publicacion en GitHub | Se preparo la estructura del repositorio para subir el proyecto fullstack de forma ordenada, manteniendo `backend`, `frontend`, `docs`, `docker-compose.yml` y README principal. | Commit local `feat: add Aromas Store fullstack project` creado en la rama `feature/aromas-store-fullstack`; se excluyeron `.env`, dependencias, builds, logs, videos y plataformas moviles no usadas. | Completado |
| 2026-07-09 | RF-05, RF-06, RNF-09, RNF-12 | AS-043 | Carrito visual en Flutter Web | Se implemento carrito funcional en el frontend publico: contador en navegacion, agregar producto, panel inferior, cambio de cantidades, vaciar carrito, validacion contra backend y resumen de subtotal, IVA y total. | `frontend/lib/main.dart` actualizado para consumir `POST /api/carrito/validar`; `dart analyze` ejecutado sin errores. | Completado |
| 2026-07-09 | RF-05, RF-06, RF-07, RNF-09, RNF-12 | AS-044 | Mejora profesional del carrito web | Se fortalecio el carrito con persistencia local, recuperacion automatica, incremento de cantidad si el producto ya existe, eliminacion con opcion de deshacer, confirmacion antes de vaciar, continuar comprando, finalizar compra preparado, detalle de subtotal por producto, disponibilidad y resumen de IVA/descuentos/envio. | `frontend/lib/main.dart` y `docs/frontend/MEJORAS_CARRITO_FRONTEND_AS044.md` actualizados con criterios de IHC, Nielsen, Norman, WCAG y ecommerce UX; `dart analyze` ejecutado sin errores. | Completado |
| 2026-07-10 | RNF-10, RNF-12 | AS-045 | Bitacora estructural del frontend | Se reorganizo la documentacion del frontend para explicar la estructura por carpetas, responsabilidades de archivos, modelos, servicios, almacenamiento local, estado de avance y proximas etapas. | `docs/frontend/FRONTEND_REFACTORIZACION_ESTRUCTURAL.md` actualizado como guia concreta de mantenimiento y refactorizacion frontend. | Completado |
| 2026-07-10 | RNF-10, RNF-12 | AS-046 | Separacion de layout y feedback frontend | Se continuo la refactorizacion estructural moviendo navegacion, marca, barra superior, boton de carrito, estado de carga, skeletons y vista de error a carpetas especializadas. | `frontend/lib/widgets/layout/`, `frontend/lib/widgets/feedback/`, `frontend/test/widget_test.dart` y `docs/frontend/FRONTEND_REFACTORIZACION_ESTRUCTURAL.md` actualizados sin cambiar comportamiento visual. | Completado |
| 2026-07-10 | RF-03, RF-04, RF-05, RNF-10, RNF-12 | AS-047 | Separacion de widgets de catalogo frontend | Se movieron encabezado, filtros, grilla, tarjetas, imagenes, placeholders, badges de disponibilidad y vista vacia del catalogo a una carpeta especializada. | `frontend/lib/widgets/catalog/`, `frontend/lib/main.dart` y `docs/frontend/FRONTEND_REFACTORIZACION_ESTRUCTURAL.md` actualizados conservando la pagina publica actual. | Completado |
| 2026-07-10 | RF-05, RF-06, RNF-10, RNF-12 | AS-048 | Separacion de widgets de carrito frontend | Se movieron barra previa, panel inferior, filas de producto, miniaturas, control de cantidad y resumen de validacion a una carpeta especializada. | `frontend/lib/widgets/cart/`, `frontend/lib/main.dart` y `docs/frontend/FRONTEND_REFACTORIZACION_ESTRUCTURAL.md` actualizados conservando comportamiento del carrito. | Completado |
| 2026-07-10 | RF-03, RF-04, RF-05, RF-06, RNF-10, RNF-12 | AS-049 | Separacion de pantalla principal y app Flutter | Se movio la pagina publica actual a `screens/home`, se separo la configuracion de app y tema, y `main.dart` quedo como punto de entrada limpio. | `frontend/lib/app/`, `frontend/lib/screens/home/`, `frontend/lib/main.dart` y `docs/frontend/FRONTEND_REFACTORIZACION_ESTRUCTURAL.md` actualizados sin agregar nuevas funcionalidades. | Completado |
| 2026-07-10 | RNF-10, RNF-12 | AS-050 | Cierre no funcional de refactor frontend | Se reviso la estructura resultante y se documento que los pasos restantes antes de nuevas funciones son validacion visual, `flutter analyze`, `flutter test`, decision sobre respaldo y cierre formal de etapa. | `docs/frontend/FRONTEND_REFACTORIZACION_ESTRUCTURAL.md` actualizado para reflejar la ubicacion real de `HomePage`, el rol limpio de `main.dart` y los pendientes sin agregar funcionalidades. | Completado |
| 2026-07-10 | RNF-10, RNF-12 | AS-051 | Orden de respaldo historico frontend | Se saco el archivo de respaldo del catalogo fuera de `frontend/lib` para que la carpeta de codigo activo solo contenga la aplicacion vigente. | `frontend/backups/main_catalogo_v1_respaldo.dart` conserva el respaldo sin cambios de contenido; `docs/frontend/FRONTEND_REFACTORIZACION_ESTRUCTURAL.md` actualizado. | Completado |
| 2026-07-11 | RF-03, RF-04, RF-05, RF-06, RNF-09, RNF-10, RNF-12 | AS-052 | Rediseño controlado de HomePage publica | Se mejoro la portada publica con navegacion comercial, buscador visual con sugerencias simuladas, fallback local de productos, accesos por categoria, destacados, mas vendidos, marcas, ocasiones, beneficios y footer sin crear login, checkout ni panel administrativo. | `frontend/lib/screens/home/`, `frontend/lib/widgets/layout/top_navigation.dart` y `frontend/analysis_options.yaml` actualizados; `dart analyze` ejecutado sin errores. `flutter test` no finalizo por bloqueo/procesos Flutter activos. | Completado |
| 2026-07-11 | RF-03, RF-04, RF-05, RNF-09, RNF-12 | AS-053 | Mega panel de busqueda predictiva | Se rediseño unicamente el panel del buscador predictivo para separar sugerencias textuales y productos visuales en dos zonas, con tarjetas comerciales, imagen simulada destacada, vista rapida simulada, cierre con Escape/clic externo y comportamiento responsive. | `frontend/lib/screens/home/home_search_box.dart` y conexion menor en `frontend/lib/screens/home/home_page.dart`; se conservo la misma fuente de productos, modelos, catalogo, filtros y carrito. `dart analyze` sin issues. | Completado |
| 2026-07-11 | RNF-09, RNF-10, RNF-12 | AS-054 | Identidad visual pastel kawaii elegante | Se reemplazo la identidad anterior por una paleta centralizada pastel luminosa con rosa suave, lavanda, melocoton, menta y celeste; se aplicaron DM Serif Display para titulos y Nunito para textos, botones, navegacion y formularios. | `frontend/lib/app/app_design_tokens.dart`, `frontend/lib/app/app_theme.dart`, HomePage, buscador, catalogo, carrito, layout y feedback actualizados sin cambiar servicios ni logica funcional. `dart analyze` sin issues. | Completado |
| 2026-07-11 | RNF-09, RNF-12 | AS-055 | Subrayado animado en menu principal | Se mejoro exclusivamente la interaccion visual de los enlaces principales del header con subrayado animado rosa malva, compatible con hover, foco por teclado y estado activo. | `frontend/lib/widgets/layout/top_navigation.dart` actualizado sin cambiar rutas, navegacion, carrito, sesion ni estructura general del header. `dart analyze` sin issues. | Completado |

| 2026-07-22 | RNF-01, RNF-07, RNF-10 | AS-056 | Arquitectura de auditoria y observabilidad | Se definio una guia simple para manejar GUIDSESION, TraceId, respuestas transaccionales, logs, metricas, trazas, errores de negocio y errores tecnicos. | `docs/arquitectura/ARQUITECTURA_AUDITORIA_OBSERVABILIDAD_TRANSACCIONES.md` creado como propuesta documental sin modificar codigo. | Completado |
| 2026-07-22 | RNF-01, RNF-07, RNF-10 | AS-057 | Diseno tecnico de auditoria de APIs | Se documento la propuesta tecnica para registrar timestamp, path, metodo, datoIngreso, datoRespuesta, TraceId y GUIDSESION por cada llamada relevante al backend. | `docs/arquitectura/DISENO_TECNICO_AUDITORIA_LOGS.md` creado con tabla propuesta, middleware, endpoints futuros de consulta, datos sensibles y pruebas recomendadas. | Completado |
| 2026-07-22 | RNF-01, RNF-07, RNF-10 | AS-058 | Adaptacion de auditoria al dominio Aromas Store | Se ajusto el diseno tecnico para evitar campos ajenos al proyecto y priorizar usuarioId, clienteId, ventaId, productoId, codigoRespuesta y mensajeRespuesta. | `docs/arquitectura/DISENO_TECNICO_AUDITORIA_LOGS.md` actualizado con ejemplos de carrito, venta y reportes adaptados a la tienda. | Completado |
| 2026-07-23 | RNF-01, RNF-07, RNF-10 | AS-059 | Implementacion backend de auditoria de APIs | Se implemento una capa transversal de auditoria para registrar request, response, GUIDSESION, TraceId, duracion, estado HTTP y campos de negocio adaptados a Aromas Store. | `backend/prisma/schema.prisma`, migracion `20260723052000_add_auditoria_logs`, modulo `backend/src/modules/auditoria/`, `backend/src/app.js`, `backend/src/routes/index.js`, `backend/scripts/api-smoke-test.js` y documentacion backend actualizados. | Completado |
| 2026-07-24 | RF-03, RNF-09, RNF-10, RNF-12 | AS-060 | Analisis del modulo de acordes y similitud | Se documento una propuesta candidata para diferenciar Aromas Store mediante acordes aromaticos, intensidades, perfiles de perfume y busqueda de perfumes similares. | `docs/requerimientos/MODULO_ACORDES_Y_SIMILITUD.md` creado con objetivo, alcance, actores, requerimientos, historias, modelo conceptual, UX, backend futuro, frontend futuro, riesgos y decisiones pendientes. | Completado |

## Endpoints Implementados

| Metodo | Ruta | Descripcion | Estado |
|---|---|---|---|
| GET | `/api` | Lista los endpoints disponibles de la API. | Completado |
| GET | `/api/docs` | Abre la documentacion visual de Swagger UI. | Completado |
| GET | `/api/docs.json` | Devuelve la especificacion OpenAPI en formato JSON. | Completado |
| GET | `/api/health` | Verifica que la API este activa. | Completado |
| GET | `/api/productos` | Lista productos con marca, categoria, inventario y filtros opcionales. | Completado |
| GET | `/api/productos/:id` | Consulta un producto por ID. | Completado |
| POST | `/api/productos` | Crea un producto con inventario inicial; protegido para Administrador y Vendedor. | Completado |
| PUT | `/api/productos/:id` | Actualiza datos de producto e inventario; protegido para Administrador y Vendedor. | Completado |
| PATCH | `/api/productos/:id/estado` | Activa o desactiva un producto; protegido para Administrador y Vendedor. | Completado |
| GET | `/api/categorias` | Lista categorias del catalogo. | Completado |
| GET | `/api/categorias/:id` | Consulta una categoria por ID. | Completado |
| POST | `/api/categorias` | Crea una categoria; protegido para Administrador y Vendedor. | Completado |
| PUT | `/api/categorias/:id` | Actualiza una categoria; protegido para Administrador y Vendedor. | Completado |
| PATCH | `/api/categorias/:id/estado` | Activa o desactiva una categoria; protegido para Administrador y Vendedor. | Completado |
| GET | `/api/marcas` | Lista marcas o casas fabricantes. | Completado |
| GET | `/api/marcas/:id` | Consulta una marca por ID. | Completado |
| POST | `/api/marcas` | Crea una marca; protegido para Administrador y Vendedor. | Completado |
| PUT | `/api/marcas/:id` | Actualiza una marca; protegido para Administrador y Vendedor. | Completado |
| PATCH | `/api/marcas/:id/estado` | Activa o desactiva una marca; protegido para Administrador y Vendedor. | Completado |
| POST | `/api/carrito/validar` | Valida productos del carrito, calcula totales y alerta stock menor que 3. | Completado |
| POST | `/api/auth/login` | Inicia sesion y genera token JWT. | Completado |
| GET | `/api/auth/me` | Devuelve el usuario autenticado mediante token. | Completado |
| POST | `/api/clientes/registro` | Registra un cliente comprador y crea su usuario con rol Cliente. | Completado |
| GET | `/api/clientes` | Lista clientes registrados; protegido para Administrador y Vendedor. | Completado |
| POST | `/api/ventas` | Crea una venta pendiente desde un carrito validado; requiere token. | Completado |
| GET | `/api/ventas` | Lista ventas registradas; protegido para Administrador y Vendedor. | Completado |
| POST | `/api/pagos` | Registra pago simulado; si queda PAGADO descuenta inventario. | Completado |
| GET | `/api/pagos` | Lista pagos registrados; protegido para Administrador y Vendedor. | Completado |
| GET | `/api/inventario` | Lista stock actual; protegido para Administrador y Bodeguero. | Completado |
| GET | `/api/inventario/alertas` | Lista productos con stock bajo o bajo minimo. | Completado |
| GET | `/api/inventario/movimientos` | Lista movimientos de inventario. | Completado |
| POST | `/api/inventario/movimientos` | Registra entradas, salidas o ajustes manuales de inventario. | Completado |
| POST | `/api/facturas` | Genera factura para una venta pagada; protegido para Administrador y Vendedor. | Completado |
| GET | `/api/facturas` | Lista facturas registradas; protegido para Administrador y Vendedor. | Completado |
| GET | `/api/facturas/:id` | Consulta una factura por ID; protegido para Administrador y Vendedor. | Completado |
| GET | `/api/promociones` | Lista promociones registradas. | Completado |
| GET | `/api/promociones/:id` | Consulta una promocion por ID. | Completado |
| POST | `/api/promociones` | Crea una promocion; protegido para Administrador y Vendedor. | Completado |
| PUT | `/api/promociones/:id` | Actualiza una promocion; protegido para Administrador y Vendedor. | Completado |
| PATCH | `/api/promociones/:id/estado` | Activa o desactiva una promocion; protegido para Administrador y Vendedor. | Completado |

## Modelo de Base de Datos Actual

Tablas principales:

- `roles`
- `usuarios`
- `clientes`
- `categorias`
- `marcas`
- `productos`
- `inventario`
- `ventas`
- `detalle_ventas`
- `pagos`
- `facturas`
- `promociones`

Decisiones tomadas:

- Se usan IDs autoincrementales en todas las tablas.
- Se usa `id` como clave primaria por tabla.
- Las llaves foraneas se nombran por entidad relacionada, por ejemplo `rolId`, `productoId`, `clienteId`, `ventaId`.
- Se separan entidades para cumplir normalizacion y evitar datos repetidos.
- Se mantiene una base manejable para el alcance academico del proyecto.

## Credenciales de Prueba

Usuario administrador:

```txt
Correo: admin@aromasstore.com
Contrasena: Admin12345
Rol: Administrador
```

## Pendientes Sugeridos

| Codigo | RF relacionado | Actividad | Descripcion | Prioridad | Estado |
|---|---|---|---|---|---|
| AS-033 | RF-03, RF-05, RF-07 | Flutter Web | Crear interfaz publica de catalogo, carrito y pedido. | Alta | Pendiente |
| AS-034 | RNF-10 | UML y documentacion | Crear diagramas de caso de uso, clases, componentes, despliegue y ER. | Alta | Pendiente |
