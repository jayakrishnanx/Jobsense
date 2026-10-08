const mongoose = require("mongoose");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });
const connectDB = require("../src/config/database");
const { runScraperByCode } = require("../src/services/scraperOrchestrator");
const Job = require("../src/models/job");
const Scraper = require("../src/models/scraper");
const { parseAnnouncementsTable } = require("../src/scrapers/ssc/parser");
const { saveOrUpdateJob } = require("../src/services/jobService");
const { analyzeNotificationDocument } = require("../src/services/analyzer/notificationAnalyzer");
const { logger } = require("../src/utils/logger");

const SAMPLE_SSC_TABLE_HTML = `
<table data-slot="table" class="w-full caption-bottom text-sm"><thead data-slot="table-header" class="[&amp;_tr]:border-b"><tr data-slot="table-row" class="data-[state=selected]:bg-muted border-b transition-colors bg-muted/30 hover:bg-muted/30"><th class="h-15 text-left align-middle font-medium text-muted-foreground w-[5%] px-6 md:px-8">S.No</th><th class="h-15 text-left align-middle font-medium text-muted-foreground w-[55%] px-6 md:px-8">Description</th><th class="h-15 text-left align-middle font-medium text-muted-foreground w-[20%] px-6 md:px-8">Files</th><th class="h-15 text-left align-middle font-medium text-muted-foreground w-[15%] px-6 md:px-8">Post Date</th></tr></thead><tbody data-slot="table-body" class="[&amp;_tr:last-child]:border-0"><tr data-slot="table-row" class="hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors bg-primary/10"><td class="py-2 md:py-3 align-middle px-8 md:px-10 font-medium text-muted-foreground">1</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-foreground/80">Important Notice- Combined Graduate Level Exam 2026</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground"><div class="flex flex-col gap-2"><div class="flex items-center justify-start gap-2 flex-wrap"><a href="/api/media/file/Important%20Notice-%20CGLE%202026-1.pdf" download="" class="text-primary hover:underline"><span>Important Notice- CGLE 2026.pdf</span></a><div class="flex gap-x-1"><span class="text-xs text-muted-foreground">(512.6 KB)</span></div></div></div></td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground">25 Sept 2026</td></tr><tr data-slot="table-row" class="hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors bg-muted/40"><td class="py-2 md:py-3 align-middle px-8 md:px-10 font-medium text-muted-foreground">2</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-foreground/80">Post Code CR13324-JUNIOR ENGINEER(QUALITY ASSURANCE) RADAR &amp; SYSTEM</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground"><div class="flex flex-col gap-2"><div class="flex items-center justify-start gap-2 flex-wrap"><a href="/api/media/file/CR13324%20(1)-1.pdf" download="" class="text-primary hover:underline"><span>CR13324 (1)-1.pdf</span></a><div class="flex gap-x-1"><span class="text-xs text-muted-foreground">(292.3 KB)</span></div></div></div></td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground">25 Sept 2026</td></tr><tr data-slot="table-row" class="hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors bg-primary/10"><td class="py-2 md:py-3 align-middle px-8 md:px-10 font-medium text-muted-foreground">3</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-foreground/80">Post Code CR12624- JUNIOR ENGINEER(QUALITY ASSURANCE) ARMAMENT- SMALL ARMS</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground"><div class="flex flex-col gap-2"><div class="flex items-center justify-start gap-2 flex-wrap"><a href="/api/media/file/CR12624%20(1)-1.pdf" download="" class="text-primary hover:underline"><span>CR12624 (1)-1.pdf</span></a><div class="flex gap-x-1"><span class="text-xs text-muted-foreground">(291.0 KB)</span></div></div></div></td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground">25 Sept 2026</td></tr><tr data-slot="table-row" class="hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors bg-muted/40"><td class="py-2 md:py-3 align-middle px-8 md:px-10 font-medium text-muted-foreground">4</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-foreground/80">Post Code CR12424- JUNIOR ENGINEER(QUALITY ASSURANCE) ARMAMENT, AMMUNITION</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground"><div class="flex flex-col gap-2"><div class="flex items-center justify-start gap-2 flex-wrap"><a href="/api/media/file/CR12424-1.pdf" download="" class="text-primary hover:underline"><span>CR12424-1.pdf</span></a><div class="flex gap-x-1"><span class="text-xs text-muted-foreground">(314.8 KB)</span></div></div></div></td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground">25 Sept 2026</td></tr><tr data-slot="table-row" class="hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors bg-primary/10"><td class="py-2 md:py-3 align-middle px-8 md:px-10 font-medium text-muted-foreground">5</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-foreground/80">Post Code CR11524- PHARMACIST(ALLOPATHIC)</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground"><div class="flex flex-col gap-2"><div class="flex items-center justify-start gap-2 flex-wrap"><a href="/api/media/file/CR11524%20(2)-2.pdf" download="" class="text-primary hover:underline"><span>CR11524 (2)-2.pdf</span></a><div class="flex gap-x-1"><span class="text-xs text-muted-foreground">(279.1 KB)</span></div></div></div></td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground">25 Sept 2026</td></tr><tr data-slot="table-row" class="hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors bg-muted/40"><td class="py-2 md:py-3 align-middle px-8 md:px-10 font-medium text-muted-foreground">6</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-foreground/80">Post Code CR10224- MULTI TASKING STAFF</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground"><div class="flex flex-col gap-2"><div class="flex items-center justify-start gap-2 flex-wrap"><a href="/api/media/file/CR10224%20(1)-3.pdf" download="" class="text-primary hover:underline"><span>CR10224 (1)-3.pdf</span></a><div class="flex gap-x-1"><span class="text-xs text-muted-foreground">(278.2 KB)</span></div></div></div></td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground">25 Sept 2026</td></tr><tr data-slot="table-row" class="hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors bg-primary/10"><td class="py-2 md:py-3 align-middle px-8 md:px-10 font-medium text-muted-foreground">7</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-foreground/80">CR12524- JUNIOR ENGINEER(QUALITY ASSURANCE) ARMAMENT, INSTRUMENT</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground"><div class="flex flex-col gap-2"><div class="flex items-center justify-start gap-2 flex-wrap"><a href="/api/media/file/CR12524%20(1).pdf" download="" class="text-primary hover:underline"><span>CR12524 (1).pdf</span></a><div class="flex gap-x-1"><span class="text-xs text-muted-foreground">(291.6 KB)</span></div></div></div></td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground">19 Aug 2026</td></tr><tr data-slot="table-row" class="hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors bg-muted/40"><td class="py-2 md:py-3 align-middle px-8 md:px-10 font-medium text-muted-foreground">8</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-foreground/80">CR11524- PHARMACIST(ALLO)</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground"><div class="flex flex-col gap-2"><div class="flex items-center justify-start gap-2 flex-wrap"><a href="/api/media/file/CR11524%20(2).pdf" download="" class="text-primary hover:underline"><span>CR11524 (2).pdf</span></a><div class="flex gap-x-1"><span class="text-xs text-muted-foreground">(285.2 KB)</span></div></div></div></td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground">19 Aug 2026</td></tr><tr data-slot="table-row" class="hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors bg-primary/10"><td class="py-2 md:py-3 align-middle px-8 md:px-10 font-medium text-muted-foreground">9</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-foreground/80">CR10224-MULTI TASKING STAFF</td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground"><div class="flex flex-col gap-2"><div class="flex items-center justify-start gap-2 flex-wrap"><a href="/api/media/file/CR10224%20(1).pdf" download="" class="text-primary hover:underline"><span>CR10224 (1).pdf</span></a><div class="flex gap-x-1"><span class="text-xs text-muted-foreground">(277.8 KB)</span></div></div></div></td><td class="py-2 md:py-3 align-middle px-6 md:px-8 text-muted-foreground">19 Aug 2026</td></tr></tbody></table>
`;

async function main() {
    await connectDB();

    console.log("-> Registering Staff Selection Commission (Central Region) in Scraper collection...");
    await Scraper.findOneAndUpdate(
        { code: "SSC_CR" },
        {
            $set: {
                name: "Staff Selection Commission (Central Region)",
                code: "SSC_CR",
                targetUrl: "https://ssccr.gov.in/announcements",
                category: "Central Govt",
                schedule: "Every 2 hours",
                frequencyMinutes: 120,
                status: "active",
                scraperType: "live_web",
            },
        },
        { upsert: true, new: true }
    );

    console.log("-> Parsing SSC Announcements from site structure...");
    const items = parseAnnouncementsTable(SAMPLE_SSC_TABLE_HTML, "https://ssccr.gov.in");
    console.log(`-> Parsed ${items.length} announcements from SSC table.`);

    let savedCount = 0;
    for (const item of items) {
        // Construct notification context for normalization & analysis
        const jobData = analyzeNotificationDocument(
            `STAFF SELECTION COMMISSION (CENTRAL REGION)\nNOTICE: ${item.rawDescription}\nPost Code: ${item.categoryNumber}\nPost Date: ${item.postDate}\nOfficial PDF: ${item.pdfUrl}`,
            {
                sourceName: "Staff Selection Commission",
                website: "https://ssccr.gov.in",
                pdfUrl: item.pdfUrl,
                rawTitle: item.title,
                categoryNumber: item.categoryNumber,
                organization: "Staff Selection Commission",
                department: "Central Region (SSCCR)",
                jobType: "Central Govt",
                location: "All India",
                lastDate: item.postDate,
            }
        );

        jobData.application.applyUrl = "https://ssc.gov.in";
        jobData.job.sourceWebsite = "https://ssccr.gov.in/announcements";

        const res = await saveOrUpdateJob(jobData, { scraperCode: "SSC_CR" });
        if (res.status === "created" || res.status === "updated") {
            savedCount++;
            console.log(`   ✓ [${item.categoryNumber || "SSC"}] ${item.title} -> ${res.status}`);
        }
    }

    const totalJobs = await Job.countDocuments();
    console.log(`\n-> Successfully synced SSC notifications. Total jobs in MongoDB: ${totalJobs}`);
    process.exit(0);
}

main().catch((err) => {
    console.error("Error running SSC sync:", err);
    process.exit(1);
});
