import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionController with ChangeNotifier {
  List<dynamic> transactions = [];
  int income = 0;
  int expenses = 0;
  bool isSubmitting = false;
  String? submitError;

  Future<void> fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('https://finance-tracker-backend-k0f7.onrender.com/api/transactions');
    final response = await http.get(
      url,
      headers: {'Authorization': token ?? ''},
    );

    if (response.statusCode == 200) {
      transactions = jsonDecode(response.body);
      _calculateTotals();
      notifyListeners();
    }
  }

  void _calculateTotals() {
    income = 0;
    expenses = 0;

    for (var tx in transactions) {
      final amount = (tx['amount'] as num).toInt();
      if (tx['type'] == 'income') {
        income += amount;
      } else {
        expenses += amount;
      }
    }
  }

  Future<void> submitTransaction({
    required BuildContext context,
    required String type,
    required String category,
    required int amount,
    required DateTime date,
  }) async {
    isSubmitting = true;
    submitError = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('https://finance-tracker-backend-k0f7.onrender.com/api/transactions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token ?? '',
        },
        body: jsonEncode({
          'type': type,
          'category': category,
          'amount': amount,
          'date': date.toIso8601String(),
        }),
      );

      isSubmitting = false;

      if (response.statusCode == 201) {
        await fetchTransactions();
        if (!context.mounted) return;
        Navigator.pop(context); // go back to dashboard
      } else {
        final data = jsonDecode(response.body);
        submitError = data['message'] ?? 'Failed to add transaction';
      }
    } catch (e) {
      submitError = 'Something went wrong';
      isSubmitting = false;
    }

    notifyListeners();
  }

  Future<void> deleteTransaction(
    String id,
    BuildContext context,
    Map<String, dynamic> tx,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('https://finance-tracker-backend-k0f7.onrender.com/api/transactions/$id');
    await http.delete(url, headers: {'Authorization': token ?? ''});
    await fetchTransactions();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => undoDelete(context, tx),
        ),
      ),
    );
  }

  Future<void> undoDelete(BuildContext context, Map<String, dynamic> tx) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('https://finance-tracker-backend-k0f7.onrender.com/api/transactions');
    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
      body: jsonEncode({
        'type': tx['type'],
        'amount': tx['amount'],
        'category': tx['category'],
        'date': tx['date'],
      }),
    );

    await fetchTransactions();
  }
}
