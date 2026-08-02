import { Router } from "express";

import {
  verAcordesDeReferencia,
  verReferencia,
} from "./referencias.controller.js";

const router = Router();

router.get("/:id/acordes", verAcordesDeReferencia);
router.get("/:id", verReferencia);

export default router;
