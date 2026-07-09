import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import { listarVentas, registrarVenta } from "./ventas.controller.js";

const router = Router();

router.post(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor", "Cliente"),
  registrarVenta,
);

router.get(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  listarVentas,
);

export default router;
