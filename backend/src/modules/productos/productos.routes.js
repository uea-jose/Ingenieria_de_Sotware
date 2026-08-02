import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import {
  actualizarEstadoProducto,
  editarAcordesProducto,
  editarProducto,
  listarProductos,
  registrarProducto,
  restaurarAcordesProducto,
  verAcordesProducto,
  verProducto,
} from "./productos.controller.js";

const router = Router();

router.get("/", listarProductos);
router.get("/:id/acordes", verAcordesProducto);
router.get("/:id", verProducto);
router.put(
  "/:id/acordes",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  editarAcordesProducto,
);
router.post(
  "/:id/restaurar-acordes",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  restaurarAcordesProducto,
);
router.post(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  registrarProducto,
);
router.put(
  "/:id",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  editarProducto,
);
router.patch(
  "/:id/estado",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  actualizarEstadoProducto,
);

export default router;
