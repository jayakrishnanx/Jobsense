/**
 * Standardized Scraper Result Container
 */

class ScraperResult {
    constructor({ scraperCode, scraperName, targetUrl }) {
        this.scraperCode = scraperCode;
        this.scraperName = scraperName;
        this.targetUrl = targetUrl;
        this.startedAt = new Date();
        this.finishedAt = null;
        this.status = "running";
        this.totalFound = 0;
        this.activeFound = 0;
        this.processedCount = 0;
        this.newSavedCount = 0;
        this.updatedCount = 0;
        this.failedCount = 0;
        this.items = [];
        this.errors = [];
    }

    recordSuccess(item, status = "CREATED") {
        this.processedCount++;
        if (status === "CREATED") {
            this.newSavedCount++;
        } else if (status === "UPDATED") {
            this.updatedCount++;
        }
        this.items.push(item);
    }

    recordFailure(error) {
        this.processedCount++;
        this.failedCount++;
        this.errors.push(error);
    }

    finish(status = "completed") {
        this.finishedAt = new Date();
        this.status = status;
        this.durationMs = this.finishedAt.getTime() - this.startedAt.getTime();
        return this;
    }
}

module.exports = ScraperResult;
