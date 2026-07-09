import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import { crearPago, listarPagos } from "./pagos.controller.js";

const router = Router();

router.post(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  crearPago,
);

router.get(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  listarPagos,
);

export default router;
