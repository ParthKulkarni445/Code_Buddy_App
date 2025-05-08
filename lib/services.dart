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

class AuthService {
  void signUpUser({
    required BuildContext context,
    required String email,
    required String password,
    required String handle,
  }) async {
    try {
      User user = User(
        id: '',
        handle: handle,
        password: password,
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
    }
  }

  void signInUser({
    required BuildContext context,
    required String handle,
    required String password,
  }) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signin'),
        body: jsonEncode({
          'handle': handle,
          'password': password,
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
      showAlert(context,'Error', e.toString());
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
        Uri.parse('${Constants.uri}/api/forgot-password'),
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

  /// Resets password; returns true on success
  Future<bool> resetPassword({
    required String email,
    required String verificationCode,
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'verificationCode': verificationCode,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['success'] ?? true)) {
        showAlert(
          context,
          'Success',
          'Password reset successfully!',
        );
        Navigator.of(context).pop();
        return true;
      } else {
        showAlert(context,'Error', data['msg'] ?? 'Failed to reset password');
        return false;
      }
    } catch (e) {
      showAlert(context, 'Error','An error occurred. Please try again.');
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
