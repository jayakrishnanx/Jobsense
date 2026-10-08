const express = require("express");
const router = express.Router();
const ScrapedJob = require("../models/scrapedJob");
const Job = require("../models/job");
const SystemLog = require("../models/systemLog");

/**
 * @route   GET /api/scraped-jobs
 * @desc    Get all scraped jobs (filtered by review status: pending, approved, rejected)
 * @access  Public / Admin
 */
router.get("/", async (req, res) => {
    try {
        const { status } = req.query;
        const query = status ? { reviewStatus: status } : {};
        const scrapedJobs = await ScrapedJob.find(query).sort({ scrapedAt: -1 });

        res.json({
            success: true,
            count: scrapedJobs.length,
            data: scrapedJobs,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   POST /api/scraped-jobs/:id/approve
 * @desc    Approve a scraped job and publish it directly to the live Job collection
 * @access  Admin
 */
router.post("/:id/approve", async (req, res) => {
    try {
        const scrapedJob = await ScrapedJob.findById(req.params.id);
        if (!scrapedJob) {
            return res.status(404).json({ success: false, message: "Scraped job not found" });
        }

        // Create published live job
        const publishedJob = new Job({
            title: req.body.title || scrapedJob.title,
            organization: req.body.organization || scrapedJob.organization,
            department: req.body.department || "General Administration",
            jobType: req.body.categoryTag || scrapedJob.categoryTag || "Central Govt",
            location: req.body.location || "All India",
            vacancies: req.body.vacancies || scrapedJob.vacancies || "As per notice",
            qualification: req.body.qualification || scrapedJob.qualification || "Any Degree",
            lastDate: req.body.lastDate || scrapedJob.lastDate || "See Notification",
            officialNotificationUrl: scrapedJob.officialUrl || "",
            source: scrapedJob.source,
            isLive: true,
        });

        await publishedJob.save();

        // Update scraped job status
        scrapedJob.reviewStatus = "approved";
        scrapedJob.publishedJobId = publishedJob._id;
        await scrapedJob.save();

        await SystemLog.create({
            level: "SUCCESS",
            category: "JOBS",
            message: `Scraped job approved and published: ${publishedJob.title}`,
            details: `Job ID: ${publishedJob._id}`,
        });

        res.json({
            success: true,
            message: "Job approved and published to candidate feeds",
            data: {
                scrapedJob,
                publishedJob,
            },
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   POST /api/scraped-jobs/:id/reject
 * @desc    Reject a scraped job
 * @access  Admin
 */
router.post("/:id/reject", async (req, res) => {
    try {
        const scrapedJob = await ScrapedJob.findByIdAndUpdate(
            req.params.id,
            { reviewStatus: "rejected" },
            { new: true }
        );
        if (!scrapedJob) {
            return res.status(404).json({ success: false, message: "Scraped job not found" });
        }
        res.json({ success: true, message: "Job rejected", data: scrapedJob });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   DELETE /api/scraped-jobs/:id
 * @desc    Delete scraped job
 * @access  Admin
 */
router.delete("/:id", async (req, res) => {
    try {
        const scrapedJob = await ScrapedJob.findByIdAndDelete(req.params.id);
        if (!scrapedJob) {
            return res.status(404).json({ success: false, message: "Scraped job not found" });
        }
        res.json({ success: true, message: "Scraped job deleted" });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
