import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import { crearFactura, listarFacturas, verFactura } from "./facturas.controller.js";

const router = Router();

router.use(requiereAutenticacion);
router.use(requiereRol("Administrador", "Vendedor"));

router.get("/", listarFacturas);
router.get("/:id", verFactura);
router.post("/", crearFactura);

export default router;
