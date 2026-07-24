import { Router } from "express";

import auditoriaRoutes from "../modules/auditoria/auditoria.routes.js";
import authRoutes from "../modules/auth/auth.routes.js";
import brandsRoutes from "../modules/brands/brands.routes.js";
import carritoRoutes from "../modules/carrito/carrito.routes.js";
import categoriesRoutes from "../modules/categories/categories.routes.js";
import clientesRoutes from "../modules/clientes/clientes.routes.js";
import facturasRoutes from "../modules/facturas/facturas.routes.js";
import inventarioRoutes from "../modules/inventario/inventario.routes.js";
import marcasRoutes from "../modules/marcas/marcas.routes.js";
import pagosRoutes from "../modules/pagos/pagos.routes.js";
import productsRoutes from "../modules/products/products.routes.js";
import promocionesRoutes from "../modules/promociones/promociones.routes.js";
import categoriasRoutes from "../modules/categorias/categorias.routes.js";
import productosRoutes from "../modules/productos/productos.routes.js";
import ventasRoutes from "../modules/ventas/ventas.routes.js";

const router = Router();

router.get("/", (req, res) => {
  res.json({
    ok: true,
    service: "Aromas Store API",
    version: "1.0.0",
    endpoints: [
      { metodo: "GET", ruta: "/api/health", descripcion: "Verifica que la API este activa." },
      { metodo: "POST", ruta: "/api/auth/login", descripcion: "Inicia sesion y genera un token JWT." },
      { metodo: "GET", ruta: "/api/auth/me", descripcion: "Devuelve el usuario autenticado mediante token." },
      { metodo: "GET", ruta: "/api/productos", descripcion: "Lista productos con marca, categoria, inventario y filtros opcionales." },
      { metodo: "GET", ruta: "/api/productos/:id", descripcion: "Consulta un producto por id." },
      { metodo: "POST", ruta: "/api/productos", descripcion: "Crea un producto con inventario inicial. Requiere Administrador o Vendedor." },
      { metodo: "PUT", ruta: "/api/productos/:id", descripcion: "Actualiza datos de un producto. Requiere Administrador o Vendedor." },
      { metodo: "PATCH", ruta: "/api/productos/:id/estado", descripcion: "Activa o desactiva un producto. Requiere Administrador o Vendedor." },
      { metodo: "GET", ruta: "/api/categorias", descripcion: "Lista categorias del catalogo." },
      { metodo: "GET", ruta: "/api/categorias/:id", descripcion: "Consulta una categoria por ID." },
      { metodo: "POST", ruta: "/api/categorias", descripcion: "Crea una categoria. Requiere Administrador o Vendedor." },
      { metodo: "PUT", ruta: "/api/categorias/:id", descripcion: "Actualiza una categoria. Requiere Administrador o Vendedor." },
      { metodo: "PATCH", ruta: "/api/categorias/:id/estado", descripcion: "Activa o desactiva una categoria. Requiere Administrador o Vendedor." },
      { metodo: "GET", ruta: "/api/marcas", descripcion: "Lista marcas o casas fabricantes." },
      { metodo: "GET", ruta: "/api/marcas/:id", descripcion: "Consulta una marca por ID." },
      { metodo: "POST", ruta: "/api/marcas", descripcion: "Crea una marca. Requiere Administrador o Vendedor." },
      { metodo: "PUT", ruta: "/api/marcas/:id", descripcion: "Actualiza una marca. Requiere Administrador o Vendedor." },
      { metodo: "PATCH", ruta: "/api/marcas/:id/estado", descripcion: "Activa o desactiva una marca. Requiere Administrador o Vendedor." },
      { metodo: "POST", ruta: "/api/carrito/validar", descripcion: "Valida productos del carrito, calcula totales y alerta stock bajo." },
      { metodo: "POST", ruta: "/api/clientes/registro", descripcion: "Registra un cliente comprador." },
      { metodo: "GET", ruta: "/api/clientes", descripcion: "Lista clientes registrados. Requiere token de Administrador o Vendedor." },
      { metodo: "POST", ruta: "/api/ventas", descripcion: "Crea una venta pendiente desde un carrito validado. Requiere token." },
      { metodo: "GET", ruta: "/api/ventas", descripcion: "Lista ventas registradas. Requiere token de Administrador o Vendedor." },
      { metodo: "POST", ruta: "/api/pagos", descripcion: "Registra pago simulado y descuenta inventario si queda PAGADO." },
      { metodo: "GET", ruta: "/api/pagos", descripcion: "Lista pagos registrados. Requiere token de Administrador o Vendedor." },
      { metodo: "GET", ruta: "/api/inventario", descripcion: "Lista stock actual. Requiere token de Administrador o Bodeguero." },
      { metodo: "GET", ruta: "/api/inventario/alertas", descripcion: "Lista productos con stock bajo o bajo minimo." },
      { metodo: "GET", ruta: "/api/inventario/movimientos", descripcion: "Lista movimientos de inventario." },
      { metodo: "POST", ruta: "/api/inventario/movimientos", descripcion: "Registra entrada, salida o ajuste manual de inventario." },
      { metodo: "POST", ruta: "/api/facturas", descripcion: "Genera factura para una venta pagada." },
      { metodo: "GET", ruta: "/api/facturas", descripcion: "Lista facturas registradas. Requiere Administrador o Vendedor." },
      { metodo: "GET", ruta: "/api/facturas/:id", descripcion: "Consulta una factura por ID. Requiere Administrador o Vendedor." },
      { metodo: "GET", ruta: "/api/promociones", descripcion: "Lista promociones registradas." },
      { metodo: "GET", ruta: "/api/promociones/:id", descripcion: "Consulta una promocion por ID." },
      { metodo: "POST", ruta: "/api/promociones", descripcion: "Crea una promocion. Requiere Administrador o Vendedor." },
      { metodo: "PUT", ruta: "/api/promociones/:id", descripcion: "Actualiza una promocion. Requiere Administrador o Vendedor." },
      { metodo: "PATCH", ruta: "/api/promociones/:id/estado", descripcion: "Activa o desactiva una promocion. Requiere Administrador o Vendedor." },
      { metodo: "GET", ruta: "/api/auditoria/logs", descripcion: "Lista logs de auditoria. Requiere Administrador." },
      { metodo: "GET", ruta: "/api/products", descripcion: "Alias temporal de /api/productos." },
      { metodo: "GET", ruta: "/api/categories", descripcion: "Alias temporal de /api/categorias." },
      { metodo: "GET", ruta: "/api/brands", descripcion: "Alias temporal de /api/marcas." },
    ],
  });
});

router.get("/health", (req, res) => {
  res.json({
    ok: true,
    service: "Aromas Store API",
    timestamp: new Date().toISOString(),
  });
});

router.use("/auth", authRoutes);
router.use("/auditoria", auditoriaRoutes);
router.use("/carrito", carritoRoutes);
router.use("/clientes", clientesRoutes);
router.use("/facturas", facturasRoutes);
router.use("/inventario", inventarioRoutes);
router.use("/marcas", marcasRoutes);
router.use("/pagos", pagosRoutes);
router.use("/promociones", promocionesRoutes);
router.use("/categorias", categoriasRoutes);
router.use("/productos", productosRoutes);
router.use("/ventas", ventasRoutes);

// Aliases kept while the frontend migration is in progress.
router.use("/brands", brandsRoutes);
router.use("/categories", categoriesRoutes);
router.use("/products", productsRoutes);

export default router;
