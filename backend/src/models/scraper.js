const mongoose = require("mongoose");

const scraperSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            trim: true,
        },
        code: {
            type: String,
            required: true,
            unique: true,
        },
        targetUrl: {
            type: String,
            required: true,
        },
        category: {
            type: String,
            default: "Government",
        },
        schedule: {
            type: String,
            default: "Every 4 hours",
        },
        frequencyMinutes: {
            type: Number,
            default: 240,
        },
        lastRunTime: {
            type: Date,
            default: Date.now,
        },
        nextRunTime: {
            type: Date,
            default: () => new Date(Date.now() + 4 * 60 * 60 * 1000),
        },
        jobsFound: {
            type: Number,
            default: 0,
        },
        status: {
            type: String,
            enum: ["active", "idle", "running", "failed", "paused"],
            default: "active",
        },
        errorMessage: {
            type: String,
            default: null,
        },
        scraperType: {
            type: String,
            enum: ["live_web", "rss", "api", "aggregator"],
            default: "live_web",
        },
    },
    {
        timestamps: true,
        toJSON: {
            transform: function (doc, ret) {
                ret.id = ret._id.toString();
                delete ret._id;
                delete ret.__v;
                return ret;
            },
        },
    }
);

module.exports = mongoose.model("Scraper", scraperSchema);
