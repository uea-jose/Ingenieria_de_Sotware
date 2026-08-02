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

function errorConEstado(mensaje, status = 400) {
  const error = new Error(mensaje);
  error.status = status;
  return error;
}

async function obtenerProductoBase(client, productoId) {
  const producto = await client.producto.findUnique({
    where: { id: productoId },
    select: {
      id: true,
      nombre: true,
      imagenUrl: true,
      referenciaId: true,
      versionPerfilReferenciaCopiado: true,
      acordesCopiadosEn: true,
    },
  });

  if (!producto) {
    throw errorConEstado("El producto indicado no existe.", 404);
  }

  return producto;
}

function normalizarAcordes(acordes) {
  if (!Array.isArray(acordes) || acordes.length === 0) {
    throw errorConEstado("acordes debe contener al menos un elemento.");
  }

  const ids = new Set();
  const normalizados = acordes.map((item, indiceAnterior) => {
    const acordeId = convertirId(item?.acordeId, "acordeId");
    const intensidad = Number.parseInt(item?.intensidad, 10);

    if (!Number.isInteger(intensidad) || intensidad < 1 || intensidad > 100) {
      throw errorConEstado("intensidad debe ser un entero entre 1 y 100.");
    }

    if (ids.has(acordeId)) {
      throw errorConEstado("No se permiten acordes repetidos.");
    }

    ids.add(acordeId);

    return {
      acordeId,
      intensidad,
      indiceAnterior,
      copiadoDeReferencia: item?.copiadoDeReferencia === true,
    };
  });

  return normalizados
    .sort(
      (primero, segundo) =>
        segundo.intensidad - primero.intensidad ||
        primero.indiceAnterior - segundo.indiceAnterior,
    )
    .map((item, index) => ({
      acordeId: item.acordeId,
      intensidad: item.intensidad,
      ordenVisual: index + 1,
      copiadoDeReferencia: item.copiadoDeReferencia,
    }));
}

export async function obtenerAcordesDeProducto(productoId) {
  const id = convertirId(productoId, "productoId");
  const producto = await obtenerProductoBase(prisma, id);
  const acordes = await prisma.productoAcorde.findMany({
    where: { productoId: id },
    orderBy: { ordenVisual: "asc" },
    select: {
      intensidad: true,
      ordenVisual: true,
      copiadoDeReferencia: true,
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

  return { producto, acordes };
}

export async function guardarAcordesDeProducto(productoId, datos) {
  const id = convertirId(productoId, "productoId");
  const acordes = normalizarAcordes(datos?.acordes);

  await prisma.$transaction(async (tx) => {
    await obtenerProductoBase(tx, id);

    const cantidadAcordes = await tx.acorde.count({
      where: {
        id: { in: acordes.map((item) => item.acordeId) },
        activo: true,
      },
    });

    if (cantidadAcordes !== acordes.length) {
      throw errorConEstado(
        "Uno o más acordes no existen o se encuentran inactivos.",
      );
    }

    await tx.productoAcorde.deleteMany({
      where: { productoId: id },
    });

    await tx.productoAcorde.createMany({
      data: acordes.map((item) => ({
        productoId: id,
        ...item,
      })),
    });
  });

  return obtenerAcordesDeProducto(id);
}

export async function restaurarAcordesDeProducto(productoId) {
  const id = convertirId(productoId, "productoId");

  await prisma.$transaction(async (tx) => {
    const producto = await obtenerProductoBase(tx, id);

    if (!producto.referenciaId) {
      throw errorConEstado(
        "El producto no tiene una referencia maestra asociada.",
        409,
      );
    }

    const referencia = await tx.referenciaPerfume.findFirst({
      where: {
        id: producto.referenciaId,
        activo: true,
      },
      include: {
        acordes: {
          orderBy: { ordenVisual: "asc" },
        },
      },
    });

    if (!referencia) {
      throw errorConEstado(
        "La referencia maestra no existe o está inactiva.",
        409,
      );
    }

    if (referencia.acordes.length === 0) {
      throw errorConEstado(
        "La referencia maestra todavía no tiene acordes.",
        409,
      );
    }

    await tx.productoAcorde.deleteMany({
      where: { productoId: id },
    });

    await tx.productoAcorde.createMany({
      data: referencia.acordes.map((item) => ({
        productoId: id,
        acordeId: item.acordeId,
        intensidad: item.intensidad,
        ordenVisual: item.ordenVisual,
        copiadoDeReferencia: true,
      })),
    });

    await tx.producto.update({
      where: { id },
      data: {
        versionPerfilReferenciaCopiado: referencia.versionPerfil,
        acordesCopiadosEn: new Date(),
      },
    });
  });

  return obtenerAcordesDeProducto(id);
}
