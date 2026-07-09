import { Router } from "express";

import { login, perfil } from "./auth.controller.js";
import { requiereAutenticacion } from "./auth.middleware.js";

const router = Router();

router.post("/login", login);
router.get("/me", requiereAutenticacion, perfil);

export default router;
