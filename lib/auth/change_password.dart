import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;

  void _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please fill out all fields"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Password updated successfully"),
        backgroundColor: Colors.green,
      ));

      _currentPasswordController.clear();
      _newPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      String message = "Failed to change password";

      if (e.code == 'wrong-password') {
        message = "Current password is incorrect";
      } else if (e.code == 'weak-password') {
        message = "New password is too weak (min 6 characters)";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("An unexpected error occurred"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Change Password"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.blueGrey,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/forget password.png',
                height: 200,
              ),
              SizedBox(height: 20),

              Text(
                "Change your password",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              ),
              SizedBox(height: 5),

              Text(
                "Enter your current password and a new one to update.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: textColor?.withOpacity(0.7)),
              ),
              SizedBox(height: 25),

              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.blueGrey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.blueGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: inputFillColor,
                ),
              ),
              SizedBox(height: 20),

              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  labelText: "New Password",
                  prefixIcon: Icon(Icons.lock, color: Colors.blueGrey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.blueGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: inputFillColor,
                ),
              ),
              SizedBox(height: 20),

              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  "Change Password",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
