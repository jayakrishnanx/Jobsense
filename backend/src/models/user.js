const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: [true, "Name is required"],
            trim: true,
        },
        phone: {
            type: String,
            required: [true, "Phone number is required"],
            unique: true,
            trim: true,
        },
        email: {
            type: String,
            required: [true, "Email address is required"],
            unique: true,
            lowercase: true,
            trim: true,
            match: [
                /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
                "Please provide a valid email address",
            ],
        },
        username: {
            type: String,
            unique: true,
            sparse: true, // allows multiple documents without a username
            lowercase: true,
            trim: true,
        },
        password: {
            type: String,
            minlength: 6,
            select: false, // Do not return by default in queries
        },
        dob: {
            type: String,
            trim: true,
            default: "",
        },
        gender: {
            type: String,
            enum: ["Male", "Female", "Other", ""],
            default: "Male",
        },
        qualification: {
            type: String,
            trim: true,
            default: "Degree",
        },
        course: {
            type: String,
            trim: true,
            default: "",
        },
        yearOfPassing: {
            type: String,
            trim: true,
            default: "",
        },
        category: {
            type: String,
            trim: true,
            default: "General",
        },
        state: {
            type: String,
            trim: true,
            default: "Kerala",
        },
        district: {
            type: String,
            trim: true,
            default: "Ernakulam",
        },
        role: {
            type: String,
            enum: ["user"],
            default: "user",
        },
        status: {
            type: String,
            enum: ["active", "inactive", "suspended"],
            default: "active",
        },
        savedJobs: [
            {
                type: String, // Job ID reference
            },
        ],
        lastLogin: {
            type: Date,
        },
    },
    {
        timestamps: true,
        toJSON: {
            transform: function (doc, ret) {
                ret.id = ret._id.toString();
                delete ret._id;
                delete ret.__v;
                delete ret.password;
                return ret;
            },
        },
    }
);

// Hash password before saving if modified
userSchema.pre("save", async function () {
    if (!this.isModified("password") || !this.password) return;
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
    if (!this.password) return false;
    return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model("User", userSchema);
