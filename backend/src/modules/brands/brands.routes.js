import { Router } from "express";

import { listBrands } from "./brands.controller.js";

const router = Router();

router.get("/", listBrands);

export default router;

