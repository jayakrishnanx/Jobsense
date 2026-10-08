/**
 * Staff Selection Commission (SSC) Scraper Configuration
 */

module.exports = {
    code: "SSC_CR",
    aliases: ["ssc", "ssc_cr", "staff_selection_commission"],
    name: "Staff Selection Commission (Central Region)",
    category: "Central Govt",
    baseUrl: "https://ssccr.gov.in",
    targetUrl: "https://ssccr.gov.in/announcements",
    applyUrl: "https://ssc.gov.in",
    selectors: {
        tableRow: "table[data-slot='table'] tbody tr, table tbody tr, table tr",
        descriptionCell: "td:nth-child(2)",
        fileLink: "a[href*='.pdf'], a[href*='/api/media/file/'], a[download]",
        dateCell: "td:nth-child(4)",
    },
    defaultOrganization: "Staff Selection Commission",
    defaultDepartment: "Government of India (Central Region)",
    timeoutMs: 25000,
};
