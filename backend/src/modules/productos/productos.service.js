import prisma from "../../config/prisma.js";

function convertirEntero(valor, nombreCampo) {
  if (valor === undefined || valor === null || valor === "") {
    return undefined;
  }

  const numero = Number.parseInt(valor, 10);

  if (Number.isNaN(numero)) {
    const error = new Error(`${nombreCampo} debe ser un numero entero.`);
    error.status = 400;
    throw error;
  }

  return numero;
}

function convertirDecimal(valor, nombreCampo) {
  if (valor === undefined || valor === null || valor === "") {
    return undefined;
  }

  const numero = Number.parseFloat(valor);

  if (Number.isNaN(numero)) {
    const error = new Error(`${nombreCampo} debe ser un numero valido.`);
    error.status = 400;
    throw error;
  }

  return numero;
}

function convertirBooleano(valor) {
  if (valor === undefined || valor === null || valor === "") {
    return undefined;
  }

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

function construirFiltros(query = {}) {
  const nombre = query.nombre?.trim();
  const marcaId = convertirEntero(query.marcaId, "marcaId");
  const categoriaId = convertirEntero(query.categoriaId, "categoriaId");
  const precioMin = convertirDecimal(query.precioMin, "precioMin");
  const precioMax = convertirDecimal(query.precioMax, "precioMax");
  const activo = convertirBooleano(query.activo);
  const where = {};

  if (nombre) {
    where.nombre = {
      contains: nombre,
      mode: "insensitive",
    };
  }

  if (marcaId !== undefined) {
    where.marcaId = marcaId;
  }

  if (categoriaId !== undefined) {
    where.categoriaId = categoriaId;
  }

  if (precioMin !== undefined || precioMax !== undefined) {
    where.precio = {};

    if (precioMin !== undefined) {
      where.precio.gte = precioMin;
    }

    if (precioMax !== undefined) {
      where.precio.lte = precioMax;
    }
  }

  if (activo !== undefined) {
    where.activo = activo;
  }

  return {
    where,
    filtrosAplicados: {
      nombre: nombre || null,
      marcaId: marcaId ?? null,
      categoriaId: categoriaId ?? null,
      precioMin: precioMin ?? null,
      precioMax: precioMax ?? null,
      activo: activo ?? null,
    },
  };
}

export async function obtenerProductos(query = {}) {
  const { where, filtrosAplicados } = construirFiltros(query);

  const productos = await prisma.producto.findMany({
    where,
    orderBy: { id: "asc" },
    include: {
      marca: true,
      categoria: true,
      inventario: true,
    },
  });

  return {
    productos,
    filtrosAplicados,
  };
}

function validarProducto(datos, parcial = false) {
  const requeridos = ["nombre", "codigo", "precio", "categoriaId", "marcaId"];

  if (!parcial) {
    const faltantes = requeridos.filter((campo) => datos[campo] === undefined || datos[campo] === null || datos[campo] === "");

    if (faltantes.length > 0) {
      const error = new Error(`Campos obligatorios faltantes: ${faltantes.join(", ")}.`);
      error.status = 400;
      throw error;
    }
  }

  if (datos.precio !== undefined) {
    const precio = convertirDecimal(datos.precio, "precio");

    if (precio <= 0) {
      const error = new Error("precio debe ser mayor a cero.");
      error.status = 400;
      throw error;
    }
  }

  if (datos.volumenMl !== undefined && datos.volumenMl !== null) {
    const volumenMl = convertirEntero(datos.volumenMl, "volumenMl");

    if (volumenMl <= 0) {
      const error = new Error("volumenMl debe ser mayor a cero.");
      error.status = 400;
      throw error;
    }
  }

  if (datos.categoriaId !== undefined) {
    convertirEntero(datos.categoriaId, "categoriaId");
  }

  if (datos.marcaId !== undefined) {
    convertirEntero(datos.marcaId, "marcaId");
  }

  if (datos.stock !== undefined) {
    const stock = convertirEntero(datos.stock, "stock");

    if (stock < 0) {
      const error = new Error("stock no puede ser negativo.");
      error.status = 400;
      throw error;
    }
  }

  if (datos.stockMinimo !== undefined) {
    const stockMinimo = convertirEntero(datos.stockMinimo, "stockMinimo");

    if (stockMinimo < 0) {
      const error = new Error("stockMinimo no puede ser negativo.");
      error.status = 400;
      throw error;
    }
  }
}

function mapearProductoData(datos) {
  const data = {};

  for (const campo of ["nombre", "codigo", "descripcion", "imagenUrl"]) {
    if (datos[campo] !== undefined) {
      data[campo] = typeof datos[campo] === "string" ? datos[campo].trim() : datos[campo];
    }
  }

  if (datos.precio !== undefined) {
    data.precio = convertirDecimal(datos.precio, "precio");
  }

  if (datos.volumenMl !== undefined) {
    data.volumenMl = datos.volumenMl === null ? null : convertirEntero(datos.volumenMl, "volumenMl");
  }

  if (datos.activo !== undefined) {
    data.activo = convertirBooleano(datos.activo);
  }

  if (datos.categoriaId !== undefined) {
    data.categoriaId = convertirEntero(datos.categoriaId, "categoriaId");
  }

  if (datos.marcaId !== undefined) {
    data.marcaId = convertirEntero(datos.marcaId, "marcaId");
  }

  return data;
}

async function validarRelaciones({ categoriaId, marcaId }) {
  if (categoriaId !== undefined) {
    const categoria = await prisma.categoria.findUnique({ where: { id: categoriaId } });

    if (!categoria || !categoria.activo) {
      const error = new Error("La categoria indicada no existe o esta inactiva.");
      error.status = 400;
      throw error;
    }
  }

  if (marcaId !== undefined) {
    const marca = await prisma.marca.findUnique({ where: { id: marcaId } });

    if (!marca || !marca.activo) {
      const error = new Error("La marca indicada no existe o esta inactiva.");
      error.status = 400;
      throw error;
    }
  }
}

export async function obtenerProductoPorId(id) {
  const productoId = convertirEntero(id, "id");
  const producto = await prisma.producto.findUnique({
    where: { id: productoId },
    include: {
      marca: true,
      categoria: true,
      inventario: true,
    },
  });

  if (!producto) {
    const error = new Error("El producto indicado no existe.");
    error.status = 404;
    throw error;
  }

  return producto;
}

export async function crearProducto(datos) {
  validarProducto(datos);

  const productoData = mapearProductoData(datos);
  await validarRelaciones({
    categoriaId: productoData.categoriaId,
    marcaId: productoData.marcaId,
  });

  const stock = datos.stock === undefined ? 0 : convertirEntero(datos.stock, "stock");
  const stockMinimo =
    datos.stockMinimo === undefined ? 0 : convertirEntero(datos.stockMinimo, "stockMinimo");

  try {
    return await prisma.producto.create({
      data: {
        ...productoData,
        inventario: {
          create: {
            stock,
            stockMinimo,
            ubicacion: datos.ubicacion?.trim() || "Bodega principal",
          },
        },
      },
      include: {
        marca: true,
        categoria: true,
        inventario: true,
      },
    });
  } catch (error) {
    if (error.code === "P2002") {
      const conflicto = new Error("Ya existe un producto con ese codigo.");
      conflicto.status = 409;
      throw conflicto;
    }

    throw error;
  }
}

export async function actualizarProducto(id, datos) {
  const productoId = convertirEntero(id, "id");
  validarProducto(datos, true);

  const productoActual = await obtenerProductoPorId(productoId);
  const productoData = mapearProductoData(datos);
  await validarRelaciones({
    categoriaId: productoData.categoriaId,
    marcaId: productoData.marcaId,
  });

  const inventarioData = {};

  if (datos.stock !== undefined) {
    inventarioData.stock = convertirEntero(datos.stock, "stock");
  }

  if (datos.stockMinimo !== undefined) {
    inventarioData.stockMinimo = convertirEntero(datos.stockMinimo, "stockMinimo");
  }

  if (datos.ubicacion !== undefined) {
    inventarioData.ubicacion = datos.ubicacion?.trim() || null;
  }

  try {
    return await prisma.$transaction(async (tx) => {
      if (Object.keys(inventarioData).length > 0) {
        await tx.inventario.upsert({
          where: { productoId },
          update: inventarioData,
          create: {
            productoId,
            stock: inventarioData.stock ?? productoActual.inventario?.stock ?? 0,
            stockMinimo: inventarioData.stockMinimo ?? productoActual.inventario?.stockMinimo ?? 0,
            ubicacion: inventarioData.ubicacion ?? productoActual.inventario?.ubicacion ?? "Bodega principal",
          },
        });
      }

      return tx.producto.update({
        where: { id: productoId },
        data: productoData,
        include: {
          marca: true,
          categoria: true,
          inventario: true,
        },
      });
    });
  } catch (error) {
    if (error.code === "P2002") {
      const conflicto = new Error("Ya existe un producto con ese codigo.");
      conflicto.status = 409;
      throw conflicto;
    }

    throw error;
  }
}

export async function cambiarEstadoProducto(id, activo) {
  const productoId = convertirEntero(id, "id");
  const estado = convertirBooleano(activo);

  await obtenerProductoPorId(productoId);

  return prisma.producto.update({
    where: { id: productoId },
    data: { activo: estado },
    include: {
      marca: true,
      categoria: true,
      inventario: true,
    },
  });
}
