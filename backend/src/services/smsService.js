const axios = require("axios");

/**
 * Real SMS Gateway Service
 * Dispatches physical SMS text messages to mobile phones
 */
async function sendRealSms(phone, otpCode) {
    const cleanedPhone = phone.replace(/\D/g, "").slice(-10);
    const message = `Your JobSense verification OTP is ${otpCode}. Valid for 5 minutes. Do not share this code with anyone.`;

    // 1. FAST2SMS Integration (India)
    const fast2smsKey = (process.env.FAST2SMS_API_KEY || "").trim();
    if (fast2smsKey && fast2smsKey !== "your_fast2sms_api_key_here" && fast2smsKey.length > 5) {
        try {
            // First attempt: OTP Route
            const res = await axios.post(
                "https://www.fast2sms.com/dev/bulkV2",
                {
                    route: "otp",
                    variables_values: otpCode,
                    numbers: cleanedPhone,
                },
                {
                    headers: {
                        authorization: fast2smsKey,
                        "Content-Type": "application/json",
                    },
                    timeout: 10000,
                }
            );

            console.log(`\n✅ [FAST2SMS DISPATCH SUCCESS] +91 ${cleanedPhone} -> Status:`, res.data);
            return { success: true, provider: "Fast2SMS", data: res.data };
        } catch (err) {
            const errorMsg = err.response?.data?.message || err.message;
            console.warn(`[Fast2SMS OTP Route Warning] Trying Quick SMS route...`, errorMsg);

            // Fallback attempt: Quick SMS route
            try {
                const fallbackRes = await axios.post(
                    "https://www.fast2sms.com/dev/bulkV2",
                    {
                        route: "q",
                        message: `Your JobSense verification code is ${otpCode}. Valid for 5 minutes.`,
                        language: "english",
                        numbers: cleanedPhone,
                    },
                    {
                        headers: {
                            authorization: fast2smsKey,
                            "Content-Type": "application/json",
                        },
                        timeout: 10000,
                    }
                );
                console.log(`\n✅ [FAST2SMS QUICK ROUTE SUCCESS] +91 ${cleanedPhone} -> Status:`, fallbackRes.data);
                return { success: true, provider: "Fast2SMS", data: fallbackRes.data };
            } catch (fallbackErr) {
                const detailedError = fallbackErr.response?.data?.message || fallbackErr.message;
                console.error(`[Fast2SMS Notice] Fast2SMS Carrier API requires account activation:`, detailedError);
                return {
                    success: false,
                    provider: "Fast2SMS",
                    message: detailedError,
                };
            }
        }
    }



    // 2. TWILIO Integration (International / India)
    const twilioSid = process.env.TWILIO_ACCOUNT_SID;
    const twilioAuthToken = process.env.TWILIO_AUTH_TOKEN;
    const twilioFromNumber = process.env.TWILIO_PHONE_NUMBER;

    if (twilioSid && twilioAuthToken && twilioFromNumber) {
        try {
            const authHeader = Buffer.from(`${twilioSid}:${twilioAuthToken}`).toString("base64");
            const params = new URLSearchParams();
            params.append("To", `+91${cleanedPhone}`);
            params.append("From", twilioFromNumber);
            params.append("Body", message);

            const res = await axios.post(
                `https://api.twilio.com/2010-04-01/Accounts/${twilioSid}/Messages.json`,
                params.toString(),
                {
                    headers: {
                        Authorization: `Basic ${authHeader}`,
                        "Content-Type": "application/x-www-form-urlencoded",
                    },
                    timeout: 8000,
                }
            );

            console.log(`[Twilio SMS Sent] +91 ${cleanedPhone} -> SID:`, res.data.sid);
            return { success: true, provider: "Twilio", sid: res.data.sid };
        } catch (err) {
            console.error(`[Twilio Error] Failed to send SMS:`, err.response?.data || err.message);
        }
    }

    // 3. 2FACTOR Integration (India)
    const twoFactorKey = process.env.TWO_FACTOR_API_KEY;
    if (twoFactorKey) {
        try {
            const res = await axios.get(
                `https://2factor.in/v3/${twoFactorKey}/SMS/+91${cleanedPhone}/${otpCode}/JobSense`,
                { timeout: 8000 }
            );
            console.log(`[2Factor SMS Sent] +91 ${cleanedPhone} -> Status:`, res.data);
            return { success: true, provider: "2Factor", data: res.data };
        } catch (err) {
            console.error(`[2Factor Error]`, err.response?.data || err.message);
        }
    }

    // If no external SMS gateway API key is configured yet in .env:
    console.log(`\n------------------------------------------------------------`);
    console.log(`ℹ️ [SMS GATEWAY NOTICE] No SMS API key configured in backend/.env`);
    console.log(`📲 Generated Real OTP for +91 ${cleanedPhone}: >>> ${otpCode} <<<`);
    console.log(`💡 To receive real cellular SMS on your physical phone:`);
    console.log(`   Add FAST2SMS_API_KEY=your_key or TWILIO credentials in backend/.env`);
    console.log(`------------------------------------------------------------\n`);

    return {
        success: false,
        provider: "console_fallback",
        message: "SMS Gateway credentials not configured in .env",
    };
}

module.exports = {
    sendRealSms,
};
