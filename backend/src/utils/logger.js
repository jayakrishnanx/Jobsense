/**
 * JobSense Structured Logger
 * Standardized logging with subsystem tags
 */

const LogLevel = {
    INFO: "INFO",
    WARN: "WARN",
    ERROR: "ERROR",
    SUCCESS: "SUCCESS",
    DEBUG: "DEBUG",
};

function formatMessage(tag, message, meta = null) {
    const timestamp = new Date().toISOString();
    let logStr = `[${timestamp}] [${tag.toUpperCase()}] ${message}`;
    if (meta) {
        if (meta instanceof Error) {
            logStr += `\n  Stack: ${meta.stack || meta.message}`;
        } else if (typeof meta === "object") {
            logStr += `\n  Details: ${JSON.stringify(meta, null, 2)}`;
        } else {
            logStr += ` (${meta})`;
        }
    }
    return logStr;
}

const logger = {
    scraper: (msg, meta) => console.log(formatMessage("SCRAPER", msg, meta)),
    pdf: (msg, meta) => console.log(formatMessage("PDF", msg, meta)),
    ocr: (msg, meta) => console.log(formatMessage("OCR", msg, meta)),
    analyzer: (msg, meta) => console.log(formatMessage("ANALYZER", msg, meta)),
    database: (msg, meta) => console.log(formatMessage("DATABASE", msg, meta)),
    orchestrator: (msg, meta) => console.log(formatMessage("ORCHESTRATOR", msg, meta)),
    info: (tag, msg, meta) => console.log(formatMessage(tag || "INFO", msg, meta)),
    warn: (tag, msg, meta) => console.warn(formatMessage(tag || "WARN", msg, meta)),
    error: (tag, msg, meta) => console.error(formatMessage(tag || "ERROR", msg, meta)),
};

module.exports = {
    logger,
    LogLevel,
};
