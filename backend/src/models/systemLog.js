const mongoose = require("mongoose");

const systemLogSchema = new mongoose.Schema(
    {
        level: {
            type: String,
            enum: ["INFO", "WARN", "ERROR", "SUCCESS"],
            default: "INFO",
        },
        category: {
            type: String,
            enum: ["SCRAPER", "AUTH", "SYSTEM", "JOBS", "USER"],
            default: "SYSTEM",
        },
        message: {
            type: String,
            required: true,
        },
        details: {
            type: String,
            default: "",
        },
        timestamp: {
            type: Date,
            default: Date.now,
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

module.exports = mongoose.model("SystemLog", systemLogSchema);
