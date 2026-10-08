const express = require("express");
const router = express.Router();
const Job = require("../models/job");
const { authenticate } = require("../middleware/auth");

/**
 * @route   GET /api/jobs
 * @desc    Get all active jobs with search, category filtering & pagination
 * @access  Public
 */
router.get("/", async (req, res) => {
    try {
        const { search, category, qualification, isFeatured } = req.query;
        let query = { isLive: true };

        if (search) {
            query.$or = [
                { title: { $regex: search, $options: "i" } },
                { organization: { $regex: search, $options: "i" } },
                { department: { $regex: search, $options: "i" } },
                { qualification: { $regex: search, $options: "i" } },
            ];
        }

        if (category && category !== "All" && category !== "All Categories") {
            query.jobType = category;
        }

        if (qualification && qualification !== "All") {
            query.qualification = { $regex: qualification, $options: "i" };
        }

        if (isFeatured === "true") {
            query.isFeatured = true;
        }

        const jobs = await Job.find(query).sort({ createdAt: -1 });
        res.json({
            success: true,
            count: jobs.length,
            data: jobs,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   GET /api/jobs/:id
 * @desc    Get single job by ID
 * @access  Public
 */
router.get("/:id", async (req, res) => {
    try {
        const job = await Job.findById(req.params.id);
        if (!job) {
            return res.status(404).json({ success: false, message: "Job not found" });
        }
        res.json({ success: true, data: job });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   POST /api/jobs/:id/ai-summary
 * @desc    Generate / fetch AI summary & structured insights for a recruitment notification
 * @access  Public
 */
router.post("/:id/ai-summary", async (req, res) => {
    try {
        const job = await Job.findById(req.params.id);
        if (!job) {
            return res.status(404).json({ success: false, message: "Job not found" });
        }

        const { generateAiSummary } = require("../services/aiSummarizer");
        const summaryResult = await generateAiSummary(job, job.rawText || job.description);

        // Persist summary in DB
        job.aiSummary = summaryResult;
        await job.save();

        res.json({
            success: true,
            data: summaryResult,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   POST /api/jobs
 * @desc    Create a new Job listing (Admin)
 * @access  Private (Admin)
 */
router.post("/", authenticate, async (req, res) => {
    try {
        const newJob = new Job(req.body);
        await newJob.save();
        res.status(201).json({ success: true, data: newJob });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});

/**
 * @route   PUT /api/jobs/:id
 * @desc    Update a Job listing
 * @access  Private (Admin)
 */
router.put("/:id", authenticate, async (req, res) => {
    try {
        const updatedJob = await Job.findByIdAndUpdate(req.params.id, req.body, {
            new: true,
            runValidators: true,
        });
        if (!updatedJob) {
            return res.status(404).json({ success: false, message: "Job not found" });
        }
        res.json({ success: true, data: updatedJob });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});

/**
 * @route   DELETE /api/jobs/:id
 * @desc    Delete a Job listing
 * @access  Private (Admin)
 */
router.delete("/:id", authenticate, async (req, res) => {
    try {
        const job = await Job.findByIdAndDelete(req.params.id);
        if (!job) {
            return res.status(404).json({ success: false, message: "Job not found" });
        }
        res.json({ success: true, message: "Job deleted successfully" });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
