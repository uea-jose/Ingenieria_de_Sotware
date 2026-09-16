import { reverseGeocode } from "./ubicacion.service.js";

export async function reverse(req, res, next) {
  try {
    const dto = await reverseGeocode({
      lat: req.query.lat,
      lon: req.query.lon,
    });
    res.json({ dato: dto });
  } catch (error) {
    next(error);
  }
}
