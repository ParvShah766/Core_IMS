const crypto = require("crypto");

const User = require("../models/User");

const VALID_ROLES = new Set(["inventoryManager", "warehouseStaff"]);

const hashPassword = (password) => {
  return crypto.createHash("sha256").update(password).digest("hex");
};

const sanitizeUser = (user) => {
  return {
    id: user._id,
    fullName: user.fullName,
    email: user.email,
    role: user.role
  };
};

exports.signUp = async (req, res) => {
  try {
    const { fullName, email, password, role } = req.body;

    if (!fullName || !email || !password) {
      return res.status(400).json({ error: "Full name, email, and password are required." });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: "Password must be at least 6 characters." });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const normalizedRole = VALID_ROLES.has(role) ? role : "inventoryManager";

    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(409).json({ error: "Email is already registered." });
    }

    const user = await User.create({
      fullName: fullName.trim(),
      email: normalizedEmail,
      passwordHash: hashPassword(password),
      role: normalizedRole
    });

    return res.status(201).json({
      message: "Account created successfully.",
      user: sanitizeUser(user)
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required." });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });

    if (!user || user.passwordHash !== hashPassword(password)) {
      return res.status(401).json({ error: "Invalid email or password." });
    }

    return res.json({
      message: "Login successful.",
      user: sanitizeUser(user)
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};
const db = require("../config/db");
const generateOTP = require("../utils/generateOTP");
const sendOTPEmail = require("../utils/sendOTPEmail");

exports.requestOTP = async (req, res) => {

  const { email } = req.body;

  const user = await db.query(
    "SELECT * FROM users WHERE email=$1",
    [email]
  );

  if (user.rows.length === 0) {
    return res.status(404).json({ message: "User not found" });
  }

  const otp = generateOTP();

  await db.query(
    "UPDATE users SET otp_code=$1, otp_expiry=NOW() + INTERVAL '5 minutes' WHERE email=$2",
    [otp, email]
  );

  await sendOTPEmail(email, otp);

  res.json({ message: "OTP sent to email" });

};