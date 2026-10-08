/**
 * JobSense Test Suite Runner
 * Runs unit and integration tests across date parsing, HTML extraction,
 * PDF text analysis, eligibility logic trees, and deduplication.
 */

const { parseDate, normalizeDateIso, isActiveDeadline } = require("../src/utils/dateUtils");
const { parseNotificationsListing, parseGazetteJobLinks } = require("../src/scrapers/keralaPSC/parser");
const { analyzeNotificationDocument } = require("../src/services/analyzer/notificationAnalyzer");
const { analyzeEligibility } = require("../src/services/analyzer/eligibilityAnalyzer");
const { generateJobFingerprint, validateJobData } = require("../src/services/jobService");

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function assert(condition, message) {
    totalTests++;
    if (condition) {
        passedTests++;
        console.log(`  ✓ ${message}`);
    } else {
        failedTests++;
        console.error(`  ✗ FAILED: ${message}`);
    }
}

function runTests() {
    console.log("\n=======================================================");
    console.log("       JobSense Scraper & Analyzer Test Suite          ");
    console.log("=======================================================\n");

    // ----------------------------------------------------
    // TEST SUITE 1: Date Parsing & Deadline Verification
    // ----------------------------------------------------
    console.log("Suite 1: Date Parsing & Deadline Verification");
    {
        const d1 = parseDate("04-11-2026");
        assert(d1 !== null && d1.getUTCFullYear() === 2026 && d1.getUTCMonth() === 10 && d1.getUTCDate() === 4, "Parse DD-MM-YYYY (04-11-2026)");

        const d2 = parseDate("30/09/2026");
        assert(d2 !== null && d2.getUTCFullYear() === 2026 && d2.getUTCMonth() === 8 && d2.getUTCDate() === 30, "Parse DD/MM/YYYY (30/09/2026)");

        const d3 = parseDate("30.09.2026");
        assert(d3 !== null && d3.getUTCFullYear() === 2026 && d3.getUTCDate() === 30, "Parse DD.MM.YYYY (30.09.2026)");

        const d4 = parseDate("4 November 2026");
        assert(d4 !== null && d4.getUTCFullYear() === 2026 && d4.getUTCMonth() === 10, "Parse text date '4 November 2026'");

        const activeCheck = isActiveDeadline("04-11-2026", new Date("2026-10-07"));
        assert(activeCheck === true, "Deadline 04-11-2026 is active on 07-10-2026");

        const expiredCheck = isActiveDeadline("02-09-2026", new Date("2026-10-07"));
        assert(expiredCheck === false, "Deadline 02-09-2026 is expired on 07-10-2026");
    }

    // ----------------------------------------------------
    // TEST SUITE 2: Kerala PSC Listing & Gazette HTML Parsing
    // ----------------------------------------------------
    console.log("\nSuite 2: Kerala PSC HTML Parser");
    {
        const mockListingHtml = `
            <html>
            <body>
                <table>
                    <thead>
                        <tr><th>Title</th><th>Category Number</th><th>Last date</th></tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><a href="/extra-ordinary-gazette-date-30092026">EXTRA ORDINARY GAZETTE DATE 30/09/2026</a></td>
                            <td>CAT.NO.151/2026 TO CAT.NO.161/2026</td>
                            <td>04-11-2026</td>
                        </tr>
                        <tr>
                            <td><a href="/extra-ordinary-gazette-date-30072026">EXTRA ORDINARY GAZETTE DATE 30/07/2026</a></td>
                            <td>CAT.NO : 73/2026 TO CAT.NO : 128/2026</td>
                            <td>02-09-2026</td>
                        </tr>
                    </tbody>
                </table>
            </body>
            </html>
        `;

        const groups = parseNotificationsListing(mockListingHtml, "https://www.keralapsc.gov.in");
        assert(groups.length === 2, "Extracted 2 notification groups from mock listing HTML");
        assert(groups[0].title === "EXTRA ORDINARY GAZETTE DATE 30/09/2026", "Parsed title correctly");
        assert(groups[0].url === "https://www.keralapsc.gov.in/extra-ordinary-gazette-date-30092026", "Resolved URL correctly");
        assert(groups[0].lastDate === "04-11-2026", "Parsed last date correctly");
        assert(groups[0].gazetteDate === "30/09/2026", "Extracted gazette date correctly");

        const mockGazetteHtml = `
            <html>
            <body>
                <div class="field-content">
                    <ul>
                        <li><a href="/sites/default/files/2026-09/noti-151-26.pdf">Draftsman Grade-II - Kerala Ports service (Hydrographic Survey Wing) (Cat.No.151/2026)</a></li>
                        <li><a href="/sites/default/files/2026-09/noti-152-26.pdf">Peon/Watchman (D / R from among the Part-Time employees in KSFE Ltd.) - KSFE (Cat.No.152/2026)</a></li>
                        <li><a href="/sites/default/files/2026-09/noti-153-26.pdf">Forest Boat Driver (Part-I) - Forest & Wildlife (Cat.No.153/2026)</a></li>
                    </ul>
                </div>
            </body>
            </html>
        `;

        const jobs = parseGazetteJobLinks(mockGazetteHtml, "https://www.keralapsc.gov.in/extra-ordinary-gazette-date-30092026", "https://www.keralapsc.gov.in");
        assert(jobs.length === 3, "Extracted 3 individual job links from gazette page");
        assert(jobs[0].pdfUrl === "https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-151-26.pdf", "Extracted direct PDF link correctly");
        assert(jobs[0].categoryNumber === "151/2026", "Extracted category number 151/2026 correctly");
    }

    // ----------------------------------------------------
    // TEST SUITE 3: Document Text Analysis (Kerala PSC Notification PDF)
    // ----------------------------------------------------
    console.log("\nSuite 3: Document Text Analysis (Based on Kerala PSC Sample)");
    {
        const mockPdfText = `
            GAZETTE DATE : 30.09.2026
            LAST DATE : 04.11.2026

            GENERAL RECRUITMENT - STATE WIDE
            CATEGORY NO.151/2026

            Applications are invited Online only from qualified candidates for appointment in the under mentioned post in Kerala Government Service.

            1. Department : Kerala Ports service (Hydrographic Survey Wing)
            2. Name of Post : Draftsman Grade II
            3. Scale of Pay : ₹ 31,100-66,800/-
            4. Number of vacancies : 2 (Two)
            5. Method of appointment : Direct Recruitment
            6. Age Limit : 18 - 40. Only candidates born between 02/01/1986 and 01/01/2008 (both dates included) are eligible to apply for the post with usual relaxation to Scheduled Castes, Scheduled Tribes and Other Backward Communities.
            7. Qualifications :
               Diploma in Civil Engineering or Mechanical Engineering recognized by the Government of Kerala OR Pass in SSLC and National Trade Certificate (NTC) in Draftsman (Civil / Mechanical).
        `;

        const normalized = analyzeNotificationDocument(mockPdfText, {
            sourceName: "Kerala PSC",
            website: "https://www.keralapsc.gov.in",
            pdfUrl: "https://www.keralapsc.gov.in/sites/default/files/2026-09/noti-151-26.pdf",
            rawTitle: "Draftsman Grade-II - Kerala Ports service",
            categoryNumber: "151/2026",
        });

        assert(normalized.job.title === "Draftsman Grade II", `Extracted post name: "${normalized.job.title}"`);
        assert(normalized.job.department === "Kerala Ports service (Hydrographic Survey Wing)", `Extracted department: "${normalized.job.department}"`);
        assert(normalized.job.categoryNumber === "151/2026", `Extracted category number: "${normalized.job.categoryNumber}"`);
        assert(normalized.salary.payScale === "₹ 31,100-66,800/-", `Extracted pay scale: "${normalized.salary.payScale}"`);
        assert(normalized.salary.minimumSalary === 31100 && normalized.salary.maximumSalary === 66800, "Extracted numeric salary bounds");
        assert(normalized.vacancy.number === 2, `Extracted vacancy count: ${normalized.vacancy.number}`);
        assert(normalized.job.applicationLastDate === "04-11-2026", `Extracted deadline date: "${normalized.job.applicationLastDate}"`);
        assert(normalized.eligibility.minimumAge === 18 && normalized.eligibility.maximumAge === 40, "Extracted age limits (18-40)");
        assert(normalized.eligibility.bornBetween.from === "02/01/1986", "Extracted born-between from date");
        assert(normalized.eligibility.bornBetween.to === "01/01/2008", "Extracted born-between to date");
        assert(normalized.eligibility.educationalQualifications.length >= 2, `Extracted ${normalized.eligibility.educationalQualifications.length} educational qualifications`);
        assert(normalized.qualificationLogic.operator === "OR", `Extracted qualification logic operator: "${normalized.qualificationLogic.operator}"`);
    }

    // ----------------------------------------------------
    // TEST SUITE 4: Eligibility Logic & Complex Conditions
    // ----------------------------------------------------
    console.log("\nSuite 4: Complex Eligibility Logic");
    {
        const complexText = `
            Qualifications:
            Bachelor's Degree in Computer Science OR Bachelor's Degree in Computer Applications AND 2 years practical experience in web development.
            Age Limit: 21 to 32 years.
        `;

        const { eligibility, qualificationLogic } = analyzeEligibility(complexText);
        assert(eligibility.minimumAge === 21 && eligibility.maximumAge === 32, "Parsed age range 21-32");
        assert(eligibility.experience.length > 0 && eligibility.experience[0].minimumYears === 2, "Parsed 2 years experience condition");
        assert(qualificationLogic.conditions.length > 0, "Created structured condition tree");
    }

    // ----------------------------------------------------
    // TEST SUITE 5: Deduplication Fingerprint & Validation
    // ----------------------------------------------------
    console.log("\nSuite 5: Deduplication & Validation");
    {
        const jobPayload1 = {
            source: { name: "Kerala PSC", pdfUrl: "https://keralapsc.gov.in/noti-151.pdf" },
            job: { title: "Draftsman Grade II", categoryNumber: "151/2026", organization: "Kerala PSC", applicationLastDate: "04-11-2026" },
        };
        const jobPayload2 = {
            source: { name: "Kerala PSC", pdfUrl: "https://keralapsc.gov.in/noti-151.pdf" },
            job: { title: "Draftsman Grade II", categoryNumber: "151/2026", organization: "Kerala PSC", applicationLastDate: "04-11-2026" },
        };

        const fp1 = generateJobFingerprint(jobPayload1);
        const fp2 = generateJobFingerprint(jobPayload2);

        assert(fp1 === fp2, "Identical jobs produce exact same deduplication fingerprint hash");
        assert(typeof fp1 === "string" && fp1.length === 64, "Fingerprint is valid SHA256 hex string");

        const valValid = validateJobData(jobPayload1);
        assert(valValid.isValid === true, "Valid job payload passes validation");

        const valInvalid = validateJobData({ job: { title: "" } });
        assert(valInvalid.isValid === false && valInvalid.errors.length > 0, "Invalid payload is rejected with clear errors");
    }

    // ----------------------------------------------------
    // TEST SUITE 6: SSC Announcements HTML Parsing & Registry
    // ----------------------------------------------------
    console.log("\nSuite 6: SSC Announcements HTML Parsing & Registry");
    {
        const { parseAnnouncementsTable } = require("../src/scrapers/ssc/parser");
        const registry = require("../src/scrapers/base/ScraperRegistry");
        require("../src/scrapers/ssc/SSCScraper");

        const mockSscTableHtml = `
            <table data-slot="table" class="w-full caption-bottom text-sm">
                <thead data-slot="table-header">
                    <tr data-slot="table-row">
                        <th>S.No</th><th>Description</th><th>Files</th><th>Post Date</th>
                    </tr>
                </thead>
                <tbody data-slot="table-body">
                    <tr data-slot="table-row">
                        <td>1</td>
                        <td>Important Notice- Combined Graduate Level Exam 2026</td>
                        <td>
                            <div>
                                <a href="/api/media/file/Important%20Notice-%20CGLE%202026-1.pdf" download="">
                                    <span>Important Notice- CGLE 2026.pdf</span>
                                </a>
                                <span>(512.6 KB)</span>
                            </div>
                        </td>
                        <td>25 Sept 2026</td>
                    </tr>
                    <tr data-slot="table-row">
                        <td>2</td>
                        <td>Post Code CR13324-JUNIOR ENGINEER(QUALITY ASSURANCE) RADAR &amp; SYSTEM</td>
                        <td>
                            <div>
                                <a href="/api/media/file/CR13324%20(1)-1.pdf" download="">
                                    <span>CR13324 (1)-1.pdf</span>
                                </a>
                                <span>(292.3 KB)</span>
                            </div>
                        </td>
                        <td>25 Sept 2026</td>
                    </tr>
                    <tr data-slot="table-row">
                        <td>6</td>
                        <td>Post Code CR10224- MULTI TASKING STAFF</td>
                        <td>
                            <div>
                                <a href="/api/media/file/CR10224%20(1)-3.pdf" download="">
                                    <span>CR10224 (1)-3.pdf</span>
                                </a>
                                <span>(278.2 KB)</span>
                            </div>
                        </td>
                        <td>25 Sept 2026</td>
                    </tr>
                </tbody>
            </table>
        `;

        const sscItems = parseAnnouncementsTable(mockSscTableHtml, "https://ssccr.gov.in");
        assert(sscItems.length === 3, `Extracted ${sscItems.length} notifications from SSC announcement table`);
        assert(sscItems[0].categoryNumber === "CGL-2026", `Extracted category number for CGL: "${sscItems[0].categoryNumber}"`);
        assert(sscItems[0].pdfUrl === "https://ssccr.gov.in/api/media/file/Important%20Notice-%20CGLE%202026-1.pdf", `Resolved direct PDF link: "${sscItems[0].pdfUrl}"`);
        assert(sscItems[1].categoryNumber === "CR13324", `Extracted post code CR13324: "${sscItems[1].categoryNumber}"`);
        assert(sscItems[1].pdfUrl === "https://ssccr.gov.in/api/media/file/CR13324%20(1)-1.pdf", "Resolved PDF link for CR13324");
        assert(sscItems[2].categoryNumber === "CR10224", `Extracted post code CR10224: "${sscItems[2].categoryNumber}"`);

        // Check registry lookup
        const sscAdapter = registry.get("ssc");
        assert(sscAdapter !== null && typeof sscAdapter === "function", "SSC scraper is registered in ScraperRegistry under 'ssc'");
        const sscCrAdapter = registry.get("ssc_cr");
        assert(sscCrAdapter !== null && typeof sscCrAdapter === "function", "SSC scraper is registered under alias 'ssc_cr'");
    }

    console.log("\n=======================================================");
    console.log(`Test Execution Finished: ${passedTests}/${totalTests} Passed (${failedTests} Failed)`);
    console.log("=======================================================\n");

    return failedTests === 0;
}

if (require.main === module) {
    const success = runTests();
    process.exit(success ? 0 : 1);
}

module.exports = { runTests };
