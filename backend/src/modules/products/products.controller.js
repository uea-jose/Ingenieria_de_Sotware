import { getProducts } from "./products.service.js";

export async function listProducts(req, res, next) {
  try {
    const { productos, filtrosAplicados } = await getProducts(req.query);

    res.json({
      data: productos,
      total: productos.length,
      filters: filtrosAplicados,
    });
  } catch (error) {
    next(error);
  }
}
