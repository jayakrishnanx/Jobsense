const express = require("express");
const router = express.Router();
const User = require("../models/user");
const Job = require("../models/job");
const { authenticate } = require("../middleware/auth");

/**
 * @route   GET /api/users
 * @desc    Get all users (for Admin User Management)
 * @access  Public / Admin
 */
router.get("/", async (req, res) => {
    try {
        const users = await User.find().select("-password").sort({ createdAt: -1 });
        res.json({
            success: true,
            count: users.length,
            data: users,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   GET /api/users/:id
 * @desc    Get single user details
 * @access  Public
 */
router.get("/:id", async (req, res) => {
    try {
        const user = await User.findById(req.params.id).select("-password");
        if (!user) {
            return res.status(404).json({ success: false, message: "User not found" });
        }
        res.json({ success: true, data: user });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

/**
 * @route   PUT /api/users/:id
 * @desc    Update candidate profile details
 * @access  Public
 */
router.put("/:id", async (req, res) => {
    try {
        const allowedUpdates = [
            "name",
            "email",
            "dob",
            "gender",
            "qualification",
            "course",
            "yearOfPassing",
            "category",
            "state",
            "district",
            "isActive",
        ];

        const updates = {};
        for (const key of allowedUpdates) {
            if (req.body[key] !== undefined) {
                updates[key] = req.body[key];
            }
        }

        const updatedUser = await User.findByIdAndUpdate(req.params.id, updates, {
            new: true,
            runValidators: true,
        }).select("-password");

        if (!updatedUser) {
            return res.status(404).json({ success: false, message: "User not found" });
        }

        res.json({
            success: true,
            message: "User profile updated successfully",
            data: updatedUser,
        });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});

/**
 * @route   POST /api/users/:id/toggle-status
 * @desc    Toggle user active/inactive status (Admin)
 * @access  Admin
 */
router.post("/:id/toggle-status", async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ success: false, message: "User not found" });
        }

        user.isActive = !user.isActive;
        await user.save();

        res.json({
            success: true,
            message: `User is now ${user.isActive ? "Active" : "Suspended"}`,
            data: user,
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
