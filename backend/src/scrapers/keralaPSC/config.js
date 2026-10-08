/**
 * Kerala PSC Scraper Configuration
 */

module.exports = {
    code: "KERALA_PSC",
    name: "Kerala Public Service Commission",
    category: "Kerala PSC",
    baseUrl: "https://www.keralapsc.gov.in",
    targetUrl: "https://www.keralapsc.gov.in/notifications",
    applyUrl: "https://thulasi.psc.kerala.gov.in/thulasi/",
    selectors: {
        tableRow: "table tbody tr, table tr",
        gazetteList: "ul li, .views-row, .field-content",
        pdfLink: "a[href*='.pdf'], a[href*='/sites/default/files/']",
    },
    defaultDepartment: "Government of Kerala",
    timeoutMs: 20000,
};
