const express = require("express");
const router = express.Router();
const Notification = require("../models/notification");

/**
 * @route   GET /api/notifications
 * @desc    Get all notifications
 * @access  Public
 */
router.get("/", async (req, res) => {
    try {
        const notifications = await Notification.find().sort({ createdAt: -1 }).limit(50);
        res.json({
            success: true,
            count: notifications.length,
            data: notifications,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   PUT /api/notifications/:id/read
 * @desc    Mark notification as read
 * @access  Public
 */
router.put("/:id/read", async (req, res) => {
    try {
        const notif = await Notification.findByIdAndUpdate(req.params.id, { isRead: true }, { new: true });
        if (!notif) return res.status(404).json({ success: false, message: "Notification not found" });
        res.json({ success: true, data: notif });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   POST /api/notifications/mark-all-read
 * @desc    Mark all notifications as read
 * @access  Public
 */
router.post("/mark-all-read", async (req, res) => {
    try {
        await Notification.updateMany({}, { isRead: true });
        res.json({ success: true, message: "All notifications marked as read" });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
