import cors from "cors";
import express from "express";
import { swaggerSpec, swaggerUi, swaggerUiOptions } from "./config/swagger.js";
import routes from "./routes/index.js";

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec, swaggerUiOptions));
app.get("/api/docs.json", (req, res) => {
  res.json(swaggerSpec);
});

app.use("/api", routes);

app.use((req, res) => {
  res.status(404).json({
    error: "Route not found",
    path: req.originalUrl,
  });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({
    error: err.status ? err.message : "Internal server error",
    detalles: err.detalles,
  });
});

export default app;
