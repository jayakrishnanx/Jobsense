const mongoose = require("mongoose");

const scrapeRunSchema = new mongoose.Schema(
    {
        scraperCode: {
            type: String,
            required: true,
            index: true,
        },
        scraperName: {
            type: String,
            required: true,
        },
        targetUrl: {
            type: String,
            required: true,
        },
        status: {
            type: String,
            enum: ["running", "completed", "failed"],
            default: "running",
            index: true,
        },
        startedAt: {
            type: Date,
            default: Date.now,
        },
        finishedAt: {
            type: Date,
            default: null,
        },
        totalFound: {
            type: Number,
            default: 0,
        },
        activeFound: {
            type: Number,
            default: 0,
        },
        processedCount: {
            type: Number,
            default: 0,
        },
        newSavedCount: {
            type: Number,
            default: 0,
        },
        updatedCount: {
            type: Number,
            default: 0,
        },
        failedCount: {
            type: Number,
            default: 0,
        },
        durationMs: {
            type: Number,
            default: 0,
        },
        errorMessage: {
            type: String,
            default: null,
        },
        summary: {
            type: mongoose.Schema.Types.Mixed,
            default: {},
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

module.exports = mongoose.model("ScrapeRun", scrapeRunSchema);
