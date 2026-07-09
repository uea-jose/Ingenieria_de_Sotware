import { getCategories } from "./categories.service.js";

export async function listCategories(req, res, next) {
  try {
    const categories = await getCategories();

    res.json({
      data: categories,
      total: categories.length,
    });
  } catch (error) {
    next(error);
  }
}

