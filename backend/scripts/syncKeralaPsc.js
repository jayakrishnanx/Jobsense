const mongoose = require("mongoose");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });
const connectDB = require("../src/config/database");
const { runScraperByCode } = require("../src/services/scraperOrchestrator");
const Job = require("../src/models/job");
const Scraper = require("../src/models/scraper");

async function main() {
    await connectDB();
    console.log("-> Purging all non-Kerala PSC and old dummy jobs from MongoDB...");
    await Job.deleteMany({});
    console.log("-> Cleaned Job collection.");

    console.log("-> Ensuring Kerala PSC is registered in Scrapers collection...");
    await Scraper.findOneAndUpdate(
        { code: "KERALA_PSC" },
        {
            $set: {
                name: "Kerala Public Service Commission",
                code: "KERALA_PSC",
                targetUrl: "https://www.keralapsc.gov.in/notifications",
                category: "Kerala PSC",
                schedule: "Every 2 hours",
                frequencyMinutes: 120,
                status: "active",
                scraperType: "live_web",
            },
        },
        { upsert: true, new: true }
    );

    console.log("-> Triggering live Kerala PSC scraper extraction pipeline...");
    const result = await runScraperByCode("kerala_psc", { maxItems: 10 });
    console.log("-> Scraper finished with status:", result.status);
    console.log(`-> Total Found: ${result.totalFound}, Active Groups: ${result.activeFound}, Processed: ${result.processedCount}, Saved: ${result.newSavedCount}`);

    const finalJobs = await Job.find().sort({ createdAt: -1 });
    console.log(`\n-> Successfully stored ${finalJobs.length} actual Kerala PSC jobs in MongoDB:`);
    finalJobs.forEach((j, idx) => {
        console.log(`   ${idx + 1}. [${j.job?.categoryNumber || "Cat"}] ${j.job?.title || j.title} - ${j.job?.department || j.department}`);
        console.log(`      Scale: ${j.salary?.payScale || j.salaryText || "N/A"} | Last Date: ${j.job?.applicationLastDate || j.lastDate}`);
    });

    process.exit(0);
}

main().catch((err) => {
    console.error("Error running Kerala PSC sync:", err);
    process.exit(1);
});
