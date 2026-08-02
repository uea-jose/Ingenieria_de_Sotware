import prisma from "../../config/prisma.js";

function convertirId(valor, nombreCampo = "id") {
  const id = Number.parseInt(valor, 10);

  if (!Number.isInteger(id) || id <= 0) {
    const error = new Error(`${nombreCampo} debe ser un entero positivo.`);
    error.status = 400;
    throw error;
  }

  return id;
}

function lanzarNoEncontrado(mensaje) {
  const error = new Error(mensaje);
  error.status = 404;
  throw error;
}

export async function obtenerReferenciasPorMarca(marcaId) {
  const id = convertirId(marcaId, "marcaId");

  return prisma.referenciaPerfume.findMany({
    where: {
      marcaId: id,
      activo: true,
      marca: { activo: true },
    },
    orderBy: [{ nombre: "asc" }, { id: "asc" }],
    select: {
      id: true,
      nombre: true,
      slug: true,
      genero: true,
      segmento: true,
      aliasCatalogo: true,
      versionPerfil: true,
    },
  });
}

export async function obtenerReferenciaPorId(referenciaId) {
  const id = convertirId(referenciaId, "referenciaId");
  const referencia = await prisma.referenciaPerfume.findFirst({
    where: { id, activo: true },
    include: {
      marca: {
        select: {
          id: true,
          nombre: true,
          paisOrigen: true,
        },
      },
    },
  });

  if (!referencia) {
    lanzarNoEncontrado("La referencia indicada no existe o está inactiva.");
  }

  return referencia;
}

export async function obtenerAcordesDeReferencia(referenciaId) {
  const referencia = await obtenerReferenciaPorId(referenciaId);
  const acordes = await prisma.referenciaPerfumeAcorde.findMany({
    where: { referenciaId: referencia.id },
    orderBy: { ordenVisual: "asc" },
    select: {
      intensidad: true,
      ordenVisual: true,
      metodoFuente: true,
      confianza: true,
      acorde: {
        select: {
          id: true,
          nombre: true,
          slug: true,
          colorHex: true,
          colorTextoHex: true,
          origenColor: true,
          alias: true,
        },
      },
    },
  });

  return {
    referencia: {
      id: referencia.id,
      nombre: referencia.nombre,
      versionPerfil: referencia.versionPerfil,
    },
    acordes,
  };
}
