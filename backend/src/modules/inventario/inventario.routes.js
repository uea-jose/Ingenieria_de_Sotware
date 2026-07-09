import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import {
  crearMovimiento,
  listarAlertas,
  listarInventario,
  listarMovimientos,
} from "./inventario.controller.js";

const router = Router();

router.use(requiereAutenticacion);
router.use(requiereRol("Administrador", "Bodeguero"));

router.get("/", listarInventario);
router.get("/alertas", listarAlertas);
router.get("/movimientos", listarMovimientos);
router.post("/movimientos", crearMovimiento);

export default router;
