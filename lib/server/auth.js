const express = require("express");
const bcryptjs = require("bcryptjs");
const { db } = require("./firebase");
const jwt = require("jsonwebtoken");
const authRouter = express.Router();
const auth = require("./tokenverify");
const usersCollection = db.collection("users");

// Sign Up
authRouter.post("/api/signup", async (req, res) => {
  try {
    const { handle, email, password } = req.body;

    // Check if user already exists
    const existingUser = await usersCollection.where("email", "==", email).get();
    if (!existingUser.empty) {
      return res.status(400).json({ msg: "User with same email already exists!" });
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
