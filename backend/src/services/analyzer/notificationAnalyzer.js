/**
 * Notification Analyzer for JobSense
 * Extracts structured job attributes from raw PDF text (post name, department,
 * vacancies, pay scale, gazette dates, category number, and appointment method).
 */

const { parseDate, normalizeDateIso } = require("../../utils/dateUtils");
const { analyzeEligibility } = require("./eligibilityAnalyzer");
const { logger } = require("../../utils/logger");

/**
 * Normalizes multi-pattern post name / title
 */
function extractPostName(text, fallbackTitle = "") {
    if (!text) return fallbackTitle;

    // Pattern 1: "2. Name of Post : Draftsman Grade II" or "Name of Post: Draftsman Grade II"
    const nameOfPostMatch = text.match(/(?:2\.\s*Name\s*of\s*Post|Name\s*of\s*Post|Post\s*Name)\s*[:\-]\s*([^\n\r]+)/i);
    if (nameOfPostMatch && nameOfPostMatch[1].trim().length > 3) {
        return nameOfPostMatch[1].trim();
    }

    // Pattern 2: "RECRUITMENT TO THE POST OF ..."
    const recruitMatch = text.match(/recruitment\s+(?:to\s+the\s+post\s+of|for\s+the\s+post\s+of)\s+([^\n\r,]+)/i);
    if (recruitMatch && recruitMatch[1].trim().length > 3) {
        return recruitMatch[1].trim();
    }

    // Fallback: Check if fallbackTitle has useful content
    if (fallbackTitle && fallbackTitle.trim().length > 3) {
        return fallbackTitle.replace(/\s*\(Cat\.?No\.?[^\)]+\)/i, "").trim();
    }

    return "Recruitment Notification";
}

/**
 * Extracts Department / Sub-organization
 */
function extractDepartment(text, fallbackOrg = "Government of Kerala") {
    if (!text) return fallbackOrg;

    // Pattern 1: "1. Department : Kerala Ports service (Hydrographic Survey Wing)"
    const deptMatch = text.match(/(?:1\.\s*Department|Department)\s*[:\-]\s*([^\n\r]+)/i);
    if (deptMatch && deptMatch[1].trim().length > 2) {
        return deptMatch[1].trim();
    }

    return fallbackOrg;
}

/**
 * Extracts Scale of Pay / Salary Range
 */
function extractScaleOfPay(text) {
    if (!text) return { payScale: "As per Govt Norms", minimumSalary: null, maximumSalary: null };

    // Pattern: "3. Scale of Pay : ₹ 31,100-66,800/-" or "Scale of Pay : Rs. 31100 - 66800"
    const payMatch = text.match(/(?:3\.\s*Scale\s*of\s*Pay|Scale\s*of\s*Pay|Pay\s*Scale|Salary)\s*[:\-]\s*([^\n\r]+)/i);
    if (payMatch) {
        const rawPay = payMatch[1].trim();
        // Extract min and max numbers from string e.g. "31,100-66,800"
        const numbers = rawPay.replace(/,/g, "").match(/\d{4,7}/g);
        let min = null;
        let max = null;
        if (numbers && numbers.length >= 2) {
            min = parseInt(numbers[0], 10);
            max = parseInt(numbers[1], 10);
        } else if (numbers && numbers.length === 1) {
            min = parseInt(numbers[0], 10);
        }
        return {
            payScale: rawPay,
            minimumSalary: min,
            maximumSalary: max,
        };
    }

    // Generic currency pattern search
    const genMatch = text.match(/(?:₹|Rs\.?)\s*([\d,]+)\s*(?:-|to)\s*([\d,]+)/i);
    if (genMatch) {
        const min = parseInt(genMatch[1].replace(/,/g, ""), 10);
        const max = parseInt(genMatch[2].replace(/,/g, ""), 10);
        return {
            payScale: `₹ ${genMatch[1]} - ${genMatch[2]}/-`,
            minimumSalary: isNaN(min) ? null : min,
            maximumSalary: isNaN(max) ? null : max,
        };
    }

    return { payScale: "As per Govt Norms", minimumSalary: null, maximumSalary: null };
}

/**
 * Extracts Number of Vacancies
 */
function extractVacancies(text) {
    if (!text) return { number: null, details: "As per official notification" };

    // Pattern: "4. Number of vacancies : 2 (Two)" or "Number of vacancies : Anticipated"
    const vacMatch = text.match(/(?:4\.\s*Number\s*of\s*vacancies|Number\s*of\s*vacancies|Vacancies)\s*[:\-]\s*([^\n\r]+)/i);
    if (vacMatch) {
        const rawVac = vacMatch[1].trim();
        const numMatch = rawVac.match(/\b(\d+)\b/);
        const num = numMatch ? parseInt(numMatch[1], 10) : null;
        return {
            number: num,
            details: rawVac,
        };
    }

    return { number: null, details: "As per official notification" };
}

/**
 * Extracts Category Number (e.g. 151/2026)
 */
function extractCategoryNumber(text, fallbackCat = "") {
    if (text) {
        const catMatch = text.match(/(?:CATEGORY\s*NO\.?|CAT\.?\s*NO\.?)\s*[:\-]?\s*(\d{1,4}\s*\/\s*\d{4})/i);
        if (catMatch) {
            return catMatch[1].replace(/\s+/g, "");
        }
    }
    if (fallbackCat) {
        const clean = fallbackCat.match(/(\d{1,4}\s*\/\s*\d{4})/);
        if (clean) return clean[1].replace(/\s+/g, "");
        return fallbackCat;
    }
    return "";
}

/**
 * Extracts Gazette Date and Application Last Date from header
 */
function extractGazetteAndLastDates(text, fallbackDates = {}) {
    let gazetteDate = fallbackDates.gazetteDate || "";
    let lastDate = fallbackDates.lastDate || "";

    if (text) {
        // Gazette Date: "GAZETTE DATE : 30.09.2026" or "GAZETTE DATE : 30/09/2026"
        const gazMatch = text.match(/GAZETTE\s*DATE\s*[:\-]\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i);
        if (gazMatch) {
            gazetteDate = gazMatch[1].replace(/[\/\.]/g, "-");
        }

        // Last Date: "LAST DATE : 04.11.2026" or "LAST DATE : 04/11/2026"
        const lastMatch = text.match(/LAST\s*DATE\s*(?:FOR\s*RECEIPT\s*OF\s*APPLICATIONS?)?\s*[:\-]\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i);
        if (lastMatch) {
            lastDate = lastMatch[1].replace(/[\/\.]/g, "-");
        }
    }

    return {
        gazetteDate,
        applicationLastDate: lastDate || "See Notification",
        lastDateIso: normalizeDateIso(lastDate),
    };
}

/**
 * Extracts Method of Appointment (Direct Recruitment / By Transfer)
 */
function extractMethodOfAppointment(text) {
    if (!text) return "Direct Recruitment";

    const methodMatch = text.match(/(?:5\.\s*Method\s*of\s*appointment|Method\s*of\s*appointment)\s*[:\-]\s*([^\n\r]+)/i);
    if (methodMatch) {
        return methodMatch[1].trim();
    }
    return "Direct Recruitment";
}

/**
 * Master Notification Analyzer
 * Transforms raw text + context into the complete normalized Job schema
 */
function analyzeNotificationDocument(rawText, sourceContext = {}) {
    logger.analyzer("Commencing multi-section document analysis...");

    const title = extractPostName(rawText, sourceContext.rawTitle || "");
    const department = extractDepartment(rawText, sourceContext.department || "");
    const categoryNumber = extractCategoryNumber(rawText, sourceContext.categoryNumber || "");
    const salary = extractScaleOfPay(rawText);
    const vacancy = extractVacancies(rawText);
    const dates = extractGazetteAndLastDates(rawText, sourceContext);
    const methodOfAppointment = extractMethodOfAppointment(rawText);

    // Run deep eligibility & logical condition extraction
    const { eligibility, qualificationLogic } = analyzeEligibility(rawText);

    // Build Selection Process
    const selectionProcess = [methodOfAppointment];
    if (rawText.toLowerCase().includes("written") || rawText.toLowerCase().includes("omr") || rawText.toLowerCase().includes("online examination")) {
        selectionProcess.push("OMR / Written Examination");
    }
    if (rawText.toLowerCase().includes("interview")) {
        selectionProcess.push("Interview");
    }
    selectionProcess.push("Document Verification");

    // Important Dates bundle
    const importantDates = [];
    if (dates.gazetteDate) {
        importantDates.push({
            title: "Gazette Notification Date",
            date: dates.gazetteDate,
            isoDate: normalizeDateIso(dates.gazetteDate),
        });
    }
    if (dates.applicationLastDate && dates.applicationLastDate !== "See Notification") {
        importantDates.push({
            title: "Last Date to Apply Online",
            date: dates.applicationLastDate,
            isoDate: dates.lastDateIso,
        });
    }

    // Standardized Normalized Structure
    const normalizedData = {
        source: {
            name: sourceContext.sourceName || "Kerala PSC",
            website: sourceContext.website || "https://www.keralapsc.gov.in",
            listingUrl: sourceContext.listingUrl || "",
            notificationUrl: sourceContext.notificationUrl || "",
            pdfUrl: sourceContext.pdfUrl || "",
            pdfFilename: sourceContext.pdfFilename || "",
        },

        job: {
            title: title,
            department: department,
            organization: sourceContext.organization || "Kerala Public Service Commission",
            jobType: sourceContext.jobType || "Kerala PSC",
            categoryNumber: categoryNumber,
            notificationNumber: categoryNumber,
            gazetteDate: dates.gazetteDate,
            applicationStartDate: dates.gazetteDate,
            applicationLastDate: dates.applicationLastDate,
            lastDateIso: dates.lastDateIso,
            location: sourceContext.location || "Kerala / Statewide",
            isLive: true,
        },

        vacancy: vacancy,
        salary: salary,
        eligibility: eligibility,
        qualificationLogic: qualificationLogic,
        selectionProcess: selectionProcess,

        application: {
            method: "Online via Kerala PSC Thulasi Portal",
            applyUrl: sourceContext.applyUrl || "https://thulasi.psc.kerala.gov.in/thulasi/",
            fee: "Nil / Free (One Time Registration)",
            documentsRequired: [
                "Kerala PSC OTR Profile ID",
                "10th / SSLC Certificate for Date of Birth",
                "Educational Qualification Certificates & Marksheets",
                "Community / Non-Creamy Layer Certificate (if applicable)",
            ],
        },

        importantDates: importantDates,
        rawText: rawText || "",

        metadata: {
            scrapedAt: new Date(),
            updatedAt: new Date(),
            lastScrapedAt: new Date(),
            parserVersion: "2.0.0",
            analysisVersion: "2.0.0",
        },
    };

    logger.analyzer(`Document analysis completed for post: "${title}" (Cat. No: ${categoryNumber || "N/A"})`);

    return normalizedData;
}

module.exports = {
    extractPostName,
    extractDepartment,
    extractScaleOfPay,
    extractVacancies,
    extractCategoryNumber,
    extractGazetteAndLastDates,
    extractMethodOfAppointment,
    analyzeNotificationDocument,
};
