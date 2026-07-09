import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import {
  actualizarEstadoProducto,
  editarProducto,
  listarProductos,
  registrarProducto,
  verProducto,
} from "./productos.controller.js";

const router = Router();

router.get("/", listarProductos);
router.get("/:id", verProducto);
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
