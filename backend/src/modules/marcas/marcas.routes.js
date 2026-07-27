import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import { listarReferenciasPorMarca } from "../referencias/referencias.controller.js";
import {
  actualizarEstadoMarca,
  editarMarca,
  listarMarcas,
  registrarMarca,
  verMarca,
} from "./marcas.controller.js";

const router = Router();

router.get("/", listarMarcas);
router.get("/:marcaId/referencias", listarReferenciasPorMarca);
router.get("/:id", verMarca);
router.post(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  registrarMarca,
);
router.put(
  "/:id",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  editarMarca,
);
router.patch(
  "/:id/estado",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  actualizarEstadoMarca,
);

export default router;
