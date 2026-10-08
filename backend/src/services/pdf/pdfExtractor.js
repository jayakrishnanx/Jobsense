/**
 * PDF Extraction Engine for JobSense
 * Handles downloading, native text extraction, quality assessment, and OCR fallback
 */

const axios = require("axios");
const pdfParse = require("pdf-parse");
const { performOcr } = require("./ocrService");
const { logger } = require("../../utils/logger");

const DEFAULT_HEADERS = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 JobSenseBot/2.0",
    Accept: "application/pdf,application/xhtml+xml,text/html;q=0.9,*/*;q=0.8",
};

/**
 * Downloads a PDF document from a remote URL into a binary Buffer
 * @param {string} pdfUrl
 * @param {number} [timeoutMs=20000]
 * @returns {Promise<{ buffer: Buffer, contentType: string, sizeBytes: number }>}
 */
async function downloadPdfBuffer(pdfUrl, timeoutMs = 20000) {
    if (!pdfUrl || typeof pdfUrl !== "string") {
        throw new Error("Invalid or empty PDF URL");
    }

    logger.pdf(`Downloading document from: ${pdfUrl}`);

    const response = await axios.get(pdfUrl, {
        responseType: "arraybuffer",
        timeout: timeoutMs,
        headers: DEFAULT_HEADERS,
        maxRedirects: 5,
    });

    const buffer = Buffer.from(response.data);
    const contentType = response.headers["content-type"] || "application/pdf";
    const sizeBytes = buffer.length;

    logger.pdf(`Downloaded document: ${(sizeBytes / 1024).toFixed(1)} KB (type: ${contentType})`);

    return { buffer, contentType, sizeBytes };
}

/**
 * Checks if the extracted text meets quality thresholds for structured parsing
 * @param {string} text
 * @returns {boolean}
 */
function assessTextQuality(text) {
    if (!text || typeof text !== "string") return false;
    const clean = text.trim();
    if (clean.length < 80) return false;

    // Check presence of basic recruitment-related keywords
    const keywords = [
        "department", "post", "gazette", "category", "scale", "pay",
        "vacancy", "age", "qualification", "appointment", "application",
        "commission", "date", "kerala", "selection", "kpsc"
    ];
    const lower = clean.toLowerCase();
    const matchedCount = keywords.filter((kw) => lower.includes(kw)).length;

    return matchedCount >= 2;
}

/**
 * Cleans and normalizes extracted raw text
 */
function cleanExtractedText(rawText) {
    if (!rawText || typeof rawText !== "string") return "";
    return rawText
        .replace(/\r\n/g, "\n")
        .replace(/\r/g, "\n")
        .replace(/\t/g, " ")
        .replace(/[\u0000-\u0008\u000B-\u000C\u000E-\u001F]/g, "") // remove non-printable control chars
        .replace(/ +/g, " ")
        .replace(/\n{3,}/g, "\n\n")
        .trim();
}

/**
 * Main Document Extraction Pipeline
 * Extracts text from PDF buffer with automatic OCR fallback if needed
 * @param {Buffer} pdfBuffer
 * @param {string} [pdfUrl]
 * @returns {Promise<{ text: string, numPages: number, method: string, info: object }>}
 */
async function extractTextFromPdf(pdfBuffer, pdfUrl = "") {
    if (!pdfBuffer || !Buffer.isBuffer(pdfBuffer)) {
        throw new Error("Invalid PDF buffer supplied to extractTextFromPdf");
    }

    let extractedText = "";
    let numPages = 1;
    let method = "PDF_PARSE";
    let info = {};

    try {
        logger.pdf("Attempting native PDF text stream parsing...");
        const parsed = await pdfParse(pdfBuffer);
        extractedText = parsed.text || "";
        numPages = parsed.numpages || 1;
        info = parsed.info || {};
        logger.pdf(`Native parse completed. ${numPages} page(s), ${extractedText.length} characters.`);
    } catch (err) {
        logger.warn("PDF", `Native pdf-parse failed: ${err.message}. Will attempt OCR fallback.`);
    }

    const isGoodQuality = assessTextQuality(extractedText);

    // If native text is poor/empty, attempt OCR
    if (!isGoodQuality) {
        logger.pdf("Native extraction insufficient or document is scanned image. Invoking OCR engine...");
        try {
            const ocrText = await performOcr(pdfBuffer);
            if (ocrText && ocrText.length > extractedText.length) {
                extractedText = ocrText;
                method = "OCR_TESSERACT";
                logger.pdf(`OCR extraction successful. Extracted ${ocrText.length} characters.`);
            }
        } catch (ocrErr) {
            logger.error("PDF", "OCR fallback attempt failed", ocrErr);
        }
    }

    const cleaned = cleanExtractedText(extractedText);

    return {
        text: cleaned,
        numPages,
        method,
        info,
        hasContent: cleaned.length >= 30,
    };
}

module.exports = {
    downloadPdfBuffer,
    assessTextQuality,
    cleanExtractedText,
    extractTextFromPdf,
};
