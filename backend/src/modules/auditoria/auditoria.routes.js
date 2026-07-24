import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import { listarLogs } from "./auditoria.controller.js";

const router = Router();

router.get(
  "/logs",
  requiereAutenticacion,
  requiereRol("Administrador"),
  listarLogs,
);

export default router;
