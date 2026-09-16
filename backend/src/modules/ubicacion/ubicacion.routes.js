import { Router } from "express";

import { reverse } from "./ubicacion.controller.js";

const router = Router();

// Public endpoint — the customer needs to be able to hit this before
// they finish authenticating (the checkout page also relies on it, but
// exposing it to anonymous browsers means the reverse geocoding cache
// warms up sooner and it doesn't leak any private data.)
router.get("/reverse", reverse);

export default router;
