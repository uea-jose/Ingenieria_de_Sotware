import { obtenerCategorias } from "../categorias/categorias.service.js";

export async function getCategories() {
  return obtenerCategorias();
}
