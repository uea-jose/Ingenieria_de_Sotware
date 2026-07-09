import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import {
  actualizarEstadoPromocion,
  editarPromocion,
  listarPromociones,
  registrarPromocion,
  verPromocion,
} from "./promociones.controller.js";

const router = Router();

router.get("/", listarPromociones);
router.get("/:id", verPromocion);
router.post(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  registrarPromocion,
);
router.put(
  "/:id",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  editarPromocion,
);
router.patch(
  "/:id/estado",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  actualizarEstadoPromocion,
);

export default router;
