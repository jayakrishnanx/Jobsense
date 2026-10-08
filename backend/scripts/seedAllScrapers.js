const mongoose = require("mongoose");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });
const connectDB = require("../src/config/database");
const Scraper = require("../src/models/scraper");

async function main() {
    await connectDB();

    const scrapers = [
        {
            code: "KERALA_PSC",
            name: "Kerala Public Service Commission",
            targetUrl: "https://www.keralapsc.gov.in/notifications",
            category: "Kerala PSC",
            schedule: "Every 2 hours",
            frequencyMinutes: 120,
            status: "active",
            scraperType: "live_web",
            jobsFound: 10,
            lastRunTime: new Date(),
        },
        {
            code: "SSC_CR",
            name: "Staff Selection Commission (Central Region)",
            targetUrl: "https://ssccr.gov.in/announcements",
            category: "Central Govt",
            schedule: "Every 2 hours",
            frequencyMinutes: 120,
            status: "active",
            scraperType: "live_web",
            jobsFound: 7,
            lastRunTime: new Date(),
        },
    ];

    for (const s of scrapers) {
        await Scraper.findOneAndUpdate(
            { code: s.code },
            { $set: s },
            { upsert: true, returnDocument: "after" }
        );
        console.log(`✓ Registered scraper: ${s.name} (${s.code})`);
    }

    console.log("All scrapers seeded successfully.");
    process.exit(0);
}

main().catch((err) => {
    console.error("Error seeding scrapers:", err);
    process.exit(1);
});
