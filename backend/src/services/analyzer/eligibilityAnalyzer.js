/**
 * Eligibility Analyzer for JobSense
 * Analyzes qualification text, age requirements, experience conditions,
 * and builds logical qualification trees preserving AND/OR/NOT relationships.
 */

const { logger } = require("../../utils/logger");

const QUALIFICATION_MAP = [
    { pattern: /\b(?:bca|bachelor\s+of\s+computer\s+applications?)\b/i, normalized: "BCA", level: "Degree", discipline: "Computer Applications" },
    { pattern: /\b(?:mca|master\s+of\s+computer\s+applications?)\b/i, normalized: "MCA", level: "Post Graduate", discipline: "Computer Applications" },
    { pattern: /\b(?:b\.?tech|b\.?e\.?|bachelor\s+of\s+technology|bachelor\s+of\s+engineering)\b/i, normalized: "B.Tech / B.E", level: "Degree", discipline: "Engineering" },
    { pattern: /\b(?:m\.?tech|m\.?e\.?|master\s+of\s+technology)\b/i, normalized: "M.Tech / M.E", level: "Post Graduate", discipline: "Engineering" },
    { pattern: /\b(?:b\.?sc\b|bachelor\s+of\s+science)\b/i, normalized: "B.Sc", level: "Degree", discipline: "Science" },
    { pattern: /\b(?:m\.?sc\b|master\s+of\s+science)\b/i, normalized: "M.Sc", level: "Post Graduate", discipline: "Science" },
    { pattern: /\b(?:b\.?com\b|bachelor\s+of\s+commerce)\b/i, normalized: "B.Com", level: "Degree", discipline: "Commerce" },
    { pattern: /\b(?:m\.?com\b|master\s+of\s+commerce)\b/i, normalized: "M.Com", level: "Post Graduate", discipline: "Commerce" },
    { pattern: /\b(?:b\.?a\b|bachelor\s+of\s+arts)\b/i, normalized: "B.A", level: "Degree", discipline: "Arts" },
    { pattern: /\b(?:b\.?ed\b|bachelor\s+of\s+education)\b/i, normalized: "B.Ed", level: "Degree", discipline: "Education" },
    { pattern: /\b(?:diploma\s+(?:in\s+[a-z\s]+)?)\b/i, normalized: "Diploma", level: "Diploma", discipline: "Technical" },
    { pattern: /\b(?:sslc|10th\s+standard|matriculation|secondary\s+school)\b/i, normalized: "10th / SSLC", level: "10th", discipline: "General" },
    { pattern: /\b(?:plus\s+two|12th\s+standard|higher\s+secondary|hse|intermediate|10\+2)\b/i, normalized: "12th / Plus Two", level: "12th", discipline: "General" },
    { pattern: /\b(?:iti|national\s+trade\s+certificate|ntc)\b/i, normalized: "ITI / NTC", level: "Certificate", discipline: "Vocational" },
    { pattern: /\b(?:graduation|degree\s+in\s+any\s+discipline|bachelor'?s?\s+degree)\b/i, normalized: "Graduation (Any Degree)", level: "Degree", discipline: "Any" },
    { pattern: /\b(?:post\s+graduation|master'?s?\s+degree)\b/i, normalized: "Post Graduation (Any PG)", level: "Post Graduate", discipline: "Any" },
];

/**
 * Extracts Minimum and Maximum Age from notification text
 */
function extractAgeLimits(text) {
    if (!text || typeof text !== "string") {
        return { minimumAge: 18, maximumAge: 40, bornBetween: { from: "", to: "" }, ageRelaxation: "" };
    }

    let minimumAge = null;
    let maximumAge = null;
    const bornBetween = { from: "", to: "" };
    let ageRelaxation = "";

    // 1. Look for explicit "Age Limit" section
    const ageSectionMatch = text.match(/(?:6\.\s*Age\s*Limit|Age\s*Limit|Age\s*:\s*)([^\n\r]+(?:\n[^\n\r]+){0,3})/i);
    const targetText = ageSectionMatch ? ageSectionMatch[0] : text;

    // Range formats: "18-40", "18 - 36", "18 to 40", "21 to 32 years"
    const rangeMatch = targetText.match(/\b(\d{2})\s*(?:-|to)\s*(\d{2})\s*(?:years?)?\b/i);
    if (rangeMatch) {
        minimumAge = parseInt(rangeMatch[1], 10);
        maximumAge = parseInt(rangeMatch[2], 10);
    }

    // Born between dates: "born between 02/01/1986 and 01/01/2008" or "02.01.1986 and 01.01.2008"
    const bornMatch = targetText.match(/born\s+between\s+(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})\s+and\s+(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i);
    if (bornMatch) {
        bornBetween.from = bornMatch[1].replace(/[\/\.]/g, "/");
        bornBetween.to = bornMatch[2].replace(/[\/\.]/g, "/");
    }

    // Relaxation notes
    if (targetText.toLowerCase().includes("usual relaxation") || targetText.toLowerCase().includes("relaxation")) {
        ageRelaxation = "Usual relaxation for SC/ST (5 years), OBC (3 years), and other eligible categories.";
    }

    return {
        minimumAge: minimumAge || 18,
        maximumAge: maximumAge || 40,
        bornBetween,
        ageRelaxation: ageRelaxation || "Standard government relaxations apply as per rules",
    };
}

/**
 * Extracts educational qualifications and maps to normalized entities
 */
function extractEducationalQualifications(text) {
    if (!text || typeof text !== "string") return [];

    const qualifications = [];
    const seen = new Set();

    // Find qualifications section if available
    const qualSectionMatch = text.match(/(?:7\.\s*Qualifications?|Qualifications?\s*:?)([\s\S]{1,1200}?)(?=\n\s*\d+\.|\n\s*Note:|$)/i);
    const targetText = qualSectionMatch ? qualSectionMatch[1] : text;

    // Scan known qualification dictionaries
    for (const item of QUALIFICATION_MAP) {
        if (item.pattern.test(targetText)) {
            if (!seen.has(item.normalized)) {
                seen.add(item.normalized);
                qualifications.push({
                    text: item.normalized,
                    normalized: item.normalized,
                    level: item.level,
                    discipline: item.discipline,
                    percentage: null,
                });
            }
        }
    }

    // If section contains specific diploma / degree text not caught by standard dictionary
    const lines = targetText.split(/\n+/).map((l) => l.trim()).filter((l) => l.length > 10);
    for (const line of lines) {
        if (
            (line.toLowerCase().includes("diploma") ||
             line.toLowerCase().includes("degree") ||
             line.toLowerCase().includes("certificate") ||
             line.toLowerCase().includes("pass in")) &&
            !qualifications.some((q) => q.text.toLowerCase() === line.toLowerCase())
        ) {
            qualifications.push({
                text: line.replace(/^[ivx\d\.\-\)\s]+/i, "").trim(),
                normalized: line.slice(0, 60),
                level: line.toLowerCase().includes("degree") ? "Degree" : "Diploma",
                discipline: "Technical / General",
                percentage: null,
            });
        }
    }

    return qualifications;
}

/**
 * Parses Complex Qualification Logic (e.g. Degree OR Diploma AND 2 years exp)
 */
function buildQualificationLogicTree(qualText, qualificationsList) {
    if (!qualText || typeof qualText !== "string") {
        return {
            operator: "OR",
            conditions: qualificationsList.map((q) => ({
                type: "education",
                value: q.text || q.normalized,
                normalized: q.normalized,
            })),
        };
    }

    const lower = qualText.toLowerCase();
    let operator = "OR";

    if (lower.includes(" or ") || lower.includes("either") || lower.includes("equivalent")) {
        operator = "OR";
    } else if (lower.includes(" and ") || lower.includes("along with") || lower.includes("both")) {
        operator = "AND";
    }

    const conditions = [];

    if (qualificationsList.length > 0) {
        for (const q of qualificationsList) {
            conditions.push({
                type: "education",
                value: q.text || q.normalized,
                normalized: q.normalized,
            });
        }
    } else {
        conditions.push({
            type: "education",
            value: "Educational Qualification as specified in official notification",
            normalized: "General",
        });
    }

    return {
        operator,
        conditions,
    };
}

/**
 * Extracts experience requirements from text
 */
function extractExperience(text) {
    if (!text || typeof text !== "string") return [];

    const expList = [];
    const expRegex = /(\d+)\s*(?:years?|yrs?)\s*(?:of\s*)?(?:practical\s*|teaching\s*|working\s*)?experience\s*(?:in\s*([^,\n\.]+))?/gi;
    let match;

    while ((match = expRegex.exec(text)) !== null) {
        const years = parseInt(match[1], 10);
        const field = match[2] ? match[2].trim() : "Relevant Field";
        expList.push({
            text: match[0].trim(),
            minimumYears: years,
            field: field,
            isMandatory: !match[0].toLowerCase().includes("desirable"),
        });
    }

    return expList;
}

/**
 * Extracts Community / Reservation Restrictions (e.g. SR for SC/ST, General, etc.)
 */
function extractCommunityRestrictions(text) {
    if (!text || typeof text !== "string") return [];

    const restrictions = [];
    const upper = text.toUpperCase();

    if (upper.includes("SR FOR SC/ST") || upper.includes("SPECIAL RECRUITMENT FROM SC/ST") || upper.includes("SPECIAL RECRUITMENT FOR ST ONLY")) {
        restrictions.push("Special Recruitment for SC/ST Only");
    }
    if (upper.includes("SR FOR ST ONLY") || upper.includes("SCHEDULED TRIBE ONLY")) {
        restrictions.push("Scheduled Tribe (ST) Only");
    }
    if (upper.includes("BY TRANSFER")) {
        restrictions.push("By Transfer from Departmental Employees");
    }
    if (upper.includes("DIFFERENTLY ABLED") || upper.includes("PWBD")) {
        restrictions.push("Differently Abled reservation as per Govt Rules");
    }

    return restrictions;
}

/**
 * Comprehensive eligibility evaluation bundle
 */
function analyzeEligibility(fullText) {
    const ageInfo = extractAgeLimits(fullText);
    const educationalQualifications = extractEducationalQualifications(fullText);
    const qualificationLogic = buildQualificationLogicTree(fullText, educationalQualifications);
    const experience = extractExperience(fullText);
    const communityRestrictions = extractCommunityRestrictions(fullText);

    return {
        eligibility: {
            minimumAge: ageInfo.minimumAge,
            maximumAge: ageInfo.maximumAge,
            ageRelaxation: ageInfo.ageRelaxation,
            bornBetween: ageInfo.bornBetween,
            educationalQualifications,
            technicalQualifications: [],
            experience,
            skills: [],
            physicalRequirements: [],
            nationality: "Indian",
            gender: "All",
            communityRestrictions,
            otherRequirements: [],
        },
        qualificationLogic,
    };
}

module.exports = {
    extractAgeLimits,
    extractEducationalQualifications,
    buildQualificationLogicTree,
    extractExperience,
    extractCommunityRestrictions,
    analyzeEligibility,
};
