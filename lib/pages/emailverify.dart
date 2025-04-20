import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class EmailVerifyPage extends StatefulWidget {
  const EmailVerifyPage({Key? key}) : super(key: key);

  @override
  State<EmailVerifyPage> createState() => _EmailVerifyPageState();
}

class _EmailVerifyPageState extends State<EmailVerifyPage> {
  bool _isEmailVerified = false;
  bool _isSendingVerification = false;
  bool _canResendEmail = true;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
  }

  Future<void> _checkEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    setState(() {
      _isEmailVerified = user?.emailVerified ?? false;
    });

    // If email is verified, navigate to login or main app screen
    if (_isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email verified successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      setState(() {
        _isSendingVerification = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && _canResendEmail) {
        await user.sendEmailVerification();

        setState(() {
          _canResendEmail = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification email sent!")),
        );

        // Enable resending email after a delay (e.g., 30 seconds)
        Future.delayed(const Duration(seconds: 30), () {
          setState(() {
            _canResendEmail = true;
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send email: $e")),
      );
    } finally {
      setState(() {
        _isSendingVerification = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
      ),
      body: Center(
        child: _isEmailVerified
            ? const CircularProgressIndicator() // Redirecting if verified
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "A verification email has been sent to your email address. Please verify your email to access the app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _canResendEmail && !_isSendingVerification
                    ? _sendVerificationEmail
                    : null,
                child: _isSendingVerification
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _checkEmailVerified,
                child: const Text('I have verified my email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
