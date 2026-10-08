/**
 * Scraper Orchestrator for JobSense
 * Coordinates scraper invocation, registry lookup, and status updates
 */

const registry = require("../scrapers/base/ScraperRegistry");
const Scraper = require("../models/scraper");
const ScrapeRun = require("../models/ScrapeRun");
const ScrapeError = require("../models/ScrapeError");
const { logger } = require("../utils/logger");

// Ensure default scrapers are loaded into registry
require("../scrapers/keralaPSC/KeralaPSCScraper");
require("../scrapers/ssc/SSCScraper");

/**
 * Executes a scraper by its registered code or alias (e.g. 'kerala_psc', 'kerala-psc')
 * @param {string} code
 * @param {object} [options]
 * @returns {Promise<object>}
 */
async function runScraperByCode(code, options = {}) {
    logger.orchestrator(`Triggering scraper run for code: "${code}"`);

    const scraperInstance = registry.create(code, options.config || {});
    const result = await scraperInstance.scrape(options);

    // Update corresponding database Scraper model if it exists
    try {
        await Scraper.findOneAndUpdate(
            { $or: [{ code: code.toUpperCase() }, { code: code.toLowerCase() }, { name: scraperInstance.name }] },
            {
                $set: {
                    status: result.status === "completed" ? "active" : "failed",
                    lastRunTime: new Date(),
                    jobsFound: result.processedCount,
                    errorMessage: result.errorMessage || null,
                },
            }
        );
    } catch (e) {
        logger.warn("DATABASE", `Could not update Scraper document status: ${e.message}`);
    }

    return result;
}

/**
 * Executes a scraper by its MongoDB document ID
 * @param {string} scraperId
 * @param {object} [options]
 */
async function runScraperById(scraperId, options = {}) {
    const scraperDoc = await Scraper.findById(scraperId);
    if (!scraperDoc) {
        throw new Error(`Scraper with ID ${scraperId} not found`);
    }

    const code = scraperDoc.code || scraperDoc.name || "KERALA_PSC";
    return runScraperByCode(code, {
        config: {
            code: scraperDoc.code,
            name: scraperDoc.name,
            targetUrl: scraperDoc.targetUrl,
            category: scraperDoc.category,
        },
        ...options,
    });
}

/**
 * Returns a list of all registered scraper adapters
 */
function getAvailableScraperAdapters() {
    return registry.list();
}

/**
 * Returns latest scrape execution history runs
 */
async function getScrapeRuns(limit = 20) {
    return ScrapeRun.find().sort({ startedAt: -1 }).limit(limit);
}

/**
 * Returns unhandled scrape errors
 */
async function getScrapeErrors(limit = 50) {
    return ScrapeError.find().sort({ createdAt: -1 }).limit(limit);
}

module.exports = {
    runScraperByCode,
    runScraperById,
    getAvailableScraperAdapters,
    getScrapeRuns,
    getScrapeErrors,
};
