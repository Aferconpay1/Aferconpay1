
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the logo
            Image(
              image: AssetImage('assets/afercon.logo.png'),
              width: 150, // Adjust the width as needed
            ),
            SizedBox(height: 24),
            // Display a loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)), // Primary Green
            ),
          ],
        ),
      ),
    );
  }
}
