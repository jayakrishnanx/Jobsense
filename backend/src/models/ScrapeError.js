const mongoose = require("mongoose");

const scrapeErrorSchema = new mongoose.Schema(
    {
        scraperCode: {
            type: String,
            required: true,
            index: true,
        },
        scrapeRunId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "ScrapeRun",
            default: null,
        },
        phase: {
            type: String,
            enum: [
                "DISCOVERY",
                "PAGE_FETCH",
                "PDF_DOWNLOAD",
                "PDF_EXTRACTION",
                "OCR",
                "ANALYSIS",
                "ELIGIBILITY",
                "DATABASE",
            ],
            required: true,
            index: true,
        },
        url: {
            type: String,
            default: "",
        },
        notificationTitle: {
            type: String,
            default: "",
        },
        categoryNumber: {
            type: String,
            default: "",
        },
        errorMessage: {
            type: String,
            required: true,
        },
        stack: {
            type: String,
            default: null,
        },
        retried: {
            type: Boolean,
            default: false,
        },
        resolved: {
            type: Boolean,
            default: false,
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

module.exports = mongoose.model("ScrapeError", scrapeErrorSchema);
