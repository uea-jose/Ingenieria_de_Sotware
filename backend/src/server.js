import "dotenv/config";

import app from "./app.js";
import prisma from "./config/prisma.js";

const port = process.env.PORT || 3000;

async function startServer() {
  await prisma.$connect();

  app.listen(port, () => {
    console.log(`Aromas Store API running on http://localhost:${port}`);
  });
}

startServer().catch(async (error) => {
  console.error("Failed to start Aromas Store API", error);
  await prisma.$disconnect();
  process.exit(1);
});

