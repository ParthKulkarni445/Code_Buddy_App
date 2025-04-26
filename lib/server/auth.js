const express = require("express");
const bcryptjs = require("bcryptjs");
const { db } = require("./firebase");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");
const authRouter = express.Router();
const auth = require("./tokenverify");
const usersCollection = db.collection("users");

// Temporary storage for verification codes
const verificationCodes = new Map();

// Send Verification Code for Password Reset
authRouter.post("/api/forgot-password", async (req, res) => {
  try {
    // Ensure SMTP credentials are set
    const { EMAIL_USER, EMAIL_PASS } = process.env;
    if (!EMAIL_USER || !EMAIL_PASS) {
      console.error('Missing SMTP credentials');
      return res.status(500).json({ success: false, msg: 'Email service not configured' });
    }

    const { email } = req.body;
    if (!email || !isValidEmail(email.trim())) {
      return res.status(400).json({ success: false, msg: "Invalid email format" });
    }
    const cleanEmail = email.trim().toLowerCase();

    const userSnapshot = await usersCollection.where("email", "==", cleanEmail).get();
    if (userSnapshot.empty) {
      return res.status(404).json({ success: false, msg: "Email not found" });
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    verificationCodes.set(cleanEmail, code);

    // Create transporter with validated credentials
    const transporter = nodemailer.createTransport({
      service: "Gmail",
      auth: { user: EMAIL_USER, pass: EMAIL_PASS },
    });

    await transporter.sendMail({
      from: EMAIL_USER,
      to: cleanEmail,
      subject: "Password Reset Verification Code",
      text: `Your verification code is: ${code}`,
    });

    return res.status(200).json({ success: true, msg: "Verification code sent" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, msg: "Failed to send verification code" });
  }
});

// Reset Password Using Verification Code
authRouter.post("/api/reset-password", async (req, res) => {
  try {
    const { email, verificationCode, newPassword } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();

    if (!cleanEmail || !isValidEmail(cleanEmail)) {
      return res.status(400).json({ success: false, msg: "Invalid email format" });
    }
    if (!verificationCode) {
      return res.status(400).json({ success: false, msg: "Verification code required" });
    }
    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ success: false, msg: "Password must be at least 6 characters" });
    }

    const stored = verificationCodes.get(cleanEmail);
    if (!stored || stored !== verificationCode) {
      return res.status(400).json({ success: false, msg: "Invalid or expired verification code" });
    }

    const userSnapshot = await usersCollection.where("email", "==", cleanEmail).get();
    if (userSnapshot.empty) {
      return res.status(404).json({ success: false, msg: "Email not found" });
    }

    const hashed = await bcryptjs.hash(newPassword, 8);
    await usersCollection.doc(userSnapshot.docs[0].id).update({ password: hashed });

    verificationCodes.delete(cleanEmail);
    return res.status(200).json({ success: true, msg: "Password reset successfully" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, msg: "Failed to reset password" });
  }
});

// Sign Up
authRouter.post("/api/signup", async (req, res) => {
  try {
    const { handle, email, password } = req.body;

    // Check if user already exists
    const existingUser = await usersCollection.where("email", "==", email).get();
    if (!existingUser.empty) {
      return res.status(400).json({ msg: "User with same email already exists!" });
    }

    const existingHandle = await usersCollection.where("handle", "==", handle).get();
    if (!existingHandle.empty) {
      return res.status(400).json({ msg: "User with same handle already exists!" });
    }

    // Hash password
    const hashedPassword = await bcryptjs.hash(password, 8);

    // Create new user in Firestore
    const newUserRef = usersCollection.doc();
    await newUserRef.set({
      handle,
      email,
      password: hashedPassword,
    });

    res.json({ id: newUserRef.id, handle, email });
  } catch (e) {
    print(e);
    res.status(500).json({ error: e.message });
  }
});

// Sign In
authRouter.post("/api/signin", async (req, res) => {
  try {
    const { handle, password } = req.body;

    // Find user by handle
    const userSnapshot = await usersCollection.where("handle", "==", handle).get();
    if (userSnapshot.empty) {
      return res.status(400).json({ msg: "User with this handle does not exist!" });
    }

    // Get user data
    const userDoc = userSnapshot.docs[0];
    const user = userDoc.data();

    // Compare passwords
    const isMatch = await bcryptjs.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ msg: "Incorrect password." });
    }

    // Generate JWT token
    const token = jwt.sign({ id: userDoc.id }, "passwordKey");
    res.json({ token, id: userDoc.id, handle: user.handle, email: user.email });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Token Validation
authRouter.post("/tokenIsValid", async (req, res) => {
  try {
    const token = req.header("x-auth-token");
    if (!token) return res.json(false);

    const verified = jwt.verify(token, "passwordKey");
    if (!verified) return res.json(false);

    const userRef = usersCollection.doc(verified.id);
    const user = await userRef.get();

    if (!user.exists) return res.json(false);

    res.json(true);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get User Data
authRouter.get("/", auth, async (req, res) => {
  try {
    const userRef = usersCollection.doc(req.user);
    const userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      return res.status(404).json({ msg: "User not found" });
    }

    const user = userSnapshot.data();
    res.json({ id: userRef.id, ...user, token: req.token });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = authRouter;
