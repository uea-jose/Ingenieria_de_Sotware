import { Router } from "express";

import { requiereAutenticacion, requiereRol } from "../auth/auth.middleware.js";
import {
  actualizarEstadoCategoria,
  editarCategoria,
  listarCategorias,
  registrarCategoria,
  verCategoria,
} from "./categorias.controller.js";

const router = Router();

router.get("/", listarCategorias);
router.get("/:id", verCategoria);
router.post(
  "/",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  registrarCategoria,
);
router.put(
  "/:id",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  editarCategoria,
);
router.patch(
  "/:id/estado",
  requiereAutenticacion,
  requiereRol("Administrador", "Vendedor"),
  actualizarEstadoCategoria,
);

export default router;
