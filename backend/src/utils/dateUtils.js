/**
 * Date Utility for JobSense
 * Handles parsing, normalization, and active-status checks for various date formats
 */

const MONTH_NAMES = {
    january: 0, jan: 0,
    february: 1, feb: 1,
    march: 2, mar: 2,
    april: 3, apr: 3,
    may: 4,
    june: 5, jun: 5,
    july: 6, jul: 6,
    august: 7, aug: 7,
    september: 8, sep: 8, sept: 8,
    october: 9, oct: 9,
    november: 10, nov: 10,
    december: 11, dec: 11,
};

/**
 * Parses diverse date formats into a standard JS Date object
 * Handles:
 * - 04-11-2026 / 04/11/2026 / 04.11.2026 (DD-MM-YYYY)
 * - 2026-11-04 (YYYY-MM-DD)
 * - 4 November 2026 / 04 Nov 2026
 * - November 4, 2026
 */
function parseDate(dateStr) {
    if (!dateStr || typeof dateStr !== "string") return null;

    const clean = dateStr.trim().replace(/[,\s]+/g, " ");

    // 1. Match DD-MM-YYYY or DD/MM/YYYY or DD.MM.YYYY
    const dmyMatch = clean.match(/^(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})$/);
    if (dmyMatch) {
        const day = parseInt(dmyMatch[1], 10);
        const month = parseInt(dmyMatch[2], 10) - 1;
        const year = parseInt(dmyMatch[3], 10);
        const date = new Date(Date.UTC(year, month, day, 23, 59, 59));
        return isNaN(date.getTime()) ? null : date;
    }

    // 2. Match YYYY-MM-DD
    const ymdMatch = clean.match(/^(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})$/);
    if (ymdMatch) {
        const year = parseInt(ymdMatch[1], 10);
        const month = parseInt(ymdMatch[2], 10) - 1;
        const day = parseInt(ymdMatch[3], 10);
        const date = new Date(Date.UTC(year, month, day, 23, 59, 59));
        return isNaN(date.getTime()) ? null : date;
    }

    // 3. Match DD Month YYYY (e.g. 04 November 2026, 4 Nov 2026)
    const textDateMatch1 = clean.match(/^(\d{1,2})\s+([a-zA-Z]+)\s+(\d{4})$/);
    if (textDateMatch1) {
        const day = parseInt(textDateMatch1[1], 10);
        const monthKey = textDateMatch1[2].toLowerCase();
        const year = parseInt(textDateMatch1[3], 10);
        if (MONTH_NAMES[monthKey] !== undefined) {
            const date = new Date(Date.UTC(year, MONTH_NAMES[monthKey], day, 23, 59, 59));
            return isNaN(date.getTime()) ? null : date;
        }
    }

    // 4. Match Month DD YYYY (e.g. November 04 2026)
    const textDateMatch2 = clean.match(/^([a-zA-Z]+)\s+(\d{1,2})\s+(\d{4})$/);
    if (textDateMatch2) {
        const monthKey = textDateMatch2[1].toLowerCase();
        const day = parseInt(textDateMatch2[2], 10);
        const year = parseInt(textDateMatch2[3], 10);
        if (MONTH_NAMES[monthKey] !== undefined) {
            const date = new Date(Date.UTC(year, MONTH_NAMES[monthKey], day, 23, 59, 59));
            return isNaN(date.getTime()) ? null : date;
        }
    }

    // Fallback standard JS Date parser
    const fallback = new Date(clean);
    if (!isNaN(fallback.getTime())) {
        return fallback;
    }

    return null;
}

/**
 * Normalizes date to ISO string (YYYY-MM-DD)
 */
function normalizeDateIso(dateInput) {
    if (!dateInput) return null;
    const date = dateInput instanceof Date ? dateInput : parseDate(dateInput);
    if (!date || isNaN(date.getTime())) return null;
    return date.toISOString().split("T")[0];
}

/**
 * Checks if a given application deadline is currently active (future or today)
 * @param {string|Date} deadlineStr
 * @param {Date} [referenceDate]
 * @returns {boolean}
 */
function isActiveDeadline(deadlineStr, referenceDate = new Date()) {
    const deadline = deadlineStr instanceof Date ? deadlineStr : parseDate(deadlineStr);
    if (!deadline) {
        // If deadline cannot be determined, treat as active to avoid dropping notices prematurely
        return true;
    }
    const ref = new Date(referenceDate);
    // Compare date timestamps at end of day
    return deadline.getTime() >= ref.getTime();
}

/**
 * Scans a body of text and extracts all date occurrences
 */
function extractDatesFromText(text) {
    if (!text || typeof text !== "string") return [];
    const results = [];
    const dateRegex = /\b(?:\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4}|\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2}|\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4})\b/gi;
    let match;
    while ((match = dateRegex.exec(text)) !== null) {
        const parsed = parseDate(match[0]);
        if (parsed) {
            results.push({
                raw: match[0],
                parsed: parsed,
                iso: normalizeDateIso(parsed),
                index: match.index,
            });
        }
    }
    return results;
}

module.exports = {
    parseDate,
    normalizeDateIso,
    isActiveDeadline,
    extractDatesFromText,
};
