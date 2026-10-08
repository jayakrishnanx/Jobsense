const mongoose = require("mongoose");

const educationalQualificationSchema = new mongoose.Schema(
    {
        text: { type: String, required: true },
        normalized: { type: String, default: "" },
        level: { type: String, default: "" }, // 10th, 12th, Degree, Post Graduate, Diploma
        discipline: { type: String, default: "" },
        percentage: { type: Number, default: null },
    },
    { _id: false }
);

const experienceRequirementSchema = new mongoose.Schema(
    {
        text: { type: String, required: true },
        minimumYears: { type: Number, default: 0 },
        field: { type: String, default: "" },
        isMandatory: { type: Boolean, default: true },
    },
    { _id: false }
);

const qualificationLogicNodeSchema = new mongoose.Schema(
    {
        operator: {
            type: String,
            enum: ["AND", "OR", "NOT", "ANY_OF", "ALL_OF", "NONE", null],
            default: "OR",
        },
        conditions: [
            {
                type: { type: String, default: "education" }, // education, experience, skill, certificate
                value: { type: String, required: true },
                normalized: { type: String, default: "" },
                minimumYears: { type: Number, default: null },
            },
        ],
    },
    { _id: false }
);

const importantDateSchema = new mongoose.Schema(
    {
        title: { type: String, required: true },
        date: { type: String, required: true },
        isoDate: { type: Date, default: null },
    },
    { _id: false }
);

const jobSchema = new mongoose.Schema(
    {
        // Unique Deduplication Fingerprint (e.g. SHA256 / composite hash)
        fingerprint: {
            type: String,
            unique: true,
            sparse: true,
            index: true,
        },

        // 1. Source Origin Information
        source: {
            name: { type: String, required: true, default: "Government Portal" },
            website: { type: String, default: "" },
            listingUrl: { type: String, default: "" },
            notificationUrl: { type: String, default: "" },
            pdfUrl: { type: String, default: "" },
            pdfFilename: { type: String, default: "" },
        },

        // 2. Standardized Job Info
        job: {
            title: { type: String, default: "", trim: true },
            department: { type: String, default: "General Administration" },
            organization: { type: String, default: "Government Commission", trim: true },
            jobType: { type: String, default: "State Govt" },
            categoryNumber: { type: String, default: "" },
            notificationNumber: { type: String, default: "" },
            gazetteDate: { type: String, default: "" },
            applicationStartDate: { type: String, default: "" },
            applicationLastDate: { type: String, default: "" },
            lastDateIso: { type: Date, default: null },
            location: { type: String, default: "Kerala / Statewide" },
            isLive: { type: Boolean, default: true, index: true },
        },

        // 3. Vacancy Details
        vacancy: {
            number: { type: Number, default: null },
            details: { type: String, default: "As per official notification" },
        },

        // 4. Salary / Pay Scale
        salary: {
            payScale: { type: String, default: "As per Govt Norms" },
            minimumSalary: { type: Number, default: null },
            maximumSalary: { type: Number, default: null },
        },

        // 5. Complete Eligibility Requirements
        eligibility: {
            minimumAge: { type: Number, default: 18 },
            maximumAge: { type: Number, default: 40 },
            ageRelaxation: { type: String, default: "Standard state/central relaxations apply" },
            bornBetween: {
                from: { type: String, default: "" },
                to: { type: String, default: "" },
            },
            educationalQualifications: [educationalQualificationSchema],
            technicalQualifications: [{ type: String }],
            experience: [experienceRequirementSchema],
            skills: [{ type: String }],
            physicalRequirements: [{ type: String }],
            nationality: { type: String, default: "Indian" },
            gender: { type: String, default: "All" },
            communityRestrictions: [{ type: String }],
            otherRequirements: [{ type: String }],
        },

        // 6. Complex Qualification Logic Tree (e.g. Degree OR Diploma AND 2 yrs exp)
        qualificationLogic: qualificationLogicNodeSchema,

        // 7. Selection Process
        selectionProcess: [{ type: String }],

        // 8. Application & Fees
        application: {
            method: { type: String, default: "Online via Official Portal" },
            applyUrl: { type: String, default: "" },
            fee: { type: String, default: "Free / As per notification" },
            documentsRequired: [{ type: String }],
        },

        // 9. Important Dates
        importantDates: [importantDateSchema],

        // 10. Raw Extraction Text & Audit
        rawText: {
            type: String,
            default: "",
        },
        extractionMethod: {
            type: String,
            enum: ["PDF_PARSE", "OCR_TESSERACT", "HTML_DOM", "HYBRID"],
            default: "PDF_PARSE",
        },

        // 11. Pipeline Metadata
        metadata: {
            scrapedAt: { type: Date, default: Date.now },
            updatedAt: { type: Date, default: Date.now },
            lastScrapedAt: { type: Date, default: Date.now },
            parserVersion: { type: String, default: "2.0.0" },
            analysisVersion: { type: String, default: "2.0.0" },
        },

        // Flat backwards-compatible fields for existing Flutter UI screens
        title: { type: String, default: "" },
        organization: { type: String, default: "" },
        department: { type: String, default: "" },
        jobType: { type: String, default: "Kerala PSC" },
        location: { type: String, default: "Kerala" },
        vacancies: { type: String, default: "As per notification" },
        qualification: { type: String, default: "Any Degree" },
        courseRequirements: { type: String, default: "" },
        ageMin: { type: Number, default: 18 },
        ageMax: { type: Number, default: 40 },
        category: { type: String, default: "General / All" },
        experience: { type: String, default: "Fresher eligible" },
        applicationStartDate: { type: String, default: "" },
        lastDate: { type: String, default: "" },
        applicationFee: { type: String, default: "Free" },
        salaryText: { type: String, default: "" },
        description: { type: String, default: "" },
        officialNotificationUrl: { type: String, default: "" },
        applyUrl: { type: String, default: "" },
        documentsRequired: [{ type: String }],
        aiSummary: {
            executiveBrief: { type: String, default: "" },
            keyHighlights: [{ type: String }],
            eligibilityOverview: { type: String, default: "" },
            examPattern: [{ type: String }],
            importantTips: [{ type: String }],
            generatedAt: { type: Date, default: Date.now },
            model: { type: String, default: "JobSense-AI-2.0" },
            isAiGenerated: { type: Boolean, default: false },
        },
        isLive: { type: Boolean, default: true },
        isFeatured: { type: Boolean, default: false },
    },
    {
        timestamps: true,
        toJSON: {
            transform: function (doc, ret) {
                ret.id = ret._id.toString();
                // Synchronize flat fields if nested job exists
                if (ret.job && ret.job.title) {
                    ret.title = ret.title || ret.job.title;
                    ret.organization = ret.organization || ret.job.organization;
                    ret.department = ret.department || ret.job.department;
                    ret.lastDate = ret.lastDate || ret.job.applicationLastDate;
                    ret.jobType = ret.jobType || ret.job.jobType;
                }
                if (ret.source && ret.source.pdfUrl) {
                    ret.officialNotificationUrl = ret.officialNotificationUrl || ret.source.pdfUrl;
                }
                if (ret.application && ret.application.applyUrl) {
                    ret.applyUrl = ret.applyUrl || ret.application.applyUrl;
                }
                delete ret._id;
                delete ret.__v;
                return ret;
            },
        },
    }
);

// Middleware to keep flat helper fields automatically synced before save
jobSchema.pre("save", function () {
    if (this.job) {
        if (this.job.title) this.title = this.job.title;
        if (this.job.organization) this.organization = this.job.organization;
        if (this.job.department) this.department = this.job.department;
        if (this.job.jobType) this.jobType = this.job.jobType;
        if (this.job.location) this.location = this.job.location;
        if (this.job.applicationStartDate) this.applicationStartDate = this.job.applicationStartDate;
        if (this.job.applicationLastDate) this.lastDate = this.job.applicationLastDate;
        this.isLive = this.job.isLive !== undefined ? this.job.isLive : true;
    }
    if (this.vacancy && this.vacancy.details) {
        this.vacancies = this.vacancy.details;
    }
    if (this.salary) {
        this.salaryText = this.salary.payScale || "As per Govt Norms";
    }
    if (this.eligibility) {
        if (this.eligibility.minimumAge) this.ageMin = this.eligibility.minimumAge;
        if (this.eligibility.maximumAge) this.ageMax = this.eligibility.maximumAge;
        if (this.eligibility.educationalQualifications && this.eligibility.educationalQualifications.length > 0) {
            this.qualification = this.eligibility.educationalQualifications.map((e) => e.text || e.normalized).join(", ");
            this.courseRequirements = this.qualification;
        }
        if (this.eligibility.experience && this.eligibility.experience.length > 0) {
            this.experience = this.eligibility.experience.map((e) => e.text).join(", ");
        }
    }
    if (this.source) {
        if (this.source.pdfUrl) this.officialNotificationUrl = this.source.pdfUrl;
    }
    if (this.application) {
        if (this.application.applyUrl) this.applyUrl = this.application.applyUrl;
        if (this.application.fee) this.applicationFee = this.application.fee;
        if (this.application.documentsRequired) this.documentsRequired = this.application.documentsRequired;
    }
    if (this.rawText && !this.description) {
        this.description = this.rawText.slice(0, 500).replace(/\s+/g, " ");
    }
});

jobSchema.index({ "job.title": "text", "job.organization": "text", "job.department": "text" });

module.exports = mongoose.model("Job", jobSchema);
