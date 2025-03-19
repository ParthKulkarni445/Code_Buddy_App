import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void showAlert(BuildContext context, String text) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Error', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: Text(text, style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(backgroundColor: Colors.black),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

void httpErrorHandle({
  required http.Response response,
  required BuildContext context,
  required VoidCallback onSuccess,
}) {
  switch (response.statusCode) {
    case 200:
      onSuccess();
      break;
    case 400:
      showAlert(context, " Bad request, please check you are connected to a network.");
      break;
    case 500:
      showAlert(context, "The server is currently down, please try again later.");
      break;
    default:
      showAlert(context, response.body);
  }
}