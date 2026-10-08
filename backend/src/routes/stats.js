const express = require("express");
const router = express.Router();
const Job = require("../models/job");
const User = require("../models/user");
const Scraper = require("../models/scraper");
const ScrapedJob = require("../models/scrapedJob");
const SystemLog = require("../models/systemLog");

/**
 * @route   GET /api/stats
 * @desc    Get live metrics for Admin Dashboard
 * @access  Public / Admin
 */
router.get("/", async (req, res) => {
    try {
        const [
            totalJobs,
            totalUsers,
            activeUsers,
            totalScrapers,
            activeScrapers,
            pendingScrapedJobs,
            approvedScrapedJobs,
            totalLogs,
        ] = await Promise.all([
            Job.countDocuments({ isLive: true }),
            User.countDocuments(),
            User.countDocuments({ isActive: true }),
            Scraper.countDocuments(),
            Scraper.countDocuments({ status: "active" }),
            ScrapedJob.countDocuments({ reviewStatus: "pending" }),
            ScrapedJob.countDocuments({ reviewStatus: "approved" }),
            SystemLog.countDocuments(),
        ]);

        res.json({
            success: true,
            data: {
                totalJobs,
                totalUsers,
                activeUsers,
                totalScrapers,
                activeScrapers,
                pendingScrapedJobs,
                approvedScrapedJobs,
                totalLogs,
                systemHealth: "Optimal",
                databaseStatus: "Connected",
            },
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
