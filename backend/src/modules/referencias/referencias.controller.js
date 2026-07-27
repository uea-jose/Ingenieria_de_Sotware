import {
  obtenerAcordesDeReferencia,
  obtenerReferenciaPorId,
  obtenerReferenciasPorMarca,
} from "./referencias.service.js";

export async function listarReferenciasPorMarca(req, res, next) {
  try {
    const referencias = await obtenerReferenciasPorMarca(req.params.marcaId);

    res.json({
      datos: referencias,
      total: referencias.length,
    });
  } catch (error) {
    next(error);
  }
}

export async function verReferencia(req, res, next) {
  try {
    res.json({
      dato: await obtenerReferenciaPorId(req.params.id),
    });
  } catch (error) {
    next(error);
  }
}

export async function verAcordesDeReferencia(req, res, next) {
  try {
    const resultado = await obtenerAcordesDeReferencia(req.params.id);

    res.json({
      datos: resultado.acordes,
      total: resultado.acordes.length,
      referencia: resultado.referencia,
    });
  } catch (error) {
    next(error);
  }
}
