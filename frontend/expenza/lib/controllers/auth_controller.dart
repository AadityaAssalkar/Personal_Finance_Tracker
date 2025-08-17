import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'transaction_controller.dart';
import 'package:provider/provider.dart';

class AuthController extends ChangeNotifier {
  static const String baseUrl =
      'https://finance-tracker-backend-k0f7.onrender.com/api/auth';

  bool isLoading = false;
  String? errorMessage;
  String? _token;

  String? get token => _token;

  Future<void> loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _token = token;
    notifyListeners();
  }

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<bool> register(String email, String password) async {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        errorMessage = data['message'] ?? 'Registration failed';
      }
    } catch (e) {
      errorMessage = 'Something went wrong';
      isLoading = false;
    }

    notifyListeners();
    return false;
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

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 60));

      isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['accessToken'];

        await _saveToken(token);

        if (!context.mounted) return;
        Provider.of<TransactionController>(context, listen: false)
            .fetchTransactions();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        final data = jsonDecode(response.body);
        errorMessage = data['message'] ?? 'Login failed';
      }
    } catch (e) {
      isLoading = false;
      errorMessage = 'Something went wrong. Please try again.';
    }

    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    notifyListeners();

    if (!context.mounted) return;

    Navigator.pushReplacementNamed(context, '/login');
  }
}
