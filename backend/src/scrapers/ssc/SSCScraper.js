/**
 * SSCScraper: Modular Scraper Adapter for Staff Selection Commission (Central Region)
 * Extends BaseScraper and follows the discovery -> announcements -> PDF -> analysis -> MongoDB chain.
 */

const cheerio = require("cheerio");
const BaseScraper = require("../base/BaseScraper");
const registry = require("../base/ScraperRegistry");
const config = require("./config");
const { parseAnnouncementsTable } = require("./parser");
const { resolveUrl, isPdfUrl } = require("../../utils/urlUtils");
const { logger } = require("../../utils/logger");

class SSCScraper extends BaseScraper {
    constructor(customConfig = {}) {
        super({
            code: config.code,
            name: config.name,
            category: config.category,
            targetUrl: config.targetUrl,
            timeoutMs: config.timeoutMs,
            ...customConfig,
        });
        this.baseUrl = config.baseUrl;
        this.applyUrl = config.applyUrl;
    }

    /**
     * Extracts announcement rows from the SSC announcements table
     * @param {string} html
     * @returns {Promise<Array<object>>}
     */
    async extractNotifications(html) {
        logger.scraper(`[${this.code}] Parsing SSC Announcements table from ${this.targetUrl}...`);
        return parseAnnouncementsTable(html, this.baseUrl);
    }

    /**
     * Extracts individual job items (for SSC, each table row is already a job item)
     * @param {string} groupUrl
     * @param {object} groupContext
     * @returns {Promise<Array<object>>}
     */
    async extractJobLinks(groupUrl, groupContext) {
        return [groupContext];
    }

    /**
     * Resolves the actual PDF document link for an announcement item
     * @param {object} jobItem
     * @returns {Promise<string>}
     */
    async findDocument(jobItem) {
        if (jobItem.pdfUrl && isPdfUrl(jobItem.pdfUrl)) {
            return jobItem.pdfUrl;
        }

        if (jobItem.url && isPdfUrl(jobItem.url)) {
            return jobItem.url;
        }

        // If link is a web page, fetch and locate PDF link
        if (jobItem.url && jobItem.url.startsWith("http")) {
            try {
                logger.pdf(`[${this.code}] Checking announcement page for PDF: ${jobItem.url}`);
                const res = await this.httpClient.get(jobItem.url);
                const $ = cheerio.load(res.data);
                const pdfAnchor = $("a[href*='.pdf'], a[href*='/api/media/file/']").first();
                if (pdfAnchor.length > 0) {
                    const foundHref = pdfAnchor.attr("href");
                    const resolvedPdf = resolveUrl(this.baseUrl, foundHref);
                    logger.pdf(`[${this.code}] Found PDF document link: ${resolvedPdf}`);
                    return resolvedPdf;
                }
            } catch (err) {
                logger.warn("PDF", `[${this.code}] Could not resolve PDF from page: ${err.message}`);
            }
        }

        return jobItem.pdfUrl || jobItem.url || "";
    }

    /**
     * Overrides normalization to ensure SSC specific defaults
     */
    normalize(rawPdfText, itemContext) {
        const normalized = super.normalize(rawPdfText, itemContext);
        normalized.job.organization = "Staff Selection Commission";
        normalized.job.jobType = "Central Govt";
        normalized.job.location = "All India";
        normalized.application.applyUrl = this.applyUrl;

        if (itemContext.categoryNumber && !normalized.job.categoryNumber) {
            normalized.job.categoryNumber = itemContext.categoryNumber;
        }

        return normalized;
    }
}

// Auto-register scraper with registry under aliases
registry.register(["ssc", "ssc_cr", "ssc_central_region", "SSC_CR", "staff_selection_commission"], SSCScraper);

module.exports = SSCScraper;
