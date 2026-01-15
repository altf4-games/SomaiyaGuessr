const app = require("../app");
const { connectDB } = require("../db/connection");

require("dotenv").config();

// Connect to MongoDB
connectDB();

// For local development
if (process.env.NODE_ENV !== "production") {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Test your endpoints at http://localhost:${PORT}`);
  });
}

// Export for Vercel serverless
module.exports = app;
