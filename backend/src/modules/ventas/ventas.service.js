import prisma from "../../config/prisma.js";
import { validarCarrito } from "../carrito/carrito.service.js";
import { descontarInventario } from "../pagos/pagos.service.js";

// Metodos aceptados desde el checkout del cliente. `OTRO` sigue existiendo
// a nivel de enum en Prisma (MetodoPago) para no romper datos legados,
// pero no se ofrece al cliente durante la finalizacion de la compra.
const METODOS_CHECKOUT_PERMITIDOS = ["EFECTIVO", "TARJETA", "TRANSFERENCIA"];

// Delivery snapshot helpers — the six fields captured at checkout time
// (see `model Venta` in schema.prisma). They stay `null` for orders that
// don't carry them (pre-migration rows) so downstream code can rely on
// null-safe reads.

function textoOpcional(valor, maxLen) {
  if (typeof valor !== "string") return null;
  const limpio = valor.trim();
  if (limpio.length === 0) return null;
  return limpio.slice(0, maxLen);
}

function coordenada(valor, min, max, label) {
  if (valor === undefined || valor === null || valor === "") return null;
  const numero = Number(valor);
  if (!Number.isFinite(numero) || numero < min || numero > max) {
    const error = new Error(`${label} debe ser un numero entre ${min} y ${max}.`);
    error.status = 400;
    throw error;
  }
  return numero;
}

function construirSnapshotEntrega(body) {
  if (!body) {
    return {
      direccionEntrega: null,
      ciudadEntrega: null,
      referenciaEntrega: null,
      telefonoContacto: null,
      latitudEntrega: null,
      longitudEntrega: null,
    };
  }
  return {
    direccionEntrega: textoOpcional(body.direccionEntrega, 255),
    ciudadEntrega: textoOpcional(body.ciudadEntrega, 80),
    referenciaEntrega: textoOpcional(body.referenciaEntrega, 255),
    telefonoContacto: textoOpcional(body.telefonoContacto, 30),
    latitudEntrega: coordenada(body.latitudEntrega, -90, 90, "latitudEntrega"),
    longitudEntrega: coordenada(body.longitudEntrega, -180, 180, "longitudEntrega"),
  };
}

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

function validarMetodoPago(metodoPago) {
  if (typeof metodoPago !== "string" || metodoPago.trim().length === 0) {
    const error = new Error("metodoPago es obligatorio para registrar la venta.");
    error.status = 400;
    throw error;
  }
  const metodoUpper = metodoPago.trim().toUpperCase();
  if (!METODOS_CHECKOUT_PERMITIDOS.includes(metodoUpper)) {
    const error = new Error(
      `metodoPago debe ser uno de: ${METODOS_CHECKOUT_PERMITIDOS.join(", ")}.`,
    );
    error.status = 400;
    throw error;
  }
  return metodoUpper;
}

export async function crearVenta({ clienteId, items, entrega, metodoPago, usuario }) {
  const cliente = await resolverCliente({ clienteId, usuario });
  const carrito = await validarCarrito(items);

  if (!carrito.valido) {
    const error = new Error("No se puede crear la venta porque el carrito no es valido.");
    error.status = 400;
    error.detalles = carrito.errores;
    throw error;
  }

  const metodo = validarMetodoPago(metodoPago);
  // TARJETA es un pago SIMULADO — al confirmar el checkout la venta se
  // aprueba automaticamente (sin pasarela real). El resto de metodos
  // dejan la venta pendiente hasta que Admin/Vendedor confirmen en el
  // panel.
  const esTarjetaSimulada = metodo === "TARJETA";
  const estadoInicialVenta = esTarjetaSimulada ? "PAGADA" : "PENDIENTE";
  const estadoInicialPago = esTarjetaSimulada ? "PAGADO" : "PENDIENTE";

  // Delivery snapshot — captured verbatim from the checkout payload and
  // stored on the Venta row so it never depends on Cliente.direccion for
  // historical accuracy. Every field is nullable in the DB, so if the
  // frontend omits them (legacy client, admin creating a manual sale)
  // the row is still valid.
  const snapshotEntrega = construirSnapshotEntrega(entrega);

  const resultado = await prisma.$transaction(async (tx) => {
    // Include with `inventario` so we can call descontarInventario if
    // the payment is auto-approved (tarjeta simulada).
    const includeCompleto = {
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
              inventario: true,
              marca: true,
              categoria: true,
            },
          },
        },
      },
      pagos: true,
      factura: true,
    };

    const venta = await tx.venta.create({
      data: {
        clienteId: cliente.id,
        usuarioId: usuario.id,
        estado: estadoInicialVenta,
        subtotal: carrito.subtotal,
        impuesto: carrito.impuesto,
        total: carrito.total,
        ...snapshotEntrega,
        detalles: {
          create: carrito.items.map((item) => ({
            productoId: item.productoId,
            cantidad: item.cantidad,
            precioUnitario: item.precioUnitario,
            total: item.total,
          })),
        },
        // Persistimos el metodo elegido por el cliente como Pago inicial
        // dentro de la misma transaccion. Asi el panel admin ya no
        // necesita re-preguntar el metodo y las ventas historicas sin
        // Pago siguen siendo distinguibles (no las tocamos).
        pagos: {
          create: [
            {
              metodo,
              estado: estadoInicialPago,
              monto: carrito.total,
              fechaPago: esTarjetaSimulada ? new Date() : null,
            },
          ],
        },
      },
      include: includeCompleto,
    });

    let alertasStock = [];
    let ventaFinal = venta;

    if (esTarjetaSimulada) {
      alertasStock = await descontarInventario(tx, venta, usuario.id);
      // Re-fetch para reflejar el inventario ya descontado en la
      // respuesta (el descontar afecta a producto.inventario.stock).
      ventaFinal = await tx.venta.findUnique({
        where: { id: venta.id },
        include: includeCompleto,
      });
    }

    return { venta: ventaFinal, alertasStock };
  });

  const mensaje = esTarjetaSimulada
    ? "Pago con tarjeta simulado aprobado automaticamente. Venta PAGADA e inventario descontado."
    : metodo === "TRANSFERENCIA"
    ? "Venta creada en estado PENDIENTE. Un administrador confirmara la transferencia."
    : "Venta creada en estado PENDIENTE. El cobro en efectivo se registrara al entregar.";

  return {
    venta: resultado.venta,
    alertasStock: resultado.alertasStock,
    mensaje,
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

// Returns only the sales that belong to the authenticated customer.
// Used by GET /ventas/mis so a Cliente can render their own order history
// without having permission to list every sale in the system.
export async function obtenerVentasDelCliente(usuario) {
  const cliente = await prisma.cliente.findUnique({
    where: { usuarioId: usuario.id },
  });

  if (!cliente) {
    return [];
  }

  return prisma.venta.findMany({
    where: { clienteId: cliente.id },
    orderBy: { id: "desc" },
    include: {
      cliente: true,
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
