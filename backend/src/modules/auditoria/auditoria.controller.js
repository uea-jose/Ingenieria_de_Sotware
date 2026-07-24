import { listarAuditoriaLogs } from "./auditoria.service.js";

export async function listarLogs(req, res, next) {
  try {
    const logs = await listarAuditoriaLogs(req.query);

    res.json({
      datos: logs,
      total: logs.length,
    });
  } catch (error) {
    next(error);
  }
}
