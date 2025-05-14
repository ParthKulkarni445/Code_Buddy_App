const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Club Functions
exports.createClub = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { name, description, isPublic, bannerUrl, avatarUrl } = data;
  const userId = context.auth.uid;

  try {
    // Validate input
    if (!name || name.trim() === '') {
      throw new functions.https.HttpsError('invalid-argument', 'Club name is required');
    }

    // Create club document
    const clubRef = db.collection('clubs').doc();
    const clubId = clubRef.id;
    
    const clubData = {
      id: clubId,
      name,
      description: description || '',
      createdBy: userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      bannerUrl: bannerUrl || null,
      avatarUrl: avatarUrl || null,
      members: [userId],
      admins: [userId],
      memberCount: 1,
      isPublic: isPublic !== false, // Default to true if not specified
    };
    
    await clubRef.set(clubData);
    
    // Add club to user's clubs
    await db.collection('users').doc(userId).update({
      clubs: admin.firestore.FieldValue.arrayUnion(clubId),
    });
    
    return { success: true, clubId };
  } catch (error) {
    console.error('Error creating club:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create club', error);
  }
});

exports.getClubById = functions.https.onCall(async (data, context) => {
  const { clubId } = data;
  
  try {
    const clubDoc = await db.collection('clubs').doc(clubId).get();
    
    if (!clubDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Club not found');
    }
    
    return { success: true, club: { id: clubDoc.id, ...clubDoc.data() } };
  } catch (error) {
    console.error('Error getting club:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get club', error);
  }
});

exports.getAllClubs = functions.https.onCall(async (data, context) => {
  try {
    const snapshot = await db.collection('clubs').get();
    
    const clubs = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    return { success: true, clubs };
  } catch (error) {
    console.error('Error getting all clubs:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get clubs', error);
  }
});

exports.getUserClubs = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = data.userId || context.auth.uid;
  
  try {
    const snapshot = await db.collection('clubs')
      .where('members', 'array-contains', userId)
      .get();
    
    const clubs = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    return { success: true, clubs };
  } catch (error) {
    console.error('Error getting user clubs:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get user clubs', error);
  }
});

exports.joinClub = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { clubId } = data;
  const userId = context.auth.uid;
  
  try {
    // Get club to check if it's public
    const clubDoc = await db.collection('clubs').doc(clubId).get();
    
    if (!clubDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Club not found');
    }
    
    const clubData = clubDoc.data();
    
    if (!clubData.isPublic) {
      throw new functions.https.HttpsError('permission-denied', 'This club is private');
    }
    
    // Check if user is already a member
    if (clubData.members.includes(userId)) {
      return { success: true, message: 'User is already a member of this club' };
    }
    
    // Update club members
    await db.collection('clubs').doc(clubId).update({
      members: admin.firestore.FieldValue.arrayUnion(userId),
      memberCount: admin.firestore.FieldValue.increment(1),
    });
    
    // Add club to user's clubs
    await db.collection('users').doc(userId).update({
      clubs: admin.firestore.FieldValue.arrayUnion(clubId),
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error joining club:', error);
    throw new functions.https.HttpsError('internal', 'Failed to join club', error);
  }
});

exports.leaveClub = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { clubId } = data;
  const userId = context.auth.uid;
  
  try {
    // Get club to check if user is the creator
    const clubDoc = await db.collection('clubs').doc(clubId).get();
    
    if (!clubDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Club not found');
    }
    
    const clubData = clubDoc.data();
    
    if (clubData.createdBy === userId) {
      throw new functions.https.HttpsError('permission-denied', 'Club creator cannot leave the club');
    }
    
    // Update club members
    await db.collection('clubs').doc(clubId).update({
      members: admin.firestore.FieldValue.arrayRemove(userId),
      admins: admin.firestore.FieldValue.arrayRemove(userId),
      memberCount: admin.firestore.FieldValue.increment(-1),
    });
    
    // Remove club from user's clubs
    await db.collection('users').doc(userId).update({
      clubs: admin.firestore.FieldValue.arrayRemove(clubId),
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error leaving club:', error);
    throw new functions.https.HttpsError('internal', 'Failed to leave club', error);
  }
});

exports.searchClubs = functions.https.onCall(async (data, context) => {
  const { query } = data;
  
  try {
    // Firestore doesn't support direct text search, so we'll get all clubs
    // and filter them server-side
    const snapshot = await db.collection('clubs').get();
    
    const clubs = snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter(club => 
        club.name.toLowerCase().includes(query.toLowerCase()) ||
        club.description.toLowerCase().includes(query.toLowerCase())
      );
    
    return { success: true, clubs };
  } catch (error) {
    console.error('Error searching clubs:', error);
    throw new functions.https.HttpsError('internal', 'Failed to search clubs', error);
  }
});

// Discussion Functions
exports.addDiscussion = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { clubId, title, content, authorName } = data;
  const authorId = context.auth.uid;
  
  try {
    // Validate input
    if (!title || title.trim() === '') {
      throw new functions.https.HttpsError('invalid-argument', 'Discussion title is required');
    }
    
    if (!clubId) {
      throw new functions.https.HttpsError('invalid-argument', 'Club ID is required');
    }
    
    // Check if user is a member of the club
    const clubDoc = await db.collection('clubs').doc(clubId).get();
    
    if (!clubDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Club not found');
    }
    
    const clubData = clubDoc.data();
    
    if (!clubData.members.includes(authorId)) {
      throw new functions.https.HttpsError('permission-denied', 'User is not a member of this club');
    }
    
    // Create discussion document
    const discussionRef = db.collection('clubs').doc(clubId).collection('discussions').doc();
    
    const discussionData = {
      id: discussionRef.id,
      clubId,
      title,
      content: content || '',
      authorId,
      authorName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      commentCount: 0,
      likeCount: 0,
    };
    
    await discussionRef.set(discussionData);
    
    return { success: true, discussionId: discussionRef.id };
  } catch (error) {
    console.error('Error adding discussion:', error);
    throw new functions.https.HttpsError('internal', 'Failed to add discussion', error);
  }
});

exports.getClubDiscussions = functions.https.onCall(async (data, context) => {
  const { clubId } = data;
  
  try {
    if (!clubId) {
      throw new functions.https.HttpsError('invalid-argument', 'Club ID is required');
    }
    
    const snapshot = await db.collection('clubs').doc(clubId)
      .collection('discussions')
      .orderBy('createdAt', 'desc')
      .get();
    
    const discussions = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt ? doc.data().createdAt.toDate() : new Date(),
    }));
    
    return { success: true, discussions };
  } catch (error) {
    console.error('Error getting discussions:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get discussions', error);
  }
});

// Problem Functions
exports.addProblem = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { clubId, title, description, difficulty, points } = data;
  const authorId = context.auth.uid;
  
  try {
    // Validate input
    if (!title || title.trim() === '') {
      throw new functions.https.HttpsError('invalid-argument', 'Problem title is required');
    }
    
    if (!clubId) {
      throw new functions.https.HttpsError('invalid-argument', 'Club ID is required');
    }
    
    // Check if user is an admin of the club
    const clubDoc = await db.collection('clubs').doc(clubId).get();
    
    if (!clubDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Club not found');
    }
    
    const clubData = clubDoc.data();
    
    if (!clubData.admins.includes(authorId)) {
      throw new functions.https.HttpsError('permission-denied', 'Only club admins can add problems');
    }
    
    // Create problem document
    const problemRef = db.collection('clubs').doc(clubId).collection('problems').doc();
    
    const problemData = {
      id: problemRef.id,
      clubId,
      title,
      description: description || '',
      difficulty: difficulty || 'medium',
      points: points || 100,
      authorId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      solvedCount: 0,
    };
    
    await problemRef.set(problemData);
    
    return { success: true, problemId: problemRef.id };
  } catch (error) {
    console.error('Error adding problem:', error);
    throw new functions.https.HttpsError('internal', 'Failed to add problem', error);
  }
});

exports.getClubProblems = functions.https.onCall(async (data, context) => {
  const { clubId } = data;
  
  try {
    if (!clubId) {
      throw new functions.https.HttpsError('invalid-argument', 'Club ID is required');
    }
    
    const snapshot = await db.collection('clubs').doc(clubId)
      .collection('problems')
      .orderBy('createdAt', 'desc')
      .get();
    
    const problems = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt ? doc.data().createdAt.toDate() : new Date(),
    }));
    
    return { success: true, problems };
  } catch (error) {
    console.error('Error getting problems:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get problems', error);
  }
});

// Leaderboard Functions
exports.getClubLeaderboard = functions.https.onCall(async (data, context) => {
  const { clubId } = data;
  
  try {
    if (!clubId) {
      throw new functions.https.HttpsError('invalid-argument', 'Club ID is required');
    }
    
    const snapshot = await db.collection('clubs').doc(clubId)
      .collection('leaderboard')
      .orderBy('points', 'desc')
      .get();
    
    const leaderboard = snapshot.docs.map(doc => ({
      userId: doc.id,
      ...doc.data(),
    }));
    
    return { success: true, leaderboard };
  } catch (error) {
    console.error('Error getting leaderboard:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get leaderboard', error);
  }
});