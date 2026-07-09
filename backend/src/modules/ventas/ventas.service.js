import prisma from "../../config/prisma.js";
import { validarCarrito } from "../carrito/carrito.service.js";

async function resolverCliente({ clienteId, usuario }) {
  if (usuario.rol === "Cliente") {
    const cliente = await prisma.cliente.findUnique({
      where: { usuarioId: usuario.id },
    });

    if (!cliente) {
      const error = new Error("El usuario autenticado no tiene perfil de cliente.");
      error.status = 400;
      throw error;
    }

    return cliente;
  }

  if (!Number.isInteger(clienteId) || clienteId <= 0) {
    const error = new Error("clienteId es obligatorio para registrar la venta.");
    error.status = 400;
    throw error;
  }

  const cliente = await prisma.cliente.findUnique({
    where: { id: clienteId },
  });

  if (!cliente) {
    const error = new Error("El cliente indicado no existe.");
    error.status = 404;
    throw error;
  }

  return cliente;
}

export async function crearVenta({ clienteId, items, usuario }) {
  const cliente = await resolverCliente({ clienteId, usuario });
  const carrito = await validarCarrito(items);

  if (!carrito.valido) {
    const error = new Error("No se puede crear la venta porque el carrito no es valido.");
    error.status = 400;
    error.detalles = carrito.errores;
    throw error;
  }

  const venta = await prisma.$transaction(async (tx) => {
    return tx.venta.create({
      data: {
        clienteId: cliente.id,
        usuarioId: usuario.id,
        estado: "PENDIENTE",
        subtotal: carrito.subtotal,
        impuesto: carrito.impuesto,
        total: carrito.total,
        detalles: {
          create: carrito.items.map((item) => ({
            productoId: item.productoId,
            cantidad: item.cantidad,
            precioUnitario: item.precioUnitario,
            total: item.total,
          })),
        },
      },
      include: {
        cliente: true,
        usuario: {
          select: {
            id: true,
            nombres: true,
            apellidos: true,
            correo: true,
            rol: true,
          },
        },
        detalles: {
          include: {
            producto: {
              include: {
                marca: true,
                categoria: true,
              },
            },
          },
        },
      },
    });
  });

  return {
    venta,
    alertasStock: carrito.alertasStock,
    mensaje: "Venta creada en estado PENDIENTE. El inventario se descontara cuando el pago sea aprobado.",
  };
}

export async function obtenerVentas() {
  return prisma.venta.findMany({
    orderBy: { id: "desc" },
    include: {
      cliente: true,
      usuario: {
        select: {
          id: true,
          nombres: true,
          apellidos: true,
          correo: true,
          rol: true,
        },
      },
      detalles: {
        include: {
          producto: {
            include: {
              marca: true,
              categoria: true,
            },
          },
        },
      },
      pagos: true,
      factura: true,
    },
  });
}
