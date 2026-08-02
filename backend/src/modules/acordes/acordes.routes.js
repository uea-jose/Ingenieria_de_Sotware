import { Router } from "express";

import { listarAcordes } from "./acordes.controller.js";

const router = Router();

router.get("/", listarAcordes);

export default router;
