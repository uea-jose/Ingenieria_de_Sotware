import prisma from "../../config/prisma.js";

const CAMPOS_SENSIBLES = new Set([
  "authorization",
  "contrasena",
  "contrasenaHash",
  "password",
  "token",
]);

function normalizarClave(clave) {
  return String(clave).toLowerCase();
}

export function limpiarDatosSensibles(valor, visitados = new WeakSet()) {
  if (valor === null || valor === undefined) {
    return valor;
  }

  if (typeof valor === "bigint") {
    return valor.toString();
  }

  if (typeof valor !== "object") {
    return valor;
  }

  if (visitados.has(valor)) {
    return "[Circular]";
  }

  visitados.add(valor);

  if (Array.isArray(valor)) {
    return valor.map((item) => limpiarDatosSensibles(item, visitados));
  }

  if (valor instanceof Date) {
    return valor.toISOString();
  }

  const limpio = {};

  for (const [clave, contenido] of Object.entries(valor)) {
    if (CAMPOS_SENSIBLES.has(normalizarClave(clave))) {
      limpio[clave] = "***";
      continue;
    }

    limpio[clave] = limpiarDatosSensibles(contenido, visitados);
  }

  return limpio;
}

function convertirJsonSeguro(valor) {
  if (valor === undefined) {
    return undefined;
  }

  const limpio = limpiarDatosSensibles(valor);

  return JSON.parse(
    JSON.stringify(limpio, (_clave, contenido) => {
      if (typeof contenido === "bigint") {
        return contenido.toString();
      }

      return contenido;
    }),
  );
}

function obtenerPrimerProductoId(body = {}, respuesta = {}) {
  const itemEntrada = body.items?.[0] || body.Datos?.items?.[0];
  const itemRespuesta = respuesta.items?.[0] || respuesta.datos?.items?.[0] || respuesta.venta?.detalles?.[0];

  return itemEntrada?.productoId ?? itemRespuesta?.productoId ?? null;
}

function obtenerVentaId(body = {}, respuesta = {}) {
  return body.ventaId ?? respuesta.venta?.id ?? respuesta.dato?.ventaId ?? respuesta.dato?.venta?.id ?? null;
}

function obtenerClienteId(body = {}, respuesta = {}) {
  return body.clienteId ?? respuesta.venta?.clienteId ?? respuesta.dato?.clienteId ?? respuesta.dato?.venta?.clienteId ?? null;
}

function obtenerCodigoRespuesta(respuesta = {}, estadoHttp) {
  return (
    respuesta.Respuesta?.Codigo ??
    respuesta.codigo ??
    respuesta.error ??
    (estadoHttp >= 200 && estadoHttp < 400 ? "00000" : String(estadoHttp))
  );
}

function obtenerMensajeRespuesta(respuesta = {}, estadoHttp) {
  return (
    respuesta.Respuesta?.Mensaje ??
    respuesta.mensaje ??
    respuesta.error ??
    (estadoHttp >= 200 && estadoHttp < 400 ? "Operacion procesada correctamente" : "Operacion no procesada")
  );
}

function obtenerResultado(estadoHttp) {
  if (estadoHttp >= 200 && estadoHttp < 400) {
    return "OK";
  }

  if (estadoHttp >= 400 && estadoHttp < 500) {
    return "ERROR_NEGOCIO";
  }

  return "ERROR_TECNICO";
}

export async function registrarAuditoria({
  req,
  datoRespuesta,
  estadoHttp,
  duracionMs,
  traceId,
  guidSesion,
}) {
  const datoIngreso = convertirJsonSeguro({
    body: req.body,
    query: req.query,
    params: req.params,
  });
  const respuestaSegura = convertirJsonSeguro(datoRespuesta);

  await prisma.auditoriaLog.create({
    data: {
      path: req.originalUrl,
      metodo: req.method,
      datoIngreso,
      datoRespuesta: respuestaSegura,
      traceId,
      guidSesion,
      usuarioId: req.usuario?.id ?? null,
      clienteId: obtenerClienteId(req.body, datoRespuesta),
      ventaId: obtenerVentaId(req.body, datoRespuesta),
      productoId: obtenerPrimerProductoId(req.body, datoRespuesta),
      estadoHttp,
      duracionMs,
      resultado: obtenerResultado(estadoHttp),
      codigoRespuesta: String(obtenerCodigoRespuesta(datoRespuesta, estadoHttp)).slice(0, 80),
      mensajeRespuesta: String(obtenerMensajeRespuesta(datoRespuesta, estadoHttp)).slice(0, 255),
    },
  });
}

export async function listarAuditoriaLogs(filtros = {}) {
  const where = {};
  const take = Math.min(Number.parseInt(filtros.limit || "50", 10) || 50, 200);
  const traceId = filtros.traceId || filtros.TraceId;
  const guidSesion = filtros.guidSesion || filtros.GUIDSESION;

  if (traceId) {
    where.traceId = String(traceId);
  }

  if (guidSesion) {
    where.guidSesion = String(guidSesion);
  }

  if (filtros.path) {
    where.path = String(filtros.path);
  }

  for (const campo of ["usuarioId", "clienteId", "ventaId", "productoId"]) {
    if (filtros[campo]) {
      const valor = Number.parseInt(filtros[campo], 10);

      if (!Number.isNaN(valor)) {
        where[campo] = valor;
      }
    }
  }

  return prisma.auditoriaLog.findMany({
    where,
    orderBy: { fecha: "desc" },
    take,
  });
}
