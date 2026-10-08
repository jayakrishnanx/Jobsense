/**
 * Job Service for JobSense
 * Handles validation, unique fingerprint generation, MongoDB upsert, deduplication,
 * and error recording.
 */

const crypto = require("crypto");
const Job = require("../models/job");
const ScrapeError = require("../models/ScrapeError");
const { logger } = require("../utils/logger");

/**
 * Generates a consistent deduplication fingerprint
 */
function generateJobFingerprint(normalizedData) {
    const src = normalizedData.source?.name || "SOURCE";
    const cat = normalizedData.job?.categoryNumber || "";
    const title = (normalizedData.job?.title || "").toLowerCase().replace(/\s+/g, "_");
    const pdfUrl = normalizedData.source?.pdfUrl || "";

    const rawString = `${src}|${cat}|${title}|${pdfUrl}`;
    return crypto.createHash("sha256").update(rawString).digest("hex");
}

/**
 * Validates normalized job payload against minimum data standards
 */
function validateJobData(jobData) {
    const errors = [];

    if (!jobData.job?.title || jobData.job.title.trim().length < 2) {
        errors.push("Missing or invalid job title");
    }
    if (!jobData.job?.organization) {
        errors.push("Missing job organization");
    }
    if (!jobData.job?.applicationLastDate) {
        errors.push("Missing application deadline / last date");
    }

    return {
        isValid: errors.length === 0,
        errors,
    };
}

/**
 * Persists or updates normalized job in MongoDB
 * @param {object} normalizedData
 * @param {object} [context]
 * @returns {Promise<{ status: 'CREATED'|'UPDATED'|'REJECTED', job: object }>}
 */
async function saveOrUpdateJob(normalizedData, context = {}) {
    const validation = validateJobData(normalizedData);
    if (!validation.isValid) {
        logger.warn("DATABASE", `Job data validation failed: ${validation.errors.join(", ")}`, normalizedData.job);
        if (context.scrapeRunId) {
            await ScrapeError.create({
                scraperCode: context.scraperCode || "GENERIC",
                scrapeRunId: context.scrapeRunId,
                phase: "DATABASE",
                url: normalizedData.source?.pdfUrl || normalizedData.source?.notificationUrl || "",
                notificationTitle: normalizedData.job?.title || "Unknown",
                categoryNumber: normalizedData.job?.categoryNumber || "",
                errorMessage: `Validation failed: ${validation.errors.join(", ")}`,
            });
        }
        return { status: "REJECTED", errors: validation.errors };
    }

    const fingerprint = generateJobFingerprint(normalizedData);
    normalizedData.fingerprint = fingerprint;

    try {
        // Query to detect duplicate: By fingerprint OR (source.name + categoryNumber if categoryNumber exists)
        const queryConditions = [{ fingerprint }];
        if (normalizedData.job?.categoryNumber && normalizedData.source?.name) {
            queryConditions.push({
                "source.name": normalizedData.source.name,
                "job.categoryNumber": normalizedData.job.categoryNumber,
            });
        }

        const existingJob = await Job.findOne({ $or: queryConditions });

        if (existingJob) {
            // Update existing job document
            normalizedData.metadata.updatedAt = new Date();
            normalizedData.metadata.lastScrapedAt = new Date();
            normalizedData.metadata.scrapedAt = existingJob.metadata?.scrapedAt || existingJob.createdAt;

            Object.assign(existingJob, normalizedData);
            await existingJob.save();

            logger.database(`Updated existing job: "${existingJob.job?.title}" (ID: ${existingJob._id})`);
            return { status: "UPDATED", job: existingJob };
        } else {
            // Create brand new job document
            normalizedData.metadata.scrapedAt = new Date();
            normalizedData.metadata.updatedAt = new Date();
            normalizedData.metadata.lastScrapedAt = new Date();

            const newJob = new Job(normalizedData);
            await newJob.save();

            logger.database(`Created new job listing: "${newJob.job?.title}" (ID: ${newJob._id})`);
            return { status: "CREATED", job: newJob };
        }
    } catch (err) {
        logger.error("DATABASE", `Failed to save job "${normalizedData.job?.title}" to MongoDB`, err);
        if (context.scrapeRunId) {
            await ScrapeError.create({
                scraperCode: context.scraperCode || "GENERIC",
                scrapeRunId: context.scrapeRunId,
                phase: "DATABASE",
                url: normalizedData.source?.pdfUrl || normalizedData.source?.notificationUrl || "",
                notificationTitle: normalizedData.job?.title || "Unknown",
                categoryNumber: normalizedData.job?.categoryNumber || "",
                errorMessage: err.message,
                stack: err.stack,
            });
        }
        throw err;
    }
}

module.exports = {
    generateJobFingerprint,
    validateJobData,
    saveOrUpdateJob,
};
