import { obtenerAcordes } from "./acordes.service.js";

export async function listarAcordes(req, res, next) {
  try {
    const acordes = await obtenerAcordes();

    res.json({
      datos: acordes,
      total: acordes.length,
    });
  } catch (error) {
    next(error);
  }
}
