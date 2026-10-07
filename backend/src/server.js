const path = require("path");
require("dotenv").config({
    path: path.join(__dirname, "../.env"),
});

const express = require("express");
const cors = require("cors");
const connectDB = require("./config/database");
const { router: authRouter, seedDefaultAccounts } = require("./routes/auth");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// API Status Root
app.get("/", (req, res) => {
    res.json({
        success: true,
        message: "JobSense API is active and running",
        timestamp: new Date().toISOString(),
    });
});

// Auth Routes
app.use("/api/auth", authRouter);

// Global Error Handler
app.use((err, req, res, next) => {
    console.error("Unhandled Server Error:", err);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || "Internal server error occurred",
    });
});

// Connect to MongoDB and seed initial data
const PORT = process.env.PORT || 5000;

connectDB().then(async () => {
    await seedDefaultAccounts();
    app.listen(PORT, () => {
        console.log(`JobSense API running on http://localhost:${PORT}`);
    });
});