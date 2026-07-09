import { obtenerMarcas } from "../marcas/marcas.service.js";

export async function getBrands() {
  return obtenerMarcas();
}
