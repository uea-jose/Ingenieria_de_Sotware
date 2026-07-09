import { getBrands } from "./brands.service.js";

export async function listBrands(req, res, next) {
  try {
    const brands = await getBrands();

    res.json({
      data: brands,
      total: brands.length,
    });
  } catch (error) {
    next(error);
  }
}

