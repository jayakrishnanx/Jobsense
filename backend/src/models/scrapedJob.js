const mongoose = require("mongoose");

const scrapedJobSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: true,
            trim: true,
        },
        organization: {
            type: String,
            required: true,
            trim: true,
        },
        source: {
            type: String,
            required: true,
        },
        officialUrl: {
            type: String,
            default: "",
        },
        vacancies: {
            type: String,
            default: "Not Specified",
        },
        qualification: {
            type: String,
            default: "Any Degree / 10th / 12th",
        },
        lastDate: {
            type: String,
            default: "Check Notification",
        },
        rawText: {
            type: String,
            default: "",
        },
        confidenceScore: {
            type: Number,
            default: 0.85,
        },
        reviewStatus: {
            type: String,
            enum: ["pending", "approved", "rejected"],
            default: "pending",
        },
        scrapedAt: {
            type: Date,
            default: Date.now,
        },
        categoryTag: {
            type: String,
            default: "Central Govt",
        },
        publishedJobId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Job",
            default: null,
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

module.exports = mongoose.model("ScrapedJob", scrapedJobSchema);
