/**
 * KeralaPSCScraper: Modular Scraper Adapter for Kerala Public Service Commission
 * Extends BaseScraper and follows the complete discovery -> gazette -> job -> PDF -> MongoDB chain.
 */

const cheerio = require("cheerio");
const BaseScraper = require("../base/BaseScraper");
const registry = require("../base/ScraperRegistry");
const config = require("./config");
const { parseNotificationsListing, parseGazetteJobLinks } = require("./parser");
const { resolveUrl, isPdfUrl } = require("../../utils/urlUtils");
const { logger } = require("../../utils/logger");

class KeralaPSCScraper extends BaseScraper {
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
     * Extracts active notification groups (e.g. Gazette dates) from /notifications table
     */
    async extractNotifications(html) {
        logger.scraper(`[${this.code}] Parsing notifications listing table...`);
        return parseNotificationsListing(html, this.baseUrl);
    }

    /**
     * Extracts individual job items from a specific Gazette page
     * E.g. /extra-ordinary-gazette-date-30092026
     */
    async extractJobLinks(groupUrl, groupContext) {
        logger.scraper(`[${this.code}] Fetching gazette group page: ${groupUrl}`);
        const response = await this.httpClient.get(groupUrl);
        const groupHtml = response.data;
        return parseGazetteJobLinks(groupHtml, groupUrl, this.baseUrl);
    }

    /**
     * Resolves the actual PDF document link for a job post
     * If link is directly a PDF, returns it. If it's an intermediate page, scrapes the PDF link.
     */
    async findDocument(jobItem) {
        if (jobItem.pdfUrl && isPdfUrl(jobItem.pdfUrl)) {
            return jobItem.pdfUrl;
        }

        if (jobItem.url && isPdfUrl(jobItem.url)) {
            return jobItem.url;
        }

        // If it's an intermediate landing page, fetch and locate the PDF download link
        if (jobItem.url) {
            try {
                logger.pdf(`[${this.code}] Searching intermediate page for PDF: ${jobItem.url}`);
                const res = await this.httpClient.get(jobItem.url);
                const $ = cheerio.load(res.data);
                const pdfAnchor = $("a[href*='.pdf'], a[href*='/sites/default/files/']").first();
                if (pdfAnchor.length > 0) {
                    const foundHref = pdfAnchor.attr("href");
                    const resolvedPdf = resolveUrl(this.baseUrl, foundHref);
                    logger.pdf(`[${this.code}] Found PDF document link: ${resolvedPdf}`);
                    return resolvedPdf;
                }
            } catch (err) {
                logger.warn("PDF", `[${this.code}] Could not resolve PDF from intermediate page: ${err.message}`);
            }
        }

        return jobItem.url || "";
    }
}

// Auto-register scraper with registry under multiple recognizable aliases
registry.register(["kerala_psc", "kpsc", "kerala-psc", "KERALA_PSC"], KeralaPSCScraper);

module.exports = KeralaPSCScraper;
