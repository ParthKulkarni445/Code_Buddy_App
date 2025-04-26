const express = require('express');
const bcryptjs = require('bcryptjs');
const { db } = require('./firebase');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const auth = require('./tokenverify');

const authRouter = express.Router();
const usersCollection = db.collection('users');

// In-memory store for verification codes (swap out for Redis in prod)
const verificationCodes = new Map();

// Helper: validate basic email format
function isValidEmail(email) {
  const re = /^\S+@\S+\.\S+$/;
  return re.test(email);
}

// Forgot-password endpoint
authRouter.post('/api/forgot-password', async (req, res) => {
  try {
    const { EMAIL_USER, EMAIL_PASS } = process.env;
    if (!EMAIL_USER || !EMAIL_PASS) {
      console.error('Missing SMTP credentials');
      return res.status(500).json({ success: false, msg: 'Email service not configured' });
    }

    const { email } = req.body;
    if (!email || !isValidEmail(email.trim())) {
      return res.status(400).json({ success: false, msg: 'Invalid email format' });
    }
    const cleanEmail = email.trim().toLowerCase();

    const userSnapshot = await usersCollection.where('email', '==', cleanEmail).get();
    if (userSnapshot.empty) {
      return res.status(404).json({ success: false, msg: 'Email not found' });
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    verificationCodes.set(cleanEmail, code);

    const transporter = nodemailer.createTransport({
      service: 'Gmail',
      auth: { user: EMAIL_USER, pass: EMAIL_PASS },
    });

    await transporter.sendMail({
      from: EMAIL_USER,
      to: cleanEmail,
      subject: 'Password Reset Verification Code',
      text: `Your verification code is: ${code}`,
    });

    return res.status(200).json({ success: true, msg: 'Verification code sent' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, msg: 'Failed to send verification code' });
  }
});

// Reset-password endpoint
authRouter.post('/api/reset-password', async (req, res) => {
  try {
    const { email, verificationCode, newPassword } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();

    if (!cleanEmail || !isValidEmail(cleanEmail)) {
      return res.status(400).json({ success: false, msg: 'Invalid email format' });
    }
    if (!verificationCode) {
      return res.status(400).json({ success: false, msg: 'Verification code required' });
    }
    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ success: false, msg: 'Password must be at least 6 characters' });
    }

    const stored = verificationCodes.get(cleanEmail);
    if (!stored || stored !== verificationCode) {
      return res.status(400).json({ success: false, msg: 'Invalid or expired verification code' });
    }

    const userSnapshot = await usersCollection.where('email', '==', cleanEmail).get();
    if (userSnapshot.empty) {
      return res.status(404).json({ success: false, msg: 'Email not found' });
    }

    const hashed = await bcryptjs.hash(newPassword, 8);
    await usersCollection.doc(userSnapshot.docs[0].id).update({ password: hashed });

    verificationCodes.delete(cleanEmail);
    return res.status(200).json({ success: true, msg: 'Password reset successfully' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, msg: 'Failed to reset password' });
  }
});

// ... other routes (signup, signin, tokenIsValid, get user) unchanged

module.exports = authRouter;
