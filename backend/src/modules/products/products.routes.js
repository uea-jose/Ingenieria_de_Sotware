import { Router } from "express";

import { listProducts } from "./products.controller.js";

const router = Router();

router.get("/", listProducts);

export default router;

