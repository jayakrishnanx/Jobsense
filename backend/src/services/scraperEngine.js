const axios = require("axios");
const cheerio = require("cheerio");
const Scraper = require("../models/scraper");
const ScrapedJob = require("../models/scrapedJob");
const Job = require("../models/job");
const SystemLog = require("../models/systemLog");
const Notification = require("../models/notification");

const DEFAULT_SCRAPERS = [];


const INITIAL_REAL_JOBS = [];

/**
 * Initialize Default Scrapers and Real Jobs if collections are empty
 */
async function seedInitialScraperData() {
    try {
        // Clean scrapers and scraped jobs so user can supply websites one by one
        await Scraper.deleteMany({});
        await ScrapedJob.deleteMany({});
        console.log(`-> Scrapers and scraped jobs cleared. Ready for custom websites.`);
    } catch (err) {
        console.error("Error in scraper initialization:", err.message);
    }
}


/**
 * Live Scraper Worker Function
 * Executes live HTTP GET request, extracts fresh announcements, and adds to ScrapedJob collection
 */
async function executeScraper(scraperId) {
    const scraper = await Scraper.findById(scraperId);
    if (!scraper) throw new Error("Scraper not found");

    scraper.status = "running";
    scraper.errorMessage = null;
    await scraper.save();

    await SystemLog.create({
        level: "INFO",
        category: "SCRAPER",
        message: `Scraper execution triggered: ${scraper.name}`,
        details: `Connecting to target endpoint: ${scraper.targetUrl}`,
    });

    try {
        // Perform real HTTP request with timeout & browser user-agent
        const response = await axios.get(scraper.targetUrl, {
            timeout: 12000,
            headers: {
                "User-Agent":
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 JobSenseBot/2.0",
                Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            },
        });

        const html = response.data;
        let extractedItems = [];

        // 1. Check if XML / RSS Feed
        if (typeof html === "string" && (html.includes("<rss") || html.includes("<feed") || html.includes("<item>"))) {
            const $ = cheerio.load(html, { xmlMode: true });
            $("item").each((i, el) => {
                const title = $(el).find("title").text().trim();
                const link = $(el).find("link").text().trim();
                if (title && title.length > 10) {
                    extractedItems.push({
                        title: title.replace(/\s+/g, " "),
                        link: link || scraper.targetUrl,
                    });
                }
            });
        } else {
            // 2. HTML Multi-Selector Strategy
            const $ = cheerio.load(html);

            // Check tables, list items, cards, and anchors
            $("table tr, li, .views-row, .card, .notice, a").each((i, el) => {
                const text = $(el).text().trim().replace(/\s+/g, " ");
                let href = $(el).attr("href") || $(el).find("a").attr("href");

                if (
                    text &&
                    text.length >= 15 &&
                    text.length <= 250 &&
                    (text.toLowerCase().includes("recruitment") ||
                        text.toLowerCase().includes("examination") ||
                        text.toLowerCase().includes("advt") ||
                        text.toLowerCase().includes("notification") ||
                        text.toLowerCase().includes("vacancy") ||
                        text.toLowerCase().includes("post") ||
                        text.toLowerCase().includes("officer") ||
                        text.toLowerCase().includes("assistant") ||
                        text.toLowerCase().includes("engineer") ||
                        text.toLowerCase().includes("clerk") ||
                        text.toLowerCase().includes("apply") ||
                        text.toLowerCase().includes("result"))
                ) {
                    const fullUrl = href && href.startsWith("http") ? href : `${scraper.targetUrl}/${href || ""}`;
                    extractedItems.push({
                        title: text,
                        link: fullUrl,
                    });
                }
            });
        }

        // Deduplicate and take top 6 notices
        const uniqueItems = Array.from(new Map(extractedItems.map((item) => [item.title, item])).values()).slice(0, 6);

        let newJobsSaved = 0;
        for (const item of uniqueItems) {
            const alreadyExists = await ScrapedJob.findOne({ title: item.title });
            if (!alreadyExists) {
                // Heuristic field extraction
                let qualification = "Any Degree / Diploma";
                const lower = item.title.toLowerCase();
                if (lower.includes("graduate") || lower.includes("degree") || lower.includes("officer")) {
                    qualification = "Degree (Graduation)";
                } else if (lower.includes("engineer") || lower.includes("b.tech") || lower.includes("technical")) {
                    qualification = "B.Tech / B.E / Diploma";
                } else if (lower.includes("10th") || lower.includes("matric") || lower.includes("sslc")) {
                    qualification = "10th / SSLC";
                } else if (lower.includes("12th") || lower.includes("plus two") || lower.includes("chsl")) {
                    qualification = "12th / Plus Two";
                }

                await ScrapedJob.create({
                    title: item.title,
                    organization: scraper.name.split("(")[0].trim(),
                    source: scraper.targetUrl,
                    officialUrl: item.link,
                    vacancies: "As per Notification",
                    qualification: qualification,
                    lastDate: "See Official Notice",
                    confidenceScore: 0.93,
                    reviewStatus: "pending",
                    categoryTag: scraper.category,
                });
                newJobsSaved++;
            }
        }

        scraper.status = "active";
        scraper.lastRunTime = new Date();
        scraper.nextRunTime = new Date(Date.now() + scraper.frequencyMinutes * 60 * 1000);
        scraper.jobsFound += newJobsSaved;
        await scraper.save();

        await SystemLog.create({
            level: "SUCCESS",
            category: "SCRAPER",
            message: `Scraper ${scraper.name} executed successfully`,
            details: `Extracted ${uniqueItems.length} announcements (${newJobsSaved} new queued for admin moderation).`,
        });


        return {
            success: true,
            totalFound: uniqueItems.length,
            newSaved: newJobsSaved,
            items: uniqueItems,
        };
    } catch (err) {
        // Record error and set status
        scraper.status = "failed";
        scraper.errorMessage = err.message;
        scraper.lastRunTime = new Date();
        await scraper.save();

        await SystemLog.create({
            level: "ERROR",
            category: "SCRAPER",
            message: `Scraper error on ${scraper.name}`,
            details: err.message,
        });

        return {
            success: false,
            error: err.message,
        };
    }
}

module.exports = {
    seedInitialScraperData,
    executeScraper,
    INITIAL_REAL_JOBS,
    DEFAULT_SCRAPERS,
};
