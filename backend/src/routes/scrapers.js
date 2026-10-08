const express = require("express");
const router = express.Router();
const Scraper = require("../models/scraper");
const {
    runScraperByCode,
    runScraperById,
    getAvailableScraperAdapters,
    getScrapeRuns,
    getScrapeErrors,
} = require("../services/scraperOrchestrator");

/**
 * @route   GET /api/scrapers
 * @desc    Get all configured scrapers
 * @access  Public / Admin
 */
router.get("/", async (req, res) => {
    try {
        const scrapers = await Scraper.find().sort({ createdAt: -1 });
        res.json({
            success: true,
            count: scrapers.length,
            data: scrapers,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   GET /api/scrapers/adapters
 * @desc    Get all available modular scraper plugins
 */
router.get("/adapters", (req, res) => {
    const adapters = getAvailableScraperAdapters();
    res.json({
        success: true,
        count: adapters.length,
        data: adapters,
    });
});

/**
 * @route   GET /api/scrapers/runs
 * @desc    Get recent scrape execution logs
 */
router.get("/runs", async (req, res) => {
    try {
        const runs = await getScrapeRuns(parseInt(req.query.limit, 10) || 25);
        res.json({ success: true, count: runs.length, data: runs });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   GET /api/scrapers/errors
 * @desc    Get logged scraping errors for inspection & retry
 */
router.get("/errors", async (req, res) => {
    try {
        const errors = await getScrapeErrors(parseInt(req.query.limit, 10) || 50);
        res.json({ success: true, count: errors.length, data: errors });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   POST /api/scrapers/kerala-psc/run
 * @desc    Dedicated endpoint to trigger Kerala PSC scraper pipeline
 */
router.post("/kerala-psc/run", async (req, res) => {
    try {
        const options = {
            maxItems: parseInt(req.query.maxItems, 10) || 15,
        };
        const result = await runScraperByCode("kerala_psc", options);
        res.json({
            success: result.status === "completed",
            data: result,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   POST /api/scrapers/:idOrCode/run
 * @desc    Trigger any scraper by database ID or registered adapter code
 */
router.post("/:idOrCode/run", async (req, res) => {
    try {
        const param = req.params.idOrCode;
        let result;

        // Check if param is valid MongoDB ObjectId
        if (param.match(/^[0-9a-fA-F]{24}$/)) {
            result = await runScraperById(param, req.body);
        } else {
            result = await runScraperByCode(param, req.body);
        }

        res.json({
            success: result.status === "completed",
            data: result,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   POST /api/scrapers
 * @desc    Add a new web scraper configuration
 */
router.post("/", async (req, res) => {
    try {
        const data = { ...req.body };
        if (!data.code) {
            data.code =
                "SCR_" +
                (data.name ? data.name.replace(/[^a-zA-Z0-9]/g, "_").toUpperCase().slice(0, 15) : "SITE") +
                "_" +
                Date.now().toString().slice(-4);
        }
        if (data.targetUrl && !data.targetUrl.startsWith("http://") && !data.targetUrl.startsWith("https://")) {
            data.targetUrl = "https://" + data.targetUrl;
        }
        const scraper = new Scraper(data);
        await scraper.save();
        res.status(201).json({ success: true, data: scraper });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});

/**
 * @route   PUT /api/scrapers/:id
 * @desc    Update scraper config
 */
router.put("/:id", async (req, res) => {
    try {
        const scraper = await Scraper.findByIdAndUpdate(req.params.id, req.body, {
            new: true,
        });
        if (!scraper) {
            return res.status(404).json({ success: false, message: "Scraper not found" });
        }
        res.json({ success: true, data: scraper });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});

/**
 * @route   DELETE /api/scrapers/:id
 * @desc    Delete a scraper configuration
 */
router.delete("/:id", async (req, res) => {
    try {
        const scraper = await Scraper.findByIdAndDelete(req.params.id);
        if (!scraper) {
            return res.status(404).json({ success: false, message: "Scraper not found" });
        }
        res.json({ success: true, message: "Scraper deleted" });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
