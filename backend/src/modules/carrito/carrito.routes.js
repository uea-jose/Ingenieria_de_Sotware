import { Router } from "express";

import { validar } from "./carrito.controller.js";

const router = Router();

router.post("/validar", validar);

export default router;
