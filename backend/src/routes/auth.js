const express = require("express");
const router = express.Router();
const User = require("../models/user");
const Admin = require("../models/admin");
const { generateToken, authenticate } = require("../middleware/auth");

/**
 * Helper to seed initial demo accounts if database is fresh
 */
const seedDefaultAccounts = async () => {
    try {
        // Seed default Admin if not exists
        const adminExists = await Admin.findOne({ username: "admin" });
        if (!adminExists) {
            const defaultAdmin = new Admin({
                username: "admin",
                password: "admin123",
                name: "System Administrator",
                email: "admin@jobsense.gov.in",
                role: "Super Administrator",
            });
            await defaultAdmin.save();
            console.log("-> Seeded default admin: admin / admin123");
        }

        // Seed default User (Rahul Sharma) if not exists
        const userExists = await User.findOne({
            $or: [{ phone: "7012823414" }, { username: "rahul" }],
        });
        if (!userExists) {
            const defaultUser = new User({
                username: "rahul",
                password: "rahul123",
                name: "Rahul Sharma",
                phone: "7012823414",
                email: "rahul.sharma@example.com",
                dob: "15/06/2001",
                gender: "Male",
                qualification: "Degree",
                course: "BCA (Computer Applications)",
                yearOfPassing: "2025",
                category: "General",
                state: "Kerala",
                district: "Ernakulam",
            });
            await defaultUser.save();
            console.log("-> Seeded default user: rahul / rahul123 (Phone: 7012823414)");
        }
    } catch (err) {
        console.error("Warning: Failed to seed default accounts:", err.message);
    }
};

/**
 * @route   POST /api/auth/register
 * @desc    Register a new candidate user
 * @access  Public
 */
router.post("/register", async (req, res) => {
    try {
        const {
            name,
            phone,
            email,
            password,
            username,
            dob,
            gender,
            qualification,
            course,
            yearOfPassing,
            category,
            state,
            district,
        } = req.body;

        if (!name || !phone || !email) {
            return res.status(400).json({
                success: false,
                message: "Name, phone number, and email are required.",
            });
        }

        // Check if phone or email is already registered
        const existingPhone = await User.findOne({ phone: phone.trim() });
        if (existingPhone) {
            return res.status(400).json({
                success: false,
                message: "A user with this mobile number already exists.",
            });
        }

        const existingEmail = await User.findOne({ email: email.trim().toLowerCase() });
        if (existingEmail) {
            return res.status(400).json({
                success: false,
                message: "A user with this email address already exists.",
            });
        }

        if (username) {
            const existingUsername = await User.findOne({ username: username.trim().toLowerCase() });
            if (existingUsername) {
                return res.status(400).json({
                    success: false,
                    message: "This username is already taken.",
                });
            }
        }

        // Create new user
        const newUser = new User({
            name: name.trim(),
            phone: phone.trim(),
            email: email.trim().toLowerCase(),
            username: username ? username.trim().toLowerCase() : undefined,
            password: password || undefined,
            dob: dob || "",
            gender: gender || "Male",
            qualification: qualification || "Degree",
            course: course || "",
            yearOfPassing: yearOfPassing || "",
            category: category || "General",
            state: state || "Kerala",
            district: district || "Ernakulam",
            lastLogin: new Date(),
        });

        await newUser.save();

        const token = generateToken({
            id: newUser._id,
            role: "user",
            accountType: "user",
        });

        return res.status(201).json({
            success: true,
            message: "User registered successfully.",
            token,
            user: newUser.toJSON(),
        });
    } catch (error) {
        console.error("Registration error:", error);
        return res.status(500).json({
            success: false,
            message: error.message || "Server error during registration.",
        });
    }
});

/**
 * @route   POST /api/auth/login
 * @desc    Unified login endpoint (handles Admin & User username/password, or phone OTP)
 * @access  Public
 */
router.post("/login", async (req, res) => {
    try {
        const { username, password, phone, otp } = req.body;
        const identifier = (username || req.body.identifier || "").trim();

        // 1. Mobile OTP Login flow
        if (phone && otp) {
            const trimmedPhone = phone.trim();
            // Default demo OTP is 123456
            if (otp !== "123456") {
                return res.status(400).json({
                    success: false,
                    message: "Invalid OTP. For demo/testing use 123456.",
                });
            }

            const user = await User.findOne({ phone: trimmedPhone });
            if (!user) {
                return res.status(200).json({
                    success: true,
                    isNewUser: true,
                    message: "OTP verified. User not found, proceed to registration.",
                });
            }

            user.lastLogin = new Date();
            await user.save();

            const token = generateToken({
                id: user._id,
                role: user.role,
                accountType: "user",
            });

            return res.json({
                success: true,
                role: "user",
                isNewUser: false,
                token,
                user: user.toJSON(),
            });
        }

        // 2. Username / Password Login flow
        if (!identifier || !password) {
            return res.status(400).json({
                success: false,
                message: "Username/Email/Phone and password are required.",
            });
        }

        const lowerIdentifier = identifier.toLowerCase();

        // Check if Admin matches
        const admin = await Admin.findOne({
            $or: [{ username: lowerIdentifier }, { email: lowerIdentifier }],
        }).select("+password");

        if (admin) {
            const isMatch = await admin.comparePassword(password);
            if (isMatch) {
                if (!admin.isActive) {
                    return res.status(403).json({
                        success: false,
                        message: "Admin account has been deactivated.",
                    });
                }

                admin.lastLogin = new Date();
                await admin.save();

                const token = generateToken({
                    id: admin._id,
                    role: admin.role,
                    accountType: "admin",
                });

                return res.json({
                    success: true,
                    role: "admin",
                    token,
                    admin: admin.toJSON(),
                });
            }
        }

        // Check if User matches
        const user = await User.findOne({
            $or: [
                { username: lowerIdentifier },
                { email: lowerIdentifier },
                { phone: identifier },
            ],
        }).select("+password");

        if (user) {
            const isMatch = await user.comparePassword(password);
            if (isMatch) {
                if (user.status !== "active") {
                    return res.status(403).json({
                        success: false,
                        message: "Your account is not active. Please contact support.",
                    });
                }

                user.lastLogin = new Date();
                await user.save();

                const token = generateToken({
                    id: user._id,
                    role: user.role,
                    accountType: "user",
                });

                return res.json({
                    success: true,
                    role: "user",
                    token,
                    user: user.toJSON(),
                });
            }
        }

        return res.status(401).json({
            success: false,
            message: "Invalid username or password. Please verify your credentials.",
        });
    } catch (error) {
        console.error("Login error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error occurred during login.",
        });
    }
});

/**
 * @route   POST /api/auth/send-otp
 * @desc    Simulate sending OTP to phone number
 * @access  Public
 */
router.post("/send-otp", async (req, res) => {
    try {
        const { phone } = req.body;
        if (!phone) {
            return res.status(400).json({
                success: false,
                message: "Phone number is required.",
            });
        }

        const trimmedPhone = phone.trim();
        const user = await User.findOne({ phone: trimmedPhone });

        // In test/demo environment, simulated OTP is 123456
        return res.json({
            success: true,
            message: `OTP sent successfully to +91 ${trimmedPhone}`,
            isExistingUser: !!user,
            testOtp: "123456",
        });
    } catch (error) {
        console.error("Send OTP error:", error);
        return res.status(500).json({
            success: false,
            message: "Error processing OTP request.",
        });
    }
});

/**
 * @route   POST /api/auth/verify-otp
 * @desc    Verify OTP for phone number
 * @access  Public
 */
router.post("/verify-otp", async (req, res) => {
    try {
        const { phone, otp } = req.body;
        if (!phone || !otp) {
            return res.status(400).json({
                success: false,
                message: "Phone number and OTP are required.",
            });
        }

        if (otp !== "123456") {
            return res.status(400).json({
                success: false,
                message: "Invalid OTP code. Use 123456 for testing.",
            });
        }

        const user = await User.findOne({ phone: phone.trim() });
        if (!user) {
            return res.json({
                success: true,
                isNewUser: true,
                message: "OTP verified. New user, proceed to registration.",
            });
        }

        user.lastLogin = new Date();
        await user.save();

        const token = generateToken({
            id: user._id,
            role: user.role,
            accountType: "user",
        });

        return res.json({
            success: true,
            isNewUser: false,
            token,
            user: user.toJSON(),
        });
    } catch (error) {
        console.error("Verify OTP error:", error);
        return res.status(500).json({
            success: false,
            message: "Error verifying OTP.",
        });
    }
});

/**
 * @route   GET /api/auth/me
 * @desc    Get currently authenticated account profile
 * @access  Private (JWT Bearer Token required)
 */
router.get("/me", authenticate, async (req, res) => {
    try {
        const account = req.user || req.admin;
        return res.json({
            success: true,
            accountType: req.accountType,
            data: account.toJSON(),
        });
    } catch (error) {
        console.error("Profile fetch error:", error);
        return res.status(500).json({
            success: false,
            message: "Failed to fetch account details.",
        });
    }
});

/**
 * @route   POST /api/auth/seed
 * @desc    Manual trigger to seed default admin and candidate users
 * @access  Public
 */
router.post("/seed", async (req, res) => {
    try {
        await seedDefaultAccounts();
        return res.json({
            success: true,
            message: "Default demo accounts (admin & rahul) verified/created.",
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message,
        });
    }
});

module.exports = {
    router,
    seedDefaultAccounts,
};
