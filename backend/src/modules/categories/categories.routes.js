import { Router } from "express";

import { listCategories } from "./categories.controller.js";

const router = Router();

router.get("/", listCategories);

export default router;

