const path = require("path");
require("dotenv").config({
    path: path.join(__dirname, "../.env"),
});

const express = require("express");
const cors = require("cors");
const connectDB = require("./config/database");
const { router: authRouter, seedDefaultAccounts } = require("./routes/auth");
const jobsRouter = require("./routes/jobs");
const scrapersRouter = require("./routes/scrapers");
const scrapedJobsRouter = require("./routes/scrapedJobs");
const usersRouter = require("./routes/users");
const notificationsRouter = require("./routes/notifications");
const logsRouter = require("./routes/logs");
const statsRouter = require("./routes/stats");
const { seedInitialScraperData } = require("./services/scraperEngine");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// API Status Root
app.get("/", (req, res) => {
    res.json({
        success: true,
        message: "JobSense API is active and running",
        version: "2.0.0",
        timestamp: new Date().toISOString(),
    });
});

// Register API Routes
app.use("/api/auth", authRouter);
app.use("/api/jobs", jobsRouter);
app.use("/api/scrapers", scrapersRouter);
app.use("/api/scraped-jobs", scrapedJobsRouter);
app.use("/api/users", usersRouter);
app.use("/api/notifications", notificationsRouter);
app.use("/api/logs", logsRouter);
app.use("/api/stats", statsRouter);

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
    await seedInitialScraperData();
    app.listen(PORT, "0.0.0.0", () => {
        console.log(`🚀 JobSense Real API & Scraper Engine running on http://0.0.0.0:${PORT} (Accessible by localhost and Android Emulator 10.0.2.2)`);
    });
});