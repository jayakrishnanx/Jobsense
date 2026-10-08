/**
 * OCR Service for JobSense
 * Handles Optical Character Recognition for image-based or scanned PDFs
 */

const { logger } = require("../../utils/logger");

let tesseract = null;
try {
    tesseract = require("tesseract.js");
} catch (err) {
    logger.warn("OCR", "tesseract.js module not found or unavailable, OCR fallback will be limited.");
}

/**
 * Performs OCR on an image buffer or image path
 * @param {Buffer|string} imageBuffer
 * @param {string} [language='eng']
 * @returns {Promise<string>}
 */
async function performOcr(imageBuffer, language = "eng") {
    if (!tesseract) {
        logger.warn("OCR", "Tesseract is not available for OCR processing");
        return "";
    }

    try {
        logger.ocr("Starting Tesseract OCR recognition cycle...");
        const result = await tesseract.recognize(imageBuffer, language, {
            logger: (m) => {
                if (m.status === "recognizing text" && m.progress % 0.25 === 0) {
                    logger.ocr(`OCR Progress: ${(m.progress * 100).toFixed(0)}%`);
                }
            },
        });

        const text = result?.data?.text || "";
        logger.ocr(`OCR completed successfully. Extracted ${text.length} characters.`);
        return text;
    } catch (err) {
        logger.error("OCR", "Failed to execute Tesseract OCR", err);
        return "";
    }
}

module.exports = {
    performOcr,
};
