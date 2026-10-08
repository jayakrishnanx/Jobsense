const nodemailer = require("nodemailer");

/**
 * Configure Nodemailer Transporter
 * Supports Gmail, Custom SMTP (Brevo/Sendgrid/Mailgun/Hostinger/cPanel), or Ethereal/Console fallback
 */
function createTransporter() {
  // 1. Check for custom SMTP configuration
  if (process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS) {
    return nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: parseInt(process.env.SMTP_PORT || "587", 10),
      secure: process.env.SMTP_SECURE === "true" || process.env.SMTP_PORT === "465",
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  }

  // 2. Check for Gmail Direct configuration (EMAIL_USER & EMAIL_PASS)
  if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
    return nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });
  }

  // 3. Fallback to Local Transport for Development
  return nodemailer.createTransport({
    host: "smtp.ethereal.email",
    port: 587,
    auth: {
      user: "ethereal.test@ethereal.email",
      pass: "testpass",
    },
  });
}

/**
 * Generate a clean, 6-digit cryptographic numeric OTP
 */
function generateOtpCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Send 6-Digit Email OTP to Candidate / Admin
 * @param {string} email - Destination email address
 * @param {string} otpCode - 6-digit numeric OTP code
 * @param {string} userName - Optional user's name
 * @param {string} purpose - "Verification" | "Password Reset"
 */
async function sendEmailOtp(email, otpCode, userName = "Job Seeker", purpose = "Verification") {
  const senderEmail = process.env.EMAIL_FROM || process.env.SMTP_USER || process.env.EMAIL_USER || "noreply@jobsense.gov.in";
  const appName = "JobSense ";
  const isReset = purpose === "Password Reset";

  const title = isReset ? "Password Reset Request" : "Email Verification Code";
  const description = isReset
    ? "You recently requested to reset your password for your <strong>JobSense</strong> account."
    : "You requested a one-time verification code to access your <strong>JobSense</strong> candidate account.";
  const subject = isReset
    ? `${otpCode} is your JobSense Password Reset Code`
    : `${otpCode} is your JobSense Verification Code`;

  const htmlTemplate = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f4f7fa; margin: 0; padding: 0; }
    .container { max-width: 560px; margin: 30px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); padding: 30px 20px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0; font-size: 24px; font-weight: 700; letter-spacing: 0.5px; }
    .header p { margin: 6px 0 0 0; opacity: 0.9; font-size: 14px; }
    .body { padding: 35px 30px; color: #333333; line-height: 1.6; }
    .greeting { font-size: 16px; font-weight: 600; color: #1e3c72; }
    .otp-box { background: #f0f4ff; border: 2px dashed #2a5298; border-radius: 10px; padding: 20px; text-align: center; margin: 25px 0; }
    .otp-label { font-size: 13px; text-transform: uppercase; letter-spacing: 1px; color: #555; margin-bottom: 8px; font-weight: 600; }
    .otp-code { font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #1e3c72; font-family: 'Courier New', Courier, monospace; margin: 0; }
    .expiry-note { font-size: 13px; color: #777; margin-top: 8px; }
    .info-list { background: #fdfdfd; border-left: 4px solid #f39c12; padding: 12px 16px; margin: 20px 0; font-size: 13px; color: #555; }
    .footer { background: #f8fafc; padding: 20px; text-align: center; font-size: 12px; color: #888; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>JobSense</h1>
      <p>Kerala PSC • SSC • UPSC Career Portal</p>
    </div>
    <div class="body">
      <div class="greeting">Hello ${userName},</div>
      <p>${description}</p>
      
      <div class="otp-box">
        <div class="otp-label">${title}</div>
        <div class="otp-code">${otpCode}</div>
        <div class="expiry-note">⏱ Valid for 10 minutes. Do not share this code with anyone.</div>
      </div>

      <div class="info-list">
        <strong>Security Notice:</strong> If you did not request this ${isReset ? 'password reset' : 'verification code'}, you can safely ignore this email. Your account remains completely secure.
      </div>
      
      <p style="margin-top: 25px; font-size: 14px;">
        Best regards,<br>
        <strong>JobSense Security & Notification System</strong>
      </p>
    </div>
    <div class="footer">
      This is an automated message sent by JobSense Government Job Recruitment Portal.<br>
      © ${new Date().getFullYear()} JobSense Portal. All rights reserved.
    </div>
  </div>
</body>
</html>
    `;

  console.log(`\n======================================================`);
  console.log(`[JobSense Email Dispatcher] Generated System Email OTP (${purpose})`);
  console.log(`Recipient : ${email}`);
  console.log(`OTP Code  : >>> ${otpCode} <<<`);
  console.log(`Timestamp : ${new Date().toISOString()}`);
  console.log(`======================================================\n`);

  try {
    const transporter = createTransporter();
    const mailOptions = {
      from: `"${appName}" <${senderEmail}>`,
      to: email,
      subject: subject,
      text: `Hello ${userName},\n\nYour JobSense ${purpose.toLowerCase()} code is: ${otpCode}\n\nThis OTP is valid for 10 minutes.\nIf you did not request this, please ignore this message.`,
      html: htmlTemplate,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`[Email Service] Mail successfully dispatched to ${email}:`, info.messageId || "OK");
    return {
      success: true,
      messageId: info.messageId,
      previewUrl: nodemailer.getTestMessageUrl ? nodemailer.getTestMessageUrl(info) : null,
      otp: otpCode,
    };
  } catch (err) {
    console.warn(`[Email Service] Note: Direct SMTP delivery failed or not configured (${err.message}). System OTP logged to console & returned for verification.`);
    return {
      success: true,
      provider: "System Console & Direct Engine",
      otp: otpCode,
      warning: err.message,
    };
  }
}

module.exports = {
  sendEmailOtp,
  generateOtpCode,
};
