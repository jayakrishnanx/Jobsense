/**
 * Scraper Registry for JobSense
 * Manages scraper adapters and provides factory instantiation
 */

const { logger } = require("../../utils/logger");

class ScraperRegistry {
    constructor() {
        this.scrapers = new Map();
    }

    /**
     * Registers a scraper class under one or more aliases
     * @param {string|string[]} keys
     * @param {typeof import('./BaseScraper')} ScraperClass
     */
    register(keys, ScraperClass) {
        const keyList = Array.isArray(keys) ? keys : [keys];
        for (const k of keyList) {
            const normalizedKey = k.toLowerCase().replace(/[\s\-_]+/g, "_");
            this.scrapers.set(normalizedKey, ScraperClass);
            logger.info("REGISTRY", `Registered scraper adapter: "${normalizedKey}" -> ${ScraperClass.name}`);
        }
    }

    /**
     * Retrieves the scraper class for a given code
     * @param {string} code
     * @returns {typeof import('./BaseScraper')|null}
     */
    get(code) {
        if (!code) return null;
        const normalizedKey = code.toLowerCase().replace(/[\s\-_]+/g, "_");
        return this.scrapers.get(normalizedKey) || null;
    }

    /**
     * Instantiates a scraper by code with optional config overrides
     * @param {string} code
     * @param {object} [customConfig]
     * @returns {import('./BaseScraper')}
     */
    create(code, customConfig = {}) {
        const ScraperClass = this.get(code);
        if (!ScraperClass) {
            throw new Error(`No scraper adapter registered for code: "${code}"`);
        }
        return new ScraperClass(customConfig);
    }

    /**
     * Lists all registered scraper codes
     * @returns {string[]}
     */
    list() {
        return Array.from(this.scrapers.keys());
    }
}

const registry = new ScraperRegistry();

module.exports = registry;
