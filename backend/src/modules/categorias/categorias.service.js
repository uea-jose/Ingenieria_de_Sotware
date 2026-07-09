import prisma from "../../config/prisma.js";

export async function obtenerCategorias() {
  return prisma.categoria.findMany({
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

function validarCategoria(datos, parcial = false) {
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

function mapearCategoria(datos) {
  const data = {};

  if (datos.nombre !== undefined) {
    data.nombre = datos.nombre.trim();
  }

  if (datos.descripcion !== undefined) {
    data.descripcion = datos.descripcion?.trim() || null;
  }

  if (datos.activo !== undefined) {
    data.activo = convertirBooleano(datos.activo);
  }

  return data;
}

export async function obtenerCategoriaPorId(id) {
  const categoriaId = convertirId(id);
  const categoria = await prisma.categoria.findUnique({
    where: { id: categoriaId },
  });

  if (!categoria) {
    const error = new Error("La categoria indicada no existe.");
    error.status = 404;
    throw error;
  }

  return categoria;
}

export async function crearCategoria(datos) {
  validarCategoria(datos);

  try {
    return await prisma.categoria.create({
      data: {
        ...mapearCategoria(datos),
        activo: datos.activo === undefined ? true : convertirBooleano(datos.activo),
      },
    });
  } catch (error) {
    if (error.code === "P2002") {
      const conflicto = new Error("Ya existe una categoria con ese nombre.");
      conflicto.status = 409;
      throw conflicto;
    }

    throw error;
  }
}

export async function actualizarCategoria(id, datos) {
  const categoriaId = convertirId(id);
  validarCategoria(datos, true);
  await obtenerCategoriaPorId(categoriaId);

  try {
    return await prisma.categoria.update({
      where: { id: categoriaId },
      data: mapearCategoria(datos),
    });
  } catch (error) {
    if (error.code === "P2002") {
      const conflicto = new Error("Ya existe una categoria con ese nombre.");
      conflicto.status = 409;
      throw conflicto;
    }

    throw error;
  }
}

export async function cambiarEstadoCategoria(id, activo) {
  const categoriaId = convertirId(id);
  await obtenerCategoriaPorId(categoriaId);

  return prisma.categoria.update({
    where: { id: categoriaId },
    data: { activo: convertirBooleano(activo) },
  });
}
