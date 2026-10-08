/**
 * SSC Announcements HTML Parser
 * Parses announcement tables and extracts notice metadata and PDF links
 */

const cheerio = require("cheerio");
const { resolveUrl, isPdfUrl, extractFilename } = require("../../utils/urlUtils");
const { parseDate, normalizeDateIso } = require("../../utils/dateUtils");

/**
 * Parses SSC Announcements table rows
 * @param {string} html
 * @param {string} baseUrl
 * @returns {Array<object>}
 */
function parseAnnouncementsTable(html, baseUrl = "https://ssccr.gov.in") {
    const $ = cheerio.load(html);
    const notifications = [];

    // Target the table rows in tbody
    const rows = $("table tbody tr, table[data-slot='table'] tbody tr");

    rows.each((index, element) => {
        const cells = $(element).find("td");
        if (cells.length < 3) return; // Skip pagination row or malformed row

        const sNo = $(cells[0]).text().trim();
        const descriptionEl = $(cells[1]);
        const descriptionText = descriptionEl.text().replace(/\s+/g, " ").trim();

        if (!descriptionText || descriptionText.toLowerCase().includes("pagination")) {
            return;
        }

        // Extract PDF Link from files cell or description cell
        let pdfUrl = "";
        let pdfFilename = "";

        const filesCell = cells.length >= 4 ? $(cells[2]) : null;
        let fileLink = filesCell ? filesCell.find("a[href]") : null;

        if (!fileLink || fileLink.length === 0) {
            fileLink = $(element).find("a[href*='.pdf'], a[href*='/api/media/file/']");
        }

        if (fileLink && fileLink.length > 0) {
            const rawHref = fileLink.first().attr("href");
            if (rawHref) {
                pdfUrl = resolveUrl(baseUrl, rawHref);
                pdfFilename = fileLink.first().text().trim() || extractFilename(pdfUrl);
            }
        }

        // Post Date
        const dateCell = cells.length >= 4 ? $(cells[3]) : $(cells[cells.length - 1]);
        const postDateText = dateCell.text().replace(/\s+/g, " ").trim();
        const parsedDate = parseDate(postDateText);
        const postDateIso = normalizeDateIso(parsedDate);

        // Extract Category / Post Code if present (e.g. CR13324, CR12624, CR10224)
        let categoryNumber = "";
        const postCodeMatch = descriptionText.match(/\b(CR\d{5}|CR\d{4}[A-Z]?)\b/i);
        if (postCodeMatch) {
            categoryNumber = postCodeMatch[1].toUpperCase();
        } else if (descriptionText.toLowerCase().includes("cgle") || descriptionText.toLowerCase().includes("combined graduate level")) {
            categoryNumber = "CGL-2026";
        } else if (descriptionText.toLowerCase().includes("multi tasking staff") || descriptionText.toLowerCase().includes("mts")) {
            categoryNumber = "MTS-2026";
        }

        // Extract clean post name / designation
        let cleanTitle = descriptionText;
        if (cleanTitle.startsWith("Post Code ")) {
            cleanTitle = cleanTitle.replace(/^Post Code\s+[A-Z0-9]+[-:\s]*/i, "");
        } else if (cleanTitle.startsWith("Important Notice- ")) {
            cleanTitle = cleanTitle.replace(/^Important Notice-?\s*/i, "");
        }

        notifications.push({
            sNo: parseInt(sNo, 10) || index + 1,
            title: cleanTitle.trim() || descriptionText,
            rawDescription: descriptionText,
            categoryNumber,
            pdfUrl,
            pdfFilename,
            postDate: postDateText,
            postDateIso: postDateIso,
            url: pdfUrl || `${baseUrl}/announcements`,
            organization: "Staff Selection Commission",
            department: "Government of India (Central Region)",
            jobType: "Central Govt",
            location: "All India",
        });
    });

    return notifications;
}

module.exports = {
    parseAnnouncementsTable,
};
