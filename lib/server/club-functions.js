const express = require("express");
const { db } = require("./firebase");
const auth = require("./tokenverify");
const clubRouter = express.Router();
const clubsCollection = db.collection("clubs");
const admin = require("firebase-admin");

// Create a new club
clubRouter.post("/api/clubs", auth, async (req, res) => {
  try {
    const { name, description, isPublic, bannerUrl, avatarUrl } = req.body;
    const userId = req.user;

    if (!name || name.trim() === '') {
      return res.status(400).json({ success: false, msg: 'Club name is required' });
    }

    // Create club document
    const clubRef = clubsCollection.doc();
    const clubId = clubRef.id;
    
    const clubData = {
      id: clubId,
      name,
      description: description || '',
      createdBy: userId,
      createdAt: new Date(),
      bannerUrl: bannerUrl || null,
      avatarUrl: avatarUrl || null,
      members: [userId],
      admins: [userId],
      memberCount: 1,
      isPublic: isPublic !== false,
    };
    
    await clubRef.set(clubData);
    console.log(clubRef.id);
    // Add club to user's clubs
    await db.collection('users').doc(userId).update({
      clubs: admin.firestore.FieldValue.arrayUnion(clubId),
    });
    
    res.status(200).json({ success: true, clubId });
  } catch (error) {
    console.error('Error creating club:', error);
    res.status(500).json({ success: false, msg: 'Failed to create club' });
  }
});

// Get club by ID
clubRouter.get("/api/clubs/:clubId", async (req, res) => {
  try {
    const { clubId } = req.params;
    const clubDoc = await clubsCollection.doc(clubId).get();
    
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }
    
    res.status(200).json({ success: true, club: { id: clubDoc.id, ...clubDoc.data() } });
  } catch (error) {
    console.error('Error getting club:', error);
    res.status(500).json({ success: false, msg: 'Failed to get club' });
  }
});

// Get all clubs
clubRouter.get("/api/clubs", async (req, res) => {
  try {
    const snapshot = await clubsCollection.get();
    const clubs = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.status(200).json({ success: true, clubs });
  } catch (error) {
    console.error('Error getting all clubs:', error);
    res.status(500).json({ success: false, msg: 'Failed to get clubs' });
  }
});

// Get user's clubs
clubRouter.get("/api/users/:userId/clubs", auth, async (req, res) => {
  try {
    const userId = req.params.userId;
    const snapshot = await clubsCollection
      .where('members', 'array-contains', userId)
      .get();
    
    const clubs = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.status(200).json({ success: true, clubs });
  } catch (error) {
    console.error('Error getting user clubs:', error);
    res.status(500).json({ success: false, msg: 'Failed to get user clubs' });
  }
});

// Join a club
clubRouter.post("/api/clubs/:clubId/join", auth, async (req, res) => {
  try {
    const { clubId } = req.params;
    const userId = req.user;
    
    const clubDoc = await clubsCollection.doc(clubId).get();
    
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }
    
    const clubData = clubDoc.data();
    
    if (!clubData.isPublic) {
      return res.status(400).json({ success: false, msg: 'This club is private' });
    }
    
    if (clubData.members.includes(userId)) {
      return res.status(200).json({ success: true, msg: 'User is already a member of this club' });
    }
    
    await clubsCollection.doc(clubId).update({
      members: db.FieldValue.arrayUnion(userId),
      memberCount: db.FieldValue.increment(1),
    });
    
    await db.collection('users').doc(userId).update({
      clubs: db.FieldValue.arrayUnion(clubId),
    });
    
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error joining club:', error);
    res.status(500).json({ success: false, msg: 'Failed to join club' });
  }
});

// Leave a club
clubRouter.post("/api/clubs/:clubId/leave", auth, async (req, res) => {
  try {
    const { clubId } = req.params;
    const userId = req.user;
    
    const clubDoc = await clubsCollection.doc(clubId).get();
    
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }
    
    const clubData = clubDoc.data();
    
    if (clubData.createdBy === userId) {
      return res.status(400).json({ success: false, msg: 'Club creator cannot leave the club' });
    }
    
    await clubsCollection.doc(clubId).update({
      members: db.FieldValue.arrayRemove(userId),
      admins: db.FieldValue.arrayRemove(userId),
      memberCount: db.FieldValue.increment(-1),
    });
    
    await db.collection('users').doc(userId).update({
      clubs: db.FieldValue.arrayRemove(clubId),
    });
    
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error leaving club:', error);
    res.status(500).json({ success: false, msg: 'Failed to leave club' });
  }
});

// Search clubs
clubRouter.get("/api/clubs/search", async (req, res) => {
  try {
    const { query } = req.query;
    const snapshot = await clubsCollection.get();
    
    const clubs = snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter(club => 
        club.name.toLowerCase().includes(query.toLowerCase()) ||
        club.description.toLowerCase().includes(query.toLowerCase())
      );
    
    res.status(200).json({ success: true, clubs });
  } catch (error) {
    console.error('Error searching clubs:', error);
    res.status(500).json({ success: false, msg: 'Failed to search clubs' });
  }
});

// Add a discussion
clubRouter.post("/api/clubs/:clubId/discussions", auth, async (req, res) => {
  try {
    const { clubId } = req.params;
    const { title, content, authorName } = req.body;
    const authorId = req.user;
    
    if (!title || title.trim() === '') {
      return res.status(400).json({ success: false, msg: 'Discussion title is required' });
    }
    
    const clubDoc = await clubsCollection.doc(clubId).get();
    
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }
    
    const clubData = clubDoc.data();
    
    if (!clubData.members.includes(authorId)) {
      return res.status(400).json({ success: false, msg: 'User is not a member of this club' });
    }
    
    const discussionRef = clubsCollection.doc(clubId).collection('discussions').doc();
    
    const discussionData = {
      id: discussionRef.id,
      clubId,
      title,
      content: content || '',
      authorId,
      authorName,
      createdAt: new Date(),
      commentCount: 0,
      likeCount: 0,
    };
    
    await discussionRef.set(discussionData);
    
    res.status(200).json({ success: true, discussionId: discussionRef.id });
  } catch (error) {
    console.error('Error adding discussion:', error);
    res.status(500).json({ success: false, msg: 'Failed to add discussion' });
  }
});

// Get club discussions
clubRouter.get("/api/clubs/:clubId/discussions", async (req, res) => {
  try {
    const { clubId } = req.params;
    
    const snapshot = await clubsCollection.doc(clubId)
      .collection('discussions')
      .orderBy('createdAt', 'desc')
      .get();
    
    const discussions = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    res.status(200).json({ success: true, discussions });
  } catch (error) {
    console.error('Error getting discussions:', error);
    res.status(500).json({ success: false, msg: 'Failed to get discussions' });
  }
});

// Add a problem
clubRouter.post("/api/clubs/:clubId/problems", auth, async (req, res) => {
  try {
    const { clubId } = req.params;
    const { title, description, difficulty, points } = req.body;
    const authorId = req.user;
    
    if (!title || title.trim() === '') {
      return res.status(400).json({ success: false, msg: 'Problem title is required' });
    }
    
    const clubDoc = await clubsCollection.doc(clubId).get();
    
    if (!clubDoc.exists) {
      return res.status(404).json({ success: false, msg: 'Club not found' });
    }
    
    const clubData = clubDoc.data();
    
    if (!clubData.admins.includes(authorId)) {
      return res.status(400).json({ success: false, msg: 'Only club admins can add problems' });
    }
    
    const problemRef = clubsCollection.doc(clubId).collection('problems').doc();
    
    const problemData = {
      id: problemRef.id,
      clubId,
      title,
      description: description || '',
      difficulty: difficulty || 'medium',
      points: points || 100,
      authorId,
      createdAt: new Date(),
      solvedCount: 0,
    };
    
    await problemRef.set(problemData);
    
    res.status(200).json({ success: true, problemId: problemRef.id });
  } catch (error) {
    console.error('Error adding problem:', error);
    res.status(500).json({ success: false, msg: 'Failed to add problem' });
  }
});

// Get club problems
clubRouter.get("/api/clubs/:clubId/problems", async (req, res) => {
  try {
    const { clubId } = req.params;
    
    const snapshot = await clubsCollection.doc(clubId)
      .collection('problems')
      .orderBy('createdAt', 'desc')
      .get();
    
    const problems = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    res.status(200).json({ success: true, problems });
  } catch (error) {
    console.error('Error getting problems:', error);
    res.status(500).json({ success: false, msg: 'Failed to get problems' });
  }
});

// Get club leaderboard
clubRouter.get("/api/clubs/:clubId/leaderboard", async (req, res) => {
  try {
    const { clubId } = req.params;
    
    const snapshot = await clubsCollection.doc(clubId)
      .collection('leaderboard')
      .orderBy('points', 'desc')
      .get();
    
    const leaderboard = snapshot.docs.map(doc => ({
      userId: doc.id,
      ...doc.data(),
    }));
    
    res.status(200).json({ success: true, leaderboard });
  } catch (error) {
    console.error('Error getting leaderboard:', error);
    res.status(500).json({ success: false, msg: 'Failed to get leaderboard' });
  }
});

module.exports = clubRouter; 