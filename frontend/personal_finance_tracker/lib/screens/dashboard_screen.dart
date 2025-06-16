import 'package:flutter/material.dart';
import 'package:personal_finance_tracker/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import '../controllers/transaction_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<TransactionController>(
      context,
      listen: false,
    ).fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionController>(context);

    final income = transactionProvider.income;
    final expenses = transactionProvider.expenses;
    final balance = income - expenses;
    final transactions = transactionProvider.transactions;

    final total = (income + expenses);
    final incomePercent = total > 0
        ? (income * 100 / total).toStringAsFixed(1)
        : '0';
    final expensePercent = total > 0
        ? (expenses * 100 / total).toStringAsFixed(1)
        : '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance: ₹$balance', style: const TextStyle(fontSize: 20)),
            Text(
              'Income: ₹$income',
              style: const TextStyle(color: Colors.green),
            ),
            Text(
              'Expenses: ₹$expenses',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Overview Chart',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: income.toDouble(),
                          color: Colors.green,
                          radius: 50,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: expenses.toDouble(),
                          color: Colors.red,
                          radius: 50,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 6,
                        ),
                        const SizedBox(width: 6),
                        Text('Savings ($incomePercent%)'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 6,
                        ),
                        const SizedBox(width: 6),
                        Text('Expenses ($expensePercent%)'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Transactions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return Slidable(
                    key: ValueKey(tx['_id']),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          onPressed: (_) {
                            final controller =
                                Provider.of<TransactionController>(
                                  context,
                                  listen: false,
                                );
                            final backup = Map<String, dynamic>.from(tx);
                            controller.deleteTransaction(
                              tx['_id'],
                              context,
                              backup,
                            );
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text('${tx['category']} - ₹${tx['amount']}'),
                      subtitle: Text(tx['date'].toString().split('T')[0]),
                      trailing: Text(
                        tx['type'],
                        style: TextStyle(
                          color: tx['type'] == 'income'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
