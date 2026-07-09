import prisma from "../../config/prisma.js";

const IVA = 0.15;
const UMBRAL_ALERTA_STOCK = 3;

function redondearMoneda(valor) {
  return Math.round((valor + Number.EPSILON) * 100) / 100;
}

function validarItems(items) {
  if (!Array.isArray(items) || items.length === 0) {
    const error = new Error("El carrito debe incluir al menos un producto.");
    error.status = 400;
    throw error;
  }

  for (const item of items) {
    if (!Number.isInteger(item.productoId) || item.productoId <= 0) {
      const error = new Error("Cada item debe tener un productoId valido.");
      error.status = 400;
      throw error;
    }

    if (!Number.isInteger(item.cantidad) || item.cantidad <= 0) {
      const error = new Error("Cada item debe tener una cantidad mayor a cero.");
      error.status = 400;
      throw error;
    }
  }
}

function agruparItems(items) {
  const agrupados = new Map();

  for (const item of items) {
    const cantidadActual = agrupados.get(item.productoId) || 0;
    agrupados.set(item.productoId, cantidadActual + item.cantidad);
  }

  return Array.from(agrupados, ([productoId, cantidad]) => ({
    productoId,
    cantidad,
  }));
}

export async function validarCarrito(items) {
  validarItems(items);

  const itemsAgrupados = agruparItems(items);
  const idsProductos = itemsAgrupados.map((item) => item.productoId);

  const productos = await prisma.producto.findMany({
    where: {
      id: { in: idsProductos },
    },
    include: {
      marca: true,
      categoria: true,
      inventario: true,
    },
  });

  const productosPorId = new Map(
    productos.map((producto) => [producto.id, producto]),
  );
  const errores = [];
  const alertasStock = [];
  const itemsCalculados = [];

  for (const item of itemsAgrupados) {
    const producto = productosPorId.get(item.productoId);

    if (!producto) {
      errores.push(`El producto con id ${item.productoId} no existe.`);
      continue;
    }

    if (!producto.activo) {
      errores.push(`${producto.nombre} no esta activo para la venta.`);
      continue;
    }

    const stockDisponible = producto.inventario?.stock ?? 0;
    const stockBajo = stockDisponible < UMBRAL_ALERTA_STOCK;
    const precioUnitario = Number(producto.precio);
    const totalItem = redondearMoneda(precioUnitario * item.cantidad);

    if (item.cantidad > stockDisponible) {
      errores.push(
        `${producto.nombre} solo tiene ${stockDisponible} unidades disponibles.`,
      );
    }

    if (stockBajo) {
      alertasStock.push({
        productoId: producto.id,
        nombre: producto.nombre,
        stockDisponible,
        mensaje: `${producto.nombre} tiene stock bajo (${stockDisponible} unidades).`,
      });
    }

    itemsCalculados.push({
      productoId: producto.id,
      nombre: producto.nombre,
      marca: producto.marca.nombre,
      categoria: producto.categoria.nombre,
      cantidad: item.cantidad,
      precioUnitario,
      stockDisponible,
      stockBajo,
      total: totalItem,
    });
  }

  const subtotal = redondearMoneda(
    itemsCalculados.reduce((acumulado, item) => acumulado + item.total, 0),
  );
  const impuesto = redondearMoneda(subtotal * IVA);
  const total = redondearMoneda(subtotal + impuesto);

  return {
    valido: errores.length === 0,
    subtotal,
    impuesto,
    total,
    porcentajeImpuesto: IVA,
    alertasStock,
    errores,
    items: itemsCalculados,
  };
}
