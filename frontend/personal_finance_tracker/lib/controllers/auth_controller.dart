import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:personal_finance_tracker/screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthController extends ChangeNotifier {
  static const String baseUrl =
      'https://finance-tracker-backend-k0f7.onrender.com/api/auth';

  bool isLoading = false;
  String? errorMessage;

  Future<void> register(
    BuildContext context,
    String email,
    String password,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final url = Uri.parse('$baseUrl/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password.trim()}),
      );

      isLoading = false;

      if (!context.mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User registered successfully. Please log in.'),
          ),
        );

        Navigator.pop(context); // Go back to login
      } else {
        final data = jsonDecode(response.body);
        errorMessage = data['message'] ?? 'Registration failed';
      }
    } catch (e) {
      errorMessage = 'Something went wrong';
      isLoading = false;
    }

    notifyListeners();
  }

  Future<void> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password.trim()}),
    );

    isLoading = false;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      final data = jsonDecode(response.body);
      errorMessage = data['message'] ?? 'Login failed';
    }

    notifyListeners();
  }
}
