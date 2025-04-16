import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/change_password.dart';
import '../auth/forgot_password_screen.dart';
import '../auth/login_screen.dart';
class AuthSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Authentication")),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding for better spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Change Password option (Card style)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Add padding to the ListTile
                leading: Icon(Icons.lock, color: Colors.blueGrey, size: 30),
                title: Text(
                  "Change Password",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => ChangePasswordScreen()));
                },
              ),
            ),
            SizedBox(height: 16), // Space between items

            // Logout option (Card style)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Add padding
                leading: Icon(Icons.exit_to_app, color: Colors.red, size: 30),
                title: Text(
                  "Logout",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
