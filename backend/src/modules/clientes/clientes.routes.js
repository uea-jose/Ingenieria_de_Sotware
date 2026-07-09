import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import { crearCliente, listarClientes } from "./clientes.controller.js";

const router = Router();

router.post("/registro", crearCliente);
router.get(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  listarClientes,
);

export default router;
