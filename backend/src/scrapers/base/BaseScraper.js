/**
 * BaseScraper: Abstract Base Class for all JobSense Web Scraper Plugins
 * Defines the standardized lifecycle for discovery, document extraction, and ingestion.
 */

const axios = require("axios");
const ScraperResult = require("./ScraperResult");
const ScrapeRun = require("../../models/ScrapeRun");
const ScrapeError = require("../../models/ScrapeError");
const { downloadPdfBuffer, extractTextFromPdf } = require("../../services/pdf/pdfExtractor");
const { analyzeNotificationDocument } = require("../../services/analyzer/notificationAnalyzer");
const { saveOrUpdateJob } = require("../../services/jobService");
const { logger } = require("../../utils/logger");

class BaseScraper {
    /**
     * @param {object} config
     * @param {string} config.code
     * @param {string} config.name
     * @param {string} config.targetUrl
     * @param {string} [config.category]
     */
    constructor(config) {
        if (!config || !config.code || !config.targetUrl) {
            throw new Error("BaseScraper requires config with 'code' and 'targetUrl'");
        }
        this.code = config.code;
        this.name = config.name || config.code;
        this.targetUrl = config.targetUrl;
        this.category = config.category || "Government";
        this.timeoutMs = config.timeoutMs || 15000;

        this.httpClient = axios.create({
            timeout: this.timeoutMs,
            headers: {
                "User-Agent":
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 JobSenseBot/2.0",
                Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
            },
        });
    }

    /**
     * Phase 1: Discover listing page HTML
     * @returns {Promise<string>}
     */
    async discover() {
        logger.scraper(`[${this.code}] Discovering listing endpoint: ${this.targetUrl}`);
        const response = await this.httpClient.get(this.targetUrl);
        return response.data;
    }

    /**
     * Phase 2: Extract active notification groups from listing HTML
     * Must be implemented by subclass
     * @param {string} html
     * @returns {Promise<Array<{ title: string, url: string, lastDate: string, categoryNumber: string, isActive: boolean }>>}
     */
    async extractNotifications(html) {
        throw new Error("extractNotifications() must be implemented by subclass");
    }

    /**
     * Phase 3: Extract individual job items from a notification group page
     * Must be implemented by subclass
     * @param {string} groupUrl
     * @param {object} groupContext
     * @returns {Promise<Array<{ title: string, url: string, pdfUrl: string, categoryNumber: string }>>}
     */
    async extractJobLinks(groupUrl, groupContext) {
        throw new Error("extractJobLinks() must be implemented by subclass");
    }

    /**
     * Phase 4: Find the exact document/PDF link for a job item
     * @param {object} jobItem
     * @returns {Promise<string>}
     */
    async findDocument(jobItem) {
        return jobItem.pdfUrl || jobItem.url || "";
    }

    /**
     * Phase 5: Normalizes extracted parsed data into standardized Job structure
     * @param {string} rawPdfText
     * @param {object} itemContext
     * @returns {object}
     */
    normalize(rawPdfText, itemContext) {
        return analyzeNotificationDocument(rawPdfText, {
            sourceName: this.name,
            website: this.targetUrl,
            listingUrl: this.targetUrl,
            notificationUrl: itemContext.url || itemContext.groupUrl || "",
            pdfUrl: itemContext.pdfUrl || "",
            rawTitle: itemContext.title || "",
            categoryNumber: itemContext.categoryNumber || "",
            organization: this.name,
            jobType: this.category,
            lastDate: itemContext.lastDate || "",
            gazetteDate: itemContext.gazetteDate || "",
        });
    }

    /**
     * Master Scrape Execution Pipeline
     * Executes the complete chain with comprehensive error boundaries
     * @param {object} [options]
     * @param {number} [options.maxItems=10]
     * @returns {Promise<ScraperResult>}
     */
    async scrape(options = {}) {
        const maxItems = options.maxItems || 15;
        const result = new ScraperResult({
            scraperCode: this.code,
            scraperName: this.name,
            targetUrl: this.targetUrl,
        });

        // Initialize ScrapeRun document in MongoDB
        let scrapeRunDoc = null;
        try {
            scrapeRunDoc = await ScrapeRun.create({
                scraperCode: this.code,
                scraperName: this.name,
                targetUrl: this.targetUrl,
                status: "running",
            });
        } catch (e) {
            logger.warn("DATABASE", `Could not create ScrapeRun log: ${e.message}`);
        }

        try {
            // 1. Discover listing page
            const listingHtml = await this.discover();

            // 2. Extract notification groups (e.g. Gazette dates)
            const notificationGroups = await this.extractNotifications(listingHtml);
            result.totalFound = notificationGroups.length;

            const activeGroups = notificationGroups.filter((g) => g.isActive !== false);
            result.activeFound = activeGroups.length;

            logger.scraper(
                `[${this.code}] Discovered ${notificationGroups.length} notification groups (${activeGroups.length} active deadlines)`
            );

            // 3. Process active notification groups
            let processedJobsCount = 0;

            for (const group of activeGroups) {
                if (processedJobsCount >= maxItems) break;

                try {
                    logger.scraper(`[${this.code}] Exploring group: "${group.title}" (${group.url})`);
                    const jobItems = await this.extractJobLinks(group.url, group);
                    logger.scraper(`[${this.code}] Found ${jobItems.length} individual job posts in group "${group.title}"`);

                    for (const jobItem of jobItems) {
                        if (processedJobsCount >= maxItems) break;
                        processedJobsCount++;

                        try {
                            // 4. Resolve document PDF URL
                            const pdfUrl = await this.findDocument(jobItem);
                            if (!pdfUrl) {
                                throw new Error(`No PDF or document URL found for job "${jobItem.title}"`);
                            }
                            jobItem.pdfUrl = pdfUrl;

                            // 5. Download and extract PDF text (with OCR fallback)
                            const { buffer } = await downloadPdfBuffer(pdfUrl, 20000);
                            const { text: rawPdfText, method: extractionMethod } = await extractTextFromPdf(buffer, pdfUrl);

                            // 6. Analyze document and build normalized job schema
                            const normalizedJobData = this.normalize(rawPdfText, {
                                ...jobItem,
                                groupUrl: group.url,
                                lastDate: group.lastDate || jobItem.lastDate,
                                gazetteDate: group.gazetteDate || jobItem.gazetteDate,
                            });
                            normalizedJobData.extractionMethod = extractionMethod;

                            // 7. Deduplicate & Save in MongoDB
                            const saveResult = await saveOrUpdateJob(normalizedJobData, {
                                scraperCode: this.code,
                                scrapeRunId: scrapeRunDoc?._id,
                            });

                            result.recordSuccess(
                                {
                                    id: saveResult.job?._id || saveResult.job?.id,
                                    title: normalizedJobData.job.title,
                                    categoryNumber: normalizedJobData.job.categoryNumber,
                                    pdfUrl: pdfUrl,
                                    status: saveResult.status,
                                },
                                saveResult.status
                            );
                        } catch (jobErr) {
                            logger.error("SCRAPER", `[${this.code}] Failed processing job "${jobItem.title}"`, jobErr);
                            result.recordFailure({
                                title: jobItem.title || "Unknown Job",
                                url: jobItem.url || group.url,
                                error: jobErr.message,
                            });

                            if (scrapeRunDoc) {
                                await ScrapeError.create({
                                    scraperCode: this.code,
                                    scrapeRunId: scrapeRunDoc._id,
                                    phase: jobErr.message.includes("PDF") ? "PDF_DOWNLOAD" : "ANALYSIS",
                                    url: jobItem.pdfUrl || jobItem.url || group.url,
                                    notificationTitle: jobItem.title || "Unknown Job",
                                    categoryNumber: jobItem.categoryNumber || "",
                                    errorMessage: jobErr.message,
                                    stack: jobErr.stack,
                                }).catch(() => {});
                            }
                            // Continue with next job (robust error boundary)
                        }
                    }
                } catch (groupErr) {
                    logger.error("SCRAPER", `[${this.code}] Failed exploring notification group "${group.title}"`, groupErr);
                    if (scrapeRunDoc) {
                        await ScrapeError.create({
                            scraperCode: this.code,
                            scrapeRunId: scrapeRunDoc._id,
                            phase: "DISCOVERY",
                            url: group.url || this.targetUrl,
                            notificationTitle: group.title || "Notification Group",
                            categoryNumber: group.categoryNumber || "",
                            errorMessage: groupErr.message,
                            stack: groupErr.stack,
                        }).catch(() => {});
                    }
                    // Continue with next group
                }
            }

            result.finish("completed");
        } catch (fatalErr) {
            logger.error("SCRAPER", `[${this.code}] Critical scraper failure`, fatalErr);
            result.finish("failed");
            result.errorMessage = fatalErr.message;
        }

        // Update ScrapeRun document in MongoDB
        if (scrapeRunDoc) {
            try {
                scrapeRunDoc.status = result.status;
                scrapeRunDoc.finishedAt = result.finishedAt;
                scrapeRunDoc.totalFound = result.totalFound;
                scrapeRunDoc.activeFound = result.activeFound;
                scrapeRunDoc.processedCount = result.processedCount;
                scrapeRunDoc.newSavedCount = result.newSavedCount;
                scrapeRunDoc.updatedCount = result.updatedCount;
                scrapeRunDoc.failedCount = result.failedCount;
                scrapeRunDoc.durationMs = result.durationMs;
                scrapeRunDoc.errorMessage = result.errorMessage || null;
                scrapeRunDoc.summary = {
                    items: result.items,
                    errors: result.errors,
                };
                await scrapeRunDoc.save();
            } catch (e) {
                logger.warn("DATABASE", `Could not update ScrapeRun record: ${e.message}`);
            }
        }

        return result;
    }
}

module.exports = BaseScraper;
