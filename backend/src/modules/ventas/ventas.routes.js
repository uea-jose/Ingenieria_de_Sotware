import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import {
  listarMisVentas,
  listarVentas,
  registrarVenta,
} from "./ventas.controller.js";

const router = Router();

router.post(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor", "Cliente"),
  registrarVenta,
);

// Own orders — accessible to any authenticated user. A Cliente sees their
// own history; Administrador/Vendedor still see this route but it filters
// by their own linked Cliente (useful for testing with staff accounts).
// Must be declared BEFORE the generic "/" route so Express matches "/mis"
// as a literal path segment (there is no dynamic ":id" here so ordering
// isn't strictly required, but it makes the intent explicit).
router.get("/mis", requiereAutenticacion, listarMisVentas);

router.get(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  listarVentas,
);

export default router;
