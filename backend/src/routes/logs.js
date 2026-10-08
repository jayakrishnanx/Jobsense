const express = require("express");
const router = express.Router();
const SystemLog = require("../models/systemLog");

/**
 * @route   GET /api/logs
 * @desc    Get system audit logs
 * @access  Public / Admin
 */
router.get("/", async (req, res) => {
    try {
        const { category, level } = req.query;
        const query = {};
        if (category && category !== "ALL") query.category = category;
        if (level && level !== "ALL") query.level = level;

        const logs = await SystemLog.find(query).sort({ timestamp: -1 }).limit(100);
        res.json({
            success: true,
            count: logs.length,
            data: logs,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   POST /api/logs
 * @desc    Insert a system audit log
 * @access  Public / Admin
 */
router.post("/", async (req, res) => {
    try {
        const log = new SystemLog(req.body);
        await log.save();
        res.status(201).json({ success: true, data: log });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});

/**
 * @route   DELETE /api/logs
 * @desc    Clear audit logs (Admin)
 * @access  Admin
 */
router.delete("/", async (req, res) => {
    try {
        await SystemLog.deleteMany({});
        res.json({ success: true, message: "System logs cleared" });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
