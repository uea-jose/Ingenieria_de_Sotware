import swaggerJSDoc from "swagger-jsdoc";
import swaggerUi from "swagger-ui-express";

const swaggerDefinition = {
  openapi: "3.0.0",
  info: {
    title: "Aromas Store API",
    version: "1.0.0",
    description:
      "Documentacion de la API REST para gestion de catalogo, clientes, ventas, pagos, inventario, facturacion y promociones.",
  },
  servers: [
    {
      url: "http://localhost:3000",
      description: "Servidor local de desarrollo",
    },
  ],
  tags: [
    { name: "Sistema" },
    { name: "Autenticacion" },
    { name: "Clientes" },
    { name: "Catalogo" },
    { name: "Acordes" },
    { name: "Referencias" },
    { name: "Carrito" },
    { name: "Ventas" },
    { name: "Pagos" },
    { name: "Inventario" },
    { name: "Facturas" },
    { name: "Promociones" },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT",
      },
    },
    schemas: {
      LoginRequest: {
        type: "object",
        required: ["correo", "contrasena"],
        properties: {
          correo: { type: "string", example: "admin@aromasstore.com" },
          contrasena: { type: "string", example: "Admin12345" },
        },
      },
      ClienteRegistroRequest: {
        type: "object",
        required: ["nombres", "apellidos", "correo", "contrasena"],
        properties: {
          nombres: { type: "string", example: "Cliente" },
          apellidos: { type: "string", example: "Prueba" },
          correo: { type: "string", example: "cliente@aromasstore.com" },
          contrasena: { type: "string", example: "Cliente12345" },
          telefono: { type: "string", example: "0999999999" },
          cedula: { type: "string", example: "1723456789" },
          direccion: { type: "string", example: "Av. Amazonas" },
          ciudad: { type: "string", example: "Quito" },
        },
      },
      ProductoRequest: {
        type: "object",
        required: ["nombre", "codigo", "precio", "categoriaId", "marcaId"],
        properties: {
          nombre: { type: "string", example: "Royal Vanilla" },
          codigo: { type: "string", example: "AS-PERF-001" },
          descripcion: { type: "string", example: "Perfume con notas de vainilla." },
          precio: { type: "number", example: 59.99 },
          volumenMl: { type: "integer", example: 100 },
          imagenUrl: { type: "string", example: "https://example.com/perfume.jpg" },
          categoriaId: { type: "integer", example: 1 },
          marcaId: { type: "integer", example: 2 },
          stock: { type: "integer", example: 25 },
          stockMinimo: { type: "integer", example: 5 },
          ubicacion: { type: "string", example: "Bodega principal" },
        },
      },
      CategoriaRequest: {
        type: "object",
        required: ["nombre"],
        properties: {
          nombre: { type: "string", example: "Perfumes" },
          descripcion: { type: "string", example: "Fragancias personales." },
          activo: { type: "boolean", example: true },
        },
      },
      MarcaRequest: {
        type: "object",
        required: ["nombre"],
        properties: {
          nombre: { type: "string", example: "Carolina Herrera" },
          paisOrigen: { type: "string", example: "Estados Unidos" },
          descripcion: { type: "string", example: "Casa fabricante de fragancias." },
          activo: { type: "boolean", example: true },
        },
      },
      CarritoValidarRequest: {
        type: "object",
        required: ["items"],
        properties: {
          items: {
            type: "array",
            items: {
              type: "object",
              required: ["productoId", "cantidad"],
              properties: {
                productoId: { type: "integer", example: 1 },
                cantidad: { type: "integer", example: 2 },
              },
            },
          },
        },
      },
      VentaRequest: {
        type: "object",
        required: ["clienteId", "items"],
        properties: {
          clienteId: { type: "integer", example: 1 },
          items: {
            type: "array",
            items: {
              type: "object",
              required: ["productoId", "cantidad"],
              properties: {
                productoId: { type: "integer", example: 1 },
                cantidad: { type: "integer", example: 1 },
              },
            },
          },
        },
      },
      PagoRequest: {
        type: "object",
        required: ["ventaId", "metodo", "estado", "monto"],
        properties: {
          ventaId: { type: "integer", example: 3 },
          metodo: { type: "string", example: "EFECTIVO" },
          estado: { type: "string", example: "PAGADO" },
          monto: { type: "number", example: 68.99 },
          referencia: { type: "string", example: "PAGO-001" },
        },
      },
      MovimientoInventarioRequest: {
        type: "object",
        required: ["productoId", "tipo", "cantidad"],
        properties: {
          productoId: { type: "integer", example: 4 },
          tipo: { type: "string", enum: ["ENTRADA", "SALIDA", "AJUSTE"], example: "AJUSTE" },
          cantidad: { type: "integer", example: 2 },
          motivo: { type: "string", example: "Prueba de alerta de stock bajo" },
        },
      },
      FacturaRequest: {
        type: "object",
        required: ["ventaId"],
        properties: {
          ventaId: { type: "integer", example: 3 },
        },
      },
      PromocionRequest: {
        type: "object",
        required: ["productoId", "nombre", "tipo", "valor", "fechaInicio", "fechaFin"],
        properties: {
          productoId: { type: "integer", example: 1 },
          nombre: { type: "string", example: "Promo verano" },
          descripcion: { type: "string", example: "10% de descuento en Royal Vanilla" },
          tipo: { type: "string", enum: ["PORCENTAJE", "MONTO"], example: "PORCENTAJE" },
          valor: { type: "number", example: 10 },
          fechaInicio: { type: "string", format: "date-time", example: "2026-07-08T00:00:00.000Z" },
          fechaFin: { type: "string", format: "date-time", example: "2026-07-31T23:59:59.000Z" },
          activo: { type: "boolean", example: true },
        },
      },
      EstadoRequest: {
        type: "object",
        required: ["activo"],
        properties: {
          activo: { type: "boolean", example: false },
        },
      },
      AcordesProductoRequest: {
        type: "object",
        required: ["acordes"],
        properties: {
          acordes: {
            type: "array",
            minItems: 1,
            items: {
              type: "object",
              required: ["acordeId", "intensidad"],
              properties: {
                acordeId: { type: "integer", example: 14 },
                intensidad: {
                  type: "integer",
                  minimum: 1,
                  maximum: 100,
                  example: 100,
                },
                copiadoDeReferencia: {
                  type: "boolean",
                  example: false,
                },
              },
            },
          },
        },
      },
    },
  },
  paths: {
    "/api": {
      get: {
        tags: ["Sistema"],
        summary: "Lista endpoints disponibles",
        responses: { 200: { description: "Listado de endpoints." } },
      },
    },
    "/api/health": {
      get: {
        tags: ["Sistema"],
        summary: "Verifica que la API este activa",
        responses: { 200: { description: "API activa." } },
      },
    },
    "/api/auth/login": {
      post: {
        tags: ["Autenticacion"],
        summary: "Inicia sesion y genera token JWT",
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/LoginRequest" } } },
        },
        responses: {
          200: { description: "Token generado correctamente." },
          401: { description: "Credenciales invalidas." },
        },
      },
    },
    "/api/auth/me": {
      get: {
        tags: ["Autenticacion"],
        summary: "Consulta el usuario autenticado",
        security: [{ bearerAuth: [] }],
        responses: {
          200: { description: "Datos del usuario autenticado." },
          401: { description: "Token no enviado, invalido o expirado." },
        },
      },
    },
    "/api/clientes/registro": {
      post: {
        tags: ["Clientes"],
        summary: "Registra un cliente comprador",
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/ClienteRegistroRequest" } } },
        },
        responses: { 201: { description: "Cliente registrado." } },
      },
    },
    "/api/clientes": {
      get: {
        tags: ["Clientes"],
        summary: "Lista clientes registrados",
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: "Listado de clientes." } },
      },
    },
    "/api/productos": {
      get: {
        tags: ["Catalogo"],
        summary: "Lista productos con filtros opcionales",
        parameters: [
          { name: "nombre", in: "query", schema: { type: "string" } },
          { name: "marcaId", in: "query", schema: { type: "integer" } },
          { name: "categoriaId", in: "query", schema: { type: "integer" } },
          { name: "precioMin", in: "query", schema: { type: "number" } },
          { name: "precioMax", in: "query", schema: { type: "number" } },
          { name: "activo", in: "query", schema: { type: "boolean" } },
        ],
        responses: { 200: { description: "Listado de productos." } },
      },
      post: {
        tags: ["Catalogo"],
        summary: "Crea un producto con inventario inicial",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/ProductoRequest" } } },
        },
        responses: { 201: { description: "Producto creado." } },
      },
    },
    "/api/productos/{id}": {
      get: {
        tags: ["Catalogo"],
        summary: "Consulta un producto por ID",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
        responses: { 200: { description: "Producto encontrado." } },
      },
      put: {
        tags: ["Catalogo"],
        summary: "Actualiza un producto",
        security: [{ bearerAuth: [] }],
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/ProductoRequest" } } },
        },
        responses: { 200: { description: "Producto actualizado." } },
      },
    },
    "/api/productos/{id}/estado": {
      patch: {
        tags: ["Catalogo"],
        summary: "Activa o desactiva un producto",
        security: [{ bearerAuth: [] }],
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/EstadoRequest" } } },
        },
        responses: { 200: { description: "Estado actualizado." } },
      },
    },
    "/api/productos/{id}/acordes": {
      get: {
        tags: ["Acordes"],
        summary: "Consulta la copia editable del perfil aromático",
        parameters: [
          {
            name: "id",
            in: "path",
            required: true,
            schema: { type: "integer" },
          },
        ],
        responses: { 200: { description: "Perfil editable del producto." } },
      },
      put: {
        tags: ["Acordes"],
        summary: "Guarda y reordena el perfil editable",
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: "id",
            in: "path",
            required: true,
            schema: { type: "integer" },
          },
        ],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: { $ref: "#/components/schemas/AcordesProductoRequest" },
            },
          },
        },
        responses: { 200: { description: "Perfil guardado y reordenado." } },
      },
    },
    "/api/productos/{id}/restaurar-acordes": {
      post: {
        tags: ["Acordes"],
        summary: "Restaura el perfil desde la referencia maestra",
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: "id",
            in: "path",
            required: true,
            schema: { type: "integer" },
          },
        ],
        responses: { 200: { description: "Perfil maestro restaurado." } },
      },
    },
    "/api/categorias": {
      get: {
        tags: ["Catalogo"],
        summary: "Lista categorias",
        responses: { 200: { description: "Listado de categorias." } },
      },
      post: {
        tags: ["Catalogo"],
        summary: "Crea una categoria",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/CategoriaRequest" } } },
        },
        responses: { 201: { description: "Categoria creada." } },
      },
    },
    "/api/marcas": {
      get: {
        tags: ["Catalogo"],
        summary: "Lista marcas",
        responses: { 200: { description: "Listado de marcas." } },
      },
      post: {
        tags: ["Catalogo"],
        summary: "Crea una marca",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/MarcaRequest" } } },
        },
        responses: { 201: { description: "Marca creada." } },
      },
    },
    "/api/marcas/{id}/referencias": {
      get: {
        tags: ["Referencias"],
        summary: "Lista referencias aromáticas de una marca",
        parameters: [
          {
            name: "id",
            in: "path",
            required: true,
            schema: { type: "integer" },
          },
        ],
        responses: { 200: { description: "Referencias activas de la marca." } },
      },
    },
    "/api/acordes": {
      get: {
        tags: ["Acordes"],
        summary: "Lista el catálogo maestro de acordes y colores",
        responses: { 200: { description: "Catálogo maestro de acordes." } },
      },
    },
    "/api/referencias/{id}": {
      get: {
        tags: ["Referencias"],
        summary: "Consulta una referencia aromática maestra",
        parameters: [
          {
            name: "id",
            in: "path",
            required: true,
            schema: { type: "integer" },
          },
        ],
        responses: { 200: { description: "Referencia encontrada." } },
      },
    },
    "/api/referencias/{id}/acordes": {
      get: {
        tags: ["Referencias"],
        summary: "Consulta el perfil maestro de una referencia",
        parameters: [
          {
            name: "id",
            in: "path",
            required: true,
            schema: { type: "integer" },
          },
        ],
        responses: { 200: { description: "Perfil aromático maestro." } },
      },
    },
    "/api/carrito/validar": {
      post: {
        tags: ["Carrito"],
        summary: "Valida carrito, stock y totales con IVA 15%",
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/CarritoValidarRequest" } } },
        },
        responses: { 200: { description: "Carrito validado." } },
      },
    },
    "/api/ventas": {
      get: {
        tags: ["Ventas"],
        summary: "Lista ventas registradas",
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: "Listado de ventas." } },
      },
      post: {
        tags: ["Ventas"],
        summary: "Crea una venta pendiente",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/VentaRequest" } } },
        },
        responses: { 201: { description: "Venta creada." } },
      },
    },
    "/api/pagos": {
      get: {
        tags: ["Pagos"],
        summary: "Lista pagos registrados",
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: "Listado de pagos." } },
      },
      post: {
        tags: ["Pagos"],
        summary: "Registra pago simulado",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/PagoRequest" } } },
        },
        responses: { 201: { description: "Pago registrado." } },
      },
    },
    "/api/inventario": {
      get: {
        tags: ["Inventario"],
        summary: "Lista stock actual",
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: "Inventario actual." } },
      },
    },
    "/api/inventario/alertas": {
      get: {
        tags: ["Inventario"],
        summary: "Lista productos con stock bajo",
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: "Alertas de stock." } },
      },
    },
    "/api/inventario/movimientos": {
      get: {
        tags: ["Inventario"],
        summary: "Lista movimientos de inventario",
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: "Movimientos de inventario." } },
      },
      post: {
        tags: ["Inventario"],
        summary: "Registra entrada, salida o ajuste de inventario",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            "application/json": { schema: { $ref: "#/components/schemas/MovimientoInventarioRequest" } },
          },
        },
        responses: { 201: { description: "Movimiento registrado." } },
      },
    },
    "/api/facturas": {
      get: {
        tags: ["Facturas"],
        summary: "Lista facturas",
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: "Listado de facturas." } },
      },
      post: {
        tags: ["Facturas"],
        summary: "Genera factura de una venta pagada",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/FacturaRequest" } } },
        },
        responses: { 201: { description: "Factura generada." } },
      },
    },
    "/api/facturas/{id}": {
      get: {
        tags: ["Facturas"],
        summary: "Consulta una factura por ID",
        security: [{ bearerAuth: [] }],
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
        responses: { 200: { description: "Factura encontrada." } },
      },
    },
    "/api/promociones": {
      get: {
        tags: ["Promociones"],
        summary: "Lista promociones",
        responses: { 200: { description: "Listado de promociones." } },
      },
      post: {
        tags: ["Promociones"],
        summary: "Crea una promocion",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/PromocionRequest" } } },
        },
        responses: { 201: { description: "Promocion creada." } },
      },
    },
    "/api/promociones/{id}": {
      get: {
        tags: ["Promociones"],
        summary: "Consulta una promocion por ID",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
        responses: { 200: { description: "Promocion encontrada." } },
      },
      put: {
        tags: ["Promociones"],
        summary: "Actualiza una promocion",
        security: [{ bearerAuth: [] }],
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/PromocionRequest" } } },
        },
        responses: { 200: { description: "Promocion actualizada." } },
      },
    },
    "/api/promociones/{id}/estado": {
      patch: {
        tags: ["Promociones"],
        summary: "Activa o desactiva una promocion",
        security: [{ bearerAuth: [] }],
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { $ref: "#/components/schemas/EstadoRequest" } } },
        },
        responses: { 200: { description: "Estado actualizado." } },
      },
    },
  },
};

const swaggerSpec = swaggerJSDoc({
  definition: swaggerDefinition,
  apis: [],
});

const swaggerUiOptions = {
  explorer: true,
  customSiteTitle: "Aromas Store API Docs",
};

export { swaggerSpec, swaggerUi, swaggerUiOptions };
