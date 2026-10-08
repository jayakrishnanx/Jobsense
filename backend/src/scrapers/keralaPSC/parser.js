/**
 * Kerala PSC HTML Parsers
 * Extracts notification listing table and gazette group job item links
 */

const cheerio = require("cheerio");
const { resolveUrl, isPdfUrl } = require("../../utils/urlUtils");
const { isActiveDeadline, parseDate, normalizeDateIso } = require("../../utils/dateUtils");
const { logger } = require("../../utils/logger");

/**
 * Parses the Kerala PSC /notifications table
 * Table Columns: Title | Category Number | Last date
 * @param {string} html
 * @param {string} baseUrl
 * @returns {Array<{ title: string, url: string, categoryNumber: string, lastDate: string, gazetteDate: string, isActive: boolean }>}
 */
function parseNotificationsListing(html, baseUrl = "https://www.keralapsc.gov.in") {
    if (!html || typeof html !== "string") return [];

    const $ = cheerio.load(html);
    const groups = [];

    // Find all rows in table
    $("table tr").each((index, row) => {
        // Skip header row if it contains <th>
        if ($(row).find("th").length > 0) return;

        const cells = $(row).find("td");
        if (cells.length < 2) return;

        // 1. Column 1: Title & link
        const titleCell = $(cells[0]);
        const titleLink = titleCell.find("a").first();
        const titleText = (titleLink.text() || titleCell.text()).trim().replace(/\s+/g, " ");
        let groupHref = titleLink.attr("href") || "";

        // If no link on title cell, scan other cells for anchor
        if (!groupHref) {
            groupHref = $(row).find("a").first().attr("href") || "";
        }

        if (!titleText || titleText.length < 5) return;

        // 2. Column 2: Category Number (e.g. CAT.NO.151/2026 TO CAT.NO.161/2026)
        let categoryNumber = "";
        if (cells.length >= 2) {
            categoryNumber = $(cells[1]).text().trim().replace(/\s+/g, " ");
        }

        // 3. Column 3: Last Date (e.g. 04-11-2026)
        let lastDate = "";
        if (cells.length >= 3) {
            lastDate = $(cells[2]).text().trim().replace(/\s+/g, "");
        } else {
            // Check if last date is embedded in text
            const dateMatch = $(row).text().match(/\b\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4}\b/);
            if (dateMatch) lastDate = dateMatch[0];
        }

        // 4. Extract Gazette Date from title (e.g. "EXTRA ORDINARY GAZETTE DATE 30/09/2026" -> "30/09/2026")
        let gazetteDate = "";
        const gazMatch = titleText.match(/\b\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4}\b/);
        if (gazMatch) {
            gazetteDate = gazMatch[0];
        }

        const fullUrl = resolveUrl(baseUrl, groupHref);
        const isActive = isActiveDeadline(lastDate);

        groups.push({
            title: titleText,
            url: fullUrl,
            categoryNumber,
            lastDate,
            gazetteDate,
            isActive,
        });
    });

    // Fallback: If no table rows matched, search list elements or links containing gazette
    if (groups.length === 0) {
        $("a").each((i, el) => {
            const text = $(el).text().trim().replace(/\s+/g, " ");
            const href = $(el).attr("href") || "";
            if (text.toLowerCase().includes("gazette") && href && href.length > 3) {
                const dateMatch = text.match(/\b\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4}\b/);
                groups.push({
                    title: text,
                    url: resolveUrl(baseUrl, href),
                    categoryNumber: "",
                    lastDate: dateMatch ? dateMatch[0] : "",
                    gazetteDate: dateMatch ? dateMatch[0] : "",
                    isActive: true,
                });
            }
        });
    }

    return groups;
}

/**
 * Parses individual job notification items from a Gazette group page
 * E.g. /extra-ordinary-gazette-date-30092026
 * Items:
 * - Draftsman Grade-II - Kerala Ports service (Hydrographic Survey Wing) (Cat.No.151/2026)
 * - Peon/Watchman (D / R from among the Part-Time employees in KSFE Ltd.) - KSFE (Cat.No.152/2026)
 * @param {string} html
 * @param {string} groupUrl
 * @param {string} baseUrl
 * @returns {Array<{ title: string, url: string, pdfUrl: string, categoryNumber: string, department: string }>}
 */
function parseGazetteJobLinks(html, groupUrl, baseUrl = "https://www.keralapsc.gov.in") {
    if (!html || typeof html !== "string") return [];

    const $ = cheerio.load(html);
    // Remove site header, navigation menus, footer to avoid false anchors
    $("header, nav, footer, #header, #navigation, #block-mainnavigation, .navbar, .region-header").remove();

    const jobItems = [];
    const seen = new Set();

    // 1. Check all list items and anchors in the main content body
    $(".region-content, .field--name-body, .node__content, article, main, body")
        .find("li, p, .field-content, div")
        .each((index, el) => {
            const link = $(el).find("a").first();
            if (link.length === 0) return;

            const rawHref = link.attr("href") || "";
            const itemText = (link.text() || $(el).text()).trim().replace(/\s+/g, " ");

            if (!rawHref || itemText.length < 8) return;

            // Skip non-job utility links (like back, home, print)
            const lower = itemText.toLowerCase();
            if (
                lower === "back" ||
                lower === "home" ||
                lower === "print" ||
                lower === "notifications" ||
                lower.includes("privacy policy") ||
                lower.includes("terms of service") ||
                lower.includes("contact us")
            ) {
                return;
            }

            // Must look like a recruitment notice or have a PDF or category number
            const hasCat = /Cat\.?\s*No\.?|\d{1,4}\/\d{4}/i.test(itemText);
            const isPdf = isPdfUrl(rawHref);
            const looksLikeJob = hasCat || isPdf || lower.includes("officer") || lower.includes("assistant") || lower.includes("teacher") || lower.includes("driver") || lower.includes("grade") || lower.includes("clerk") || lower.includes("peon") || lower.includes("surveyor") || lower.includes("engineer");

            if (!looksLikeJob) return;

            const fullLink = resolveUrl(baseUrl, rawHref);
            if (seen.has(fullLink)) return;
            seen.add(fullLink);

            // Extract category number (e.g. Cat.No.151/2026 or 151/2026)
            let categoryNumber = "";
            const catMatch = itemText.match(/(?:Cat\.?\s*No\.?|Category\s*No\.?)\s*[:\-]?\s*(\d{1,4}\s*\/\s*\d{4})/i);
            if (catMatch) {
                categoryNumber = catMatch[1].replace(/\s+/g, "");
            }

            // Try extracting department from hyphen-delimited text
            let department = "Government of Kerala";
            if (itemText.includes(" - ")) {
                const parts = itemText.split(" - ");
                if (parts.length >= 2) {
                    department = parts[1].replace(/\(Cat\.?[^\)]+\)/i, "").trim();
                }
            }

            jobItems.push({
                title: itemText,
                url: fullLink,
                pdfUrl: isPdf ? fullLink : "",
                categoryNumber,
                department,
                groupUrl,
            });
        });

    return jobItems;
}

module.exports = {
    parseNotificationsListing,
    parseGazetteJobLinks,
};
