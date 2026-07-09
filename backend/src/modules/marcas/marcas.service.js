import prisma from "../../config/prisma.js";

export async function obtenerMarcas() {
  return prisma.marca.findMany({
    orderBy: { nombre: "asc" },
  });
}

function convertirId(valor, nombreCampo = "id") {
  const numero = Number.parseInt(valor, 10);

  if (Number.isNaN(numero) || numero <= 0) {
    const error = new Error(`${nombreCampo} debe ser un numero entero positivo.`);
    error.status = 400;
    throw error;
  }

  return numero;
}

function convertirBooleano(valor) {
  if (valor === "true" || valor === true) {
    return true;
  }

  if (valor === "false" || valor === false) {
    return false;
  }

  const error = new Error("activo debe ser true o false.");
  error.status = 400;
  throw error;
}

function validarMarca(datos, parcial = false) {
  if (!parcial && !datos.nombre) {
    const error = new Error("nombre es obligatorio.");
    error.status = 400;
    throw error;
  }

  if (datos.nombre !== undefined && !datos.nombre.trim()) {
    const error = new Error("nombre no puede estar vacio.");
    error.status = 400;
    throw error;
  }
}

function mapearMarca(datos) {
  const data = {};

  for (const campo of ["nombre", "paisOrigen", "descripcion"]) {
    if (datos[campo] !== undefined) {
      data[campo] = datos[campo]?.trim() || null;
    }
  }

  if (datos.activo !== undefined) {
    data.activo = convertirBooleano(datos.activo);
  }

  return data;
}

export async function obtenerMarcaPorId(id) {
  const marcaId = convertirId(id);
  const marca = await prisma.marca.findUnique({
    where: { id: marcaId },
  });

  if (!marca) {
    const error = new Error("La marca indicada no existe.");
    error.status = 404;
    throw error;
  }

  return marca;
}

export async function crearMarca(datos) {
  validarMarca(datos);

  try {
    return await prisma.marca.create({
      data: {
        ...mapearMarca(datos),
        activo: datos.activo === undefined ? true : convertirBooleano(datos.activo),
      },
    });
  } catch (error) {
    if (error.code === "P2002") {
      const conflicto = new Error("Ya existe una marca con ese nombre.");
      conflicto.status = 409;
      throw conflicto;
    }

    throw error;
  }
}

export async function actualizarMarca(id, datos) {
  const marcaId = convertirId(id);
  validarMarca(datos, true);
  await obtenerMarcaPorId(marcaId);

  try {
    return await prisma.marca.update({
      where: { id: marcaId },
      data: mapearMarca(datos),
    });
  } catch (error) {
    if (error.code === "P2002") {
      const conflicto = new Error("Ya existe una marca con ese nombre.");
      conflicto.status = 409;
      throw conflicto;
    }

    throw error;
  }
}

export async function cambiarEstadoMarca(id, activo) {
  const marcaId = convertirId(id);
  await obtenerMarcaPorId(marcaId);

  return prisma.marca.update({
    where: { id: marcaId },
    data: { activo: convertirBooleano(activo) },
  });
}
