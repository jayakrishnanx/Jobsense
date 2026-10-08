const jwt = require("jsonwebtoken");
const User = require("../models/user");
const Admin = require("../models/admin");

const JWT_SECRET = process.env.JWT_SECRET || "jobsense_secret_fallback_key";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";

/**
 * Generate a JWT token for a user or admin
 */
const generateToken = (payload) => {
    let cleanPayload = {};
    if (payload && payload._id) {
        cleanPayload = {
            id: payload._id.toString(),
            accountType: payload.role ? "admin" : "user",
            username: payload.username,
        };
    } else if (typeof payload === "object") {
        cleanPayload = { ...payload };
    } else {
        cleanPayload = { id: String(payload) };
    }

    return jwt.sign(cleanPayload, JWT_SECRET, {
        expiresIn: JWT_EXPIRES_IN,
    });
};


/**
 * Middleware to verify JWT token and attach user/admin object
 */
const authenticate = async (req, res, next) => {
    try {
        let token;
        const authHeader = req.headers.authorization;

        if (authHeader && authHeader.startsWith("Bearer ")) {
            token = authHeader.split(" ")[1];
        }

        if (!token) {
            return res.status(401).json({
                success: false,
                message: "Authentication required. No token provided.",
            });
        }

        const decoded = jwt.verify(token, JWT_SECRET);

        if (decoded.accountType === "admin") {
            const admin = await Admin.findById(decoded.id);
            if (!admin || !admin.isActive) {
                return res.status(401).json({
                    success: false,
                    message: "Admin account not found or deactivated.",
                });
            }
            req.admin = admin;
            req.user = null;
            req.accountType = "admin";
        } else {
            const user = await User.findById(decoded.id);
            if (!user || user.status !== "active") {
                return res.status(401).json({
                    success: false,
                    message: "User account not found or inactive.",
                });
            }
            req.user = user;
            req.admin = null;
            req.accountType = "user";
        }

        req.tokenPayload = decoded;
        next();
    } catch (error) {
        if (error.name === "TokenExpiredError") {
            return res.status(401).json({
                success: false,
                message: "Authentication token has expired. Please log in again.",
            });
        }
        return res.status(401).json({
            success: false,
            message: "Invalid authentication token.",
        });
    }
};

/**
 * Middleware restricting access to Admins only
 */
const requireAdmin = (req, res, next) => {
    if (!req.admin || req.accountType !== "admin") {
        return res.status(403).json({
            success: false,
            message: "Access denied. Admin privileges required.",
        });
    }
    next();
};

/**
 * Middleware restricting access to Users only
 */
const requireUser = (req, res, next) => {
    if (!req.user || req.accountType !== "user") {
        return res.status(403).json({
            success: false,
            message: "Access denied. Candidate/user privileges required.",
        });
    }
    next();
};

module.exports = {
    generateToken,
    authenticate,
    requireAdmin,
    requireUser,
};
