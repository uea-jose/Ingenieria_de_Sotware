import crypto from "node:crypto";

import { registrarAuditoria } from "./auditoria.service.js";

function obtenerGuidSesion(req) {
  return (
    req.headers["x-guid-sesion"] ||
    req.headers["x-session-id"] ||
    req.body?.Auditoria?.GUIDSESION ||
    req.body?.Auditoria?.IdentificadorGUID ||
    crypto.randomUUID()
  );
}

function obtenerTraceId(req) {
  return (
    req.headers["x-trace-id"] ||
    req.body?.Auditoria?.TraceId ||
    crypto.randomUUID().replaceAll("-", "")
  );
}

export function auditoriaMiddleware(req, res, next) {
  const inicio = Date.now();
  const guidSesion = String(obtenerGuidSesion(req));
  const traceId = String(obtenerTraceId(req));
  const jsonOriginal = res.json.bind(res);

  req.auditoria = {
    guidSesion,
    traceId,
  };

  res.setHeader("X-GUIDSESION", guidSesion);
  res.setHeader("X-Trace-Id", traceId);

  res.json = function jsonConAuditoria(body) {
    const estadoHttp = res.statusCode;
    const duracionMs = Date.now() - inicio;

    registrarAuditoria({
      req,
      datoRespuesta: body,
      estadoHttp,
      duracionMs,
      guidSesion,
      traceId,
    }).catch((error) => {
      console.error("No se pudo registrar auditoria:", error.message);
    });

    return jsonOriginal(body);
  };

  next();
}
