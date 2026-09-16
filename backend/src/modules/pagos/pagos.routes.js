import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import {
  confirmarPagoPendiente,
  crearPago,
  listarPagos,
} from "./pagos.controller.js";

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

// Confirma un Pago PENDIENTE existente (no re-pregunta el metodo, lo
// lee del registro). Se usa desde el panel admin para "Confirmar
// transferencia" y "Registrar cobro".
router.post(
  "/:id/confirmar",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  confirmarPagoPendiente,
);

export default router;
