const mongoose = require("mongoose");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });
const connectDB = require("../src/config/database");
const Job = require("../src/models/job");
const { generateAiSummary } = require("../src/services/aiSummarizer");

async function main() {
    await connectDB();

    const jobs = await Job.find();
    console.log(`-> Generating AI Summaries for ${jobs.length} jobs in MongoDB...`);

    let count = 0;
    for (const job of jobs) {
        const summary = await generateAiSummary(job, job.rawText || job.description);
        job.aiSummary = summary;
        // Also update description to be the clean executive brief instead of raw dump
        if (summary.executiveBrief) {
            job.description = summary.executiveBrief;
        }
        await job.save();
        count++;
        console.log(`   ✓ [${count}/${jobs.length}] AI Summary generated for: ${job.title}`);
    }

    console.log(`\n-> Successfully generated and saved AI summaries for all ${count} jobs.`);
    process.exit(0);
}

main().catch((err) => {
    console.error("Error generating AI summaries:", err);
    process.exit(1);
});
