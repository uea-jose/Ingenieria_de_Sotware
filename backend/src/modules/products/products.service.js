import { obtenerProductos } from "../productos/productos.service.js";

export async function getProducts(query = {}) {
  return obtenerProductos(query);
}
