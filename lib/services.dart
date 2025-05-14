import 'dart:convert';
import 'dart:math';
import 'package:acex/auth_page.dart';
import 'package:acex/landing_page.dart';
import 'package:acex/models/user.dart';
import 'package:acex/providers/user_provider.dart';
import 'package:acex/utils/constant.dart';
import 'package:acex/utils/secure_storage.dart';
import 'package:acex/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProblemDetails {
  final String title;
  final String statement;
  final String inputSpec;
  final String outputSpec;
  final List<Map<String, String>> examples;

  ProblemDetails({
    required this.title,
    required this.statement,
    required this.inputSpec,
    required this.outputSpec,
    required this.examples,
  });
}

class Club {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final String? bannerUrl;
  final String? avatarUrl;
  final List<String> members;
  final List<String> admins;
  final int memberCount;
  final bool isPublic;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.bannerUrl,
    this.avatarUrl,
    required this.members,
    required this.admins,
    required this.memberCount,
    required this.isPublic,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is DateTime 
              ? json['createdAt'] 
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
      bannerUrl: json['bannerUrl'],
      avatarUrl: json['avatarUrl'],
      members: List<String>.from(json['members'] ?? []),
      admins: List<String>.from(json['admins'] ?? []),
      memberCount: json['memberCount'] ?? 0,
      isPublic: json['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'bannerUrl': bannerUrl,
      'avatarUrl': avatarUrl,
      'members': members,
      'admins': admins,
      'memberCount': memberCount,
      'isPublic': isPublic,
    };
  }
}

class ClubDiscussion {
  final String id;
  final String clubId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int commentCount;
  final int likeCount;

  ClubDiscussion({
    required this.id,
    required this.clubId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.commentCount,
    required this.likeCount,
  });

  factory ClubDiscussion.fromJson(Map<String, dynamic> json) {
    return ClubDiscussion(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is DateTime 
              ? json['createdAt'] 
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
      commentCount: json['commentCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubId': clubId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'commentCount': commentCount,
      'likeCount': likeCount,
    };
  }
}

class ClubProblem {
  final String id;
  final String clubId;
  final String title;
  final String description;
  final String difficulty;
  final int points;
  final String authorId;
  final DateTime createdAt;
  final int solvedCount;

  ClubProblem({
    required this.id,
    required this.clubId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.points,
    required this.authorId,
    required this.createdAt,
    required this.solvedCount,
  });

  factory ClubProblem.fromJson(Map<String, dynamic> json) {
    return ClubProblem(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      points: json['points'] ?? 100,
      authorId: json['authorId'] ?? '',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is DateTime 
              ? json['createdAt'] 
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
      solvedCount: json['solvedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubId': clubId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'points': points,
      'authorId': authorId,
      'createdAt': createdAt.toIso8601String(),
      'solvedCount': solvedCount,
    };
  }
}

class AuthService {
  void signUpUser({
    required BuildContext context,
    required String email,
    required String handle,
    Function? onSuccess,
  }) async {
    try {
      User user = User(
        id: '',
        handle: handle,
        email: email,
        token: '',
      );
      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signup'),
        body: user.toJson(),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {
          showAlert(
            context,
            'Success',
            'Account created! Login with the same credentials!',
          );
        },
      );
    } catch (e) {
      showAlert(context,'Error', e.toString());
    } finally {
      if (onSuccess != null) {
        onSuccess();
      }
    }

  }

  void signInUser({
    required BuildContext context,
    required String handle,
    Function? onSuccess,
  }) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signin'),
        body: jsonEncode({
          'handle': handle,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      print(res.body);
      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          userProvider.setUser(res.body);
          print('This is the token: ${jsonDecode(res.body)['token']}');
          await prefs.setString('x-auth-token', jsonDecode(res.body)['token']);
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LandingPage(),
            ),
            (route) => false,
          );
        },
      );
    } catch (e) {
      showAlert(context,'Error', "Some error occured, please try again later.");
    } finally {
      if (onSuccess != null) {
        onSuccess();
      }
    }
  }

  Future<void> getUserData(
    BuildContext context,
  ) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');

      if (token == null || token.isEmpty) return;

      var tokenRes = await http.post(
        Uri.parse('${Constants.uri}/tokenIsValid'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      var response = jsonDecode(tokenRes.body);

      if (response == true) {
        http.Response userRes = await http.get(
          Uri.parse('${Constants.uri}/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'x-auth-token': token
          },
        );

        userProvider.setUser(userRes.body);
      }
    } catch (e) {
      print(e);
      showAlert(context, 'Error', "Some error occured, please try again later.");
    }
  }

  void signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('x-auth-token', '');
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AuthPage(),
      ),
      (route) => false,
    );
  }

  Future<bool> sendVerificationCode({
    required String email,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['success'] ?? true)) {
        showAlert(
          context,
          'Success',
          'Verification code sent to your email!',
        );
        return true;
      } else {
        showAlert(context, 'Error',data['msg'] ?? 'Failed to send verification code');
        return false;
      }
    } catch (e) {
      showAlert(context,'Error', 'An error occurred. Please try again.');
      return false;
    }
  }

  // Add this to AuthService
Future<bool> validateAuthCode({
  required String email,
  required String code,
  required BuildContext context,
}) async {
  try {
    final res = await http.post(
      Uri.parse('${Constants.uri}/api/validate-auth-code'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'verificationCode': code}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return true;
    } else {
      showAlert(context, 'Error', data['msg'] ?? 'Invalid code');
      return false;
    }
  } catch (e) {
    showAlert(context, 'Error', 'Could not validate code. Please try again.');
    return false;
  }
}
}

class ApiService {
  final String baseUrl =
      'https://codeforces.com/api/'; // Replace with your server's URL if deployed

  Future<ProblemDetails> getProblemDetails(int contestId, String index) async {
    final url = 'https://codeforces.com/problemset/problem/$contestId/$index';

    // This would be your actual API endpoint that runs puppeteer
    // For now, returning mock data
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    return ProblemDetails(
      title: 'Nuetral Tonality',
      statement:
          'Given an array a of n positive integers. In one operation, you can pick any pair of indexes (i,j) such that ai and aj have distinct parity, then replace the smaller one with the sum of them. More formally: \n\nIf ai<aj, replace ai with ai+aj; \nOtherwise, replace aj with ai+aj. \n\nFind the minimum number of operations needed to make all elements of the array have the same parity.',
      inputSpec:
          'The first line contains two integers n and m (1 ≤ n, m ≤ 100) — the number of rows and columns in the matrix.',
      outputSpec:
          'Print "YES" (without quotes) if it is possible to make the matrix beautiful, or "NO" (without quotes) otherwise.',
      examples: [
        {
          'input': '3\n2 1 3',
          'output': '1 2 3',
        },
        {
          'input': '5\n1 2 3 5 4',
          'output': '1 2 3 4 5',
        },
      ],
    );
  }

  Future<List<dynamic>> getContests() async {
    final response =
        await http.get(Uri.parse('https://codeforces.com/api/contest.list'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load contest details');
      }
    } else {
      throw Exception('Failed to load contest details');
    }
  }

  Future<Map<String, dynamic>> getContestDetails(int contestId) async {
    final response = await http.get(Uri.parse(
        'https://codeforces.com/api/contest.standings?contestId=$contestId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load contest details');
      }
    } else {
      throw Exception('Failed to load contest details');
    }
  }

  //getContestRatingChanges
  Future<List<dynamic>> getContestRatingChanges(int contestId) async {
    final response = await http.get(Uri.parse(
        'https://codeforces.com/api/contest.ratingChanges?contestId=$contestId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load contest rating changes');
      }
    } else {
      throw Exception('Failed to load contest rating changes');
    }
  }

  Future<Map<String, dynamic>> getUserStandings(
      int contestId, String handle) async {
    final response = await http.get(Uri.parse(
        'https://codeforces.com/api/contest.standings?contestId=$contestId&handles=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user standings');
      }
    } else {
      throw Exception('Failed to fetch user standings');
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String handle) async {
    final response = await http
        .get(Uri.parse('https://codeforces.com/api/user.info?handles=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'][0];
      } else {
        throw Exception('Failed to fetch user info');
      }
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  Future<List<dynamic>> getRatingHistory(String handle) async {
    final response = await http.get(
        Uri.parse('https://codeforces.com/api/user.rating?handle=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user info 1');
      }
    } else {
      throw Exception('Failed to fetch user info 2');
    }
  }

  Future<List<dynamic>> getSubmissions(String handle) async {
    final response = await http.get(
        Uri.parse('https://codeforces.com/api/user.status?handle=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user info');
      }
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  Future<Map<String, dynamic>> getProblemset() async {
    final response = await http
        .get(Uri.parse('https://codeforces.com/api/problemset.problems'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch problem set');
      }
    } else {
      throw Exception('Failed to fetch problem set');
    }
  }

  String _generateApiSig(
      int time, String methodName, String paramString, String? apiSecret) {
    // Create random string of 6 characters
    final rand = Random().nextInt(900000) +
        100000; // Generates a number between 100000 and 999999

    // Format: rand/methodName?param1=value1&param2=value2#apiSecret
    final strToHash = '$rand/$methodName?$paramString#$apiSecret';

    // Generate SHA512 hash
    final bytes = utf8.encode(strToHash);
    final hash = sha512.convert(bytes);

    return '$rand${hash.toString()}';
  }

  Future<Map<String, dynamic>> getFriendStandings(
      String handle, int contestId) async {
    String? apiKey = await SecureStorageService.readData('api_key');
    String? apiSecret = await SecureStorageService.readData('api_secret');

    const methodName = 'contest.standings';
    final time = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final friendsInfo = await fetchFriends(handle, false);
    final friendsHandles = friendsInfo.join(';');
    final paramString =
        'apiKey=$apiKey&contestId=$contestId&handles=$handle;$friendsHandles&time=$time';
    final apiSig = _generateApiSig(time, methodName, paramString, apiSecret);
    final url = Uri.parse('$baseUrl$methodName?$paramString&apiSig=$apiSig');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch standings');
      }
    } else {
      throw Exception('Failed to fetch standings');
    }
  }

  Future<List<dynamic>> fetchFriends(String handle, bool isOnline) async {
    String? apiKey = await SecureStorageService.readData('api_key');
    String? apiSecret = await SecureStorageService.readData('api_secret');
    const methodName = 'user.friends';
    final time = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    // Create parameter string
    final paramString = 'apiKey=$apiKey&onlyOnline=$isOnline&time=$time';

    // Generate API signature
    final apiSig = _generateApiSig(time, methodName, paramString, apiSecret);
    // Construct full URL with authentication
    final url = Uri.parse('$baseUrl$methodName?$paramString&apiSig=$apiSig');
    final response = await http.get(url);
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load friends list: ${data['comment']}');
      }
    } else {
      throw Exception('Failed to load friends list');
    }
  }

  Future<List<dynamic>> fetchFriendsInfo(String handle, bool isOnline) async {
    final friendList = await fetchFriends(handle, isOnline);
    String friends = friendList.join(';');
    final response = await http.get(Uri.parse(
        'https://codeforces.com/api/user.info?handles=$handle;$friends'));
    //print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user info');
      }
    } else {
      throw Exception('Failed to fetch user info');
    }
  }
}

class ClubService {
  // Create a new club
  Future<String> createClub({
    required BuildContext context,
    required String name,
    required String description,
    String? bannerUrl,
    String? avatarUrl,
    bool isPublic = true,
  }) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');

      final response = await http.post(
        Uri.parse('${Constants.uri}/api/clubs'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'bannerUrl': bannerUrl,
          'avatarUrl': avatarUrl,
          'isPublic': isPublic,
        }),
      );
      print(response.body); 
      String clubId = '';
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          clubId = data['clubId'];
          showAlert(context, 'Success', 'Club created successfully with ID: $clubId');
        },
      );
      return clubId;
    } catch (e) {
      print(e.toString());
      showAlert(context, 'Error', 'Failed to create club');
      return '';
    }
  }
  
  // Get club by ID
  Future<Club?> getClubById(BuildContext context, String clubId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs/$clubId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      
      Club? club;
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          club = Club.fromJson(data['club']);
        },
      );
      return club;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to get club');
      return null; // Return null on error
    }
  }
  
  // Get all clubs
  Future<List<Club>> getAllClubs(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      
      List<Club> clubs = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          final clubsData = data['clubs'] as List<dynamic>;
          clubs = clubsData.map((clubData) => Club.fromJson(clubData)).toList();
        },
      );
      return clubs;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to get clubs');
      return []; // Return empty list on error
    }
  }
  
  // Get clubs for a user
  Future<List<Club>> getUserClubs(BuildContext context, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/users/$userId/clubs'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': await SecureStorageService.readData('x-auth-token') ?? '',
        },
      );
      
      List<Club> clubs = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          final clubsData = data['clubs'] as List<dynamic>;
          clubs = clubsData.map((clubData) => Club.fromJson(clubData)).toList();
        },
      );
      return clubs;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to get user clubs');
      return []; // Return empty list on error
    }
  }
  
  // Join a club
  Future<bool> joinClub(BuildContext context, String clubId) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/join'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': await SecureStorageService.readData('x-auth-token') ?? '',
        },
      );
      
      bool success = false;
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          success = true;
          showAlert(context, 'Success', 'Successfully joined the club');
        },
      );
      return success;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to join club');
      return false; // Return false on error
    }
  }
  
  // Leave a club
  Future<bool> leaveClub(BuildContext context, String clubId) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/leave'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': await SecureStorageService.readData('x-auth-token') ?? '',
        },
      );
      
      bool success = false;
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          success = true;
          showAlert(context, 'Success', 'Successfully left the club');
        },
      );
      return success;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to leave club');
      return false; // Return false on error
    }
  }
  
  // Add a discussion
  Future<String> addDiscussion({
    required BuildContext context,
    required String clubId,
    required String title,
    required String content,
    required String authorName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/discussions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': await SecureStorageService.readData('x-auth-token') ?? '',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'authorName': authorName,
        }),
      );
      
      String discussionId = '';
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          discussionId = data['discussionId'];
        },
      );
      return discussionId;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to add discussion');
      return ''; // Return empty string on error
    }
  }
  
  // Get club discussions
  Future<List<ClubDiscussion>> getClubDiscussions(BuildContext context, String clubId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/discussions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      
      List<ClubDiscussion> discussions = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          final discussionsData = data['discussions'] as List<dynamic>;
          discussions = discussionsData.map((discussionData) => ClubDiscussion.fromJson(discussionData)).toList();
        },
      );
      return discussions;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to get discussions');
      return []; // Return empty list on error
    }
  }
  
  // Add a problem
  Future<String> addProblem({
    required BuildContext context,
    required String clubId,
    required String title,
    required String description,
    required String difficulty,
    required int points,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/problems'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': await SecureStorageService.readData('x-auth-token') ?? '',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'difficulty': difficulty,
          'points': points,
        }),
      );
      
      String problemId = '';
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          problemId = data['problemId'];
        },
      );
      return problemId;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to add problem');
      return ''; // Return empty string on error
    }
  }
  
  // Get club problems
  Future<List<ClubProblem>> getClubProblems(BuildContext context, String clubId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/problems'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      
      List<ClubProblem> problems = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          final problemsData = data['problems'] as List<dynamic>;
          problems = problemsData.map((problemData) => ClubProblem.fromJson(problemData)).toList();
        },
      );
      return problems;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to get problems');
      return []; // Return empty list on error
    }
  }
  
  // Get club leaderboard
  Future<List<Map<String, dynamic>>> getClubLeaderboard(BuildContext context, String clubId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/leaderboard'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      
      List<Map<String, dynamic>> leaderboard = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          leaderboard = List<Map<String, dynamic>>.from(data['leaderboard']);
        },
      );
      return leaderboard;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to get leaderboard');
      return []; // Return empty list on error
    }
  }
  
  // Search clubs
  Future<List<Club>> searchClubs(BuildContext context, String query) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs/search?query=$query'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      
      List<Club> clubs = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          final clubsData = data['clubs'] as List<dynamic>;
          clubs = clubsData.map((clubData) => Club.fromJson(clubData)).toList();
        },
      );
      return clubs;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to search clubs');
      return []; // Return empty list on error
    }
  }
}