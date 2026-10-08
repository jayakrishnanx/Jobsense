/**
 * URL Utility for JobSense
 * Handles resolving relative links, URL cleaning, and document link detection
 */

const { URL } = require("url");
const path = require("path");

/**
 * Resolves a relative or absolute URL against a base URL
 */
function resolveUrl(baseUrl, relativePath) {
    if (!relativePath || typeof relativePath !== "string") return "";
    const cleanRelative = relativePath.trim();
    if (!cleanRelative) return "";

    try {
        // If already absolute URL
        if (cleanRelative.startsWith("http://") || cleanRelative.startsWith("https://")) {
            return cleanRelative;
        }
        if (cleanRelative.startsWith("//")) {
            return `https:${cleanRelative}`;
        }
        const base = new URL(baseUrl);
        const resolved = new URL(cleanRelative, base);
        return resolved.href;
    } catch (e) {
        return cleanRelative;
    }
}

/**
 * Checks whether a URL or link points to a PDF file
 */
function isPdfUrl(urlStr) {
    if (!urlStr || typeof urlStr !== "string") return false;
    const clean = urlStr.trim().toLowerCase();
    return clean.endsWith(".pdf") || clean.includes(".pdf?") || clean.includes("/pdf/") || clean.includes("view_pdf");
}

/**
 * Extracts the filename from a URL
 */
function extractFilename(urlStr) {
    if (!urlStr || typeof urlStr !== "string") return "";
    try {
        const parsed = new URL(urlStr.startsWith("http") ? urlStr : `https://dummy.com/${urlStr}`);
        const basename = path.basename(parsed.pathname);
        return basename || "document.pdf";
    } catch (_) {
        return "document.pdf";
    }
}

module.exports = {
    resolveUrl,
    isPdfUrl,
    extractFilename,
};
