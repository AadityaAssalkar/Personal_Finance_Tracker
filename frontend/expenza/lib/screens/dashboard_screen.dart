import 'package:flutter/material.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/splash_screen.dart';
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
        backgroundColor: const Color(0xFFAF4CAC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildBalanceCard(balance, income, expenses),
                  const SizedBox(height: 20),
                  _buildPieChartSection(
                    income,
                    expenses,
                    incomePercent,
                    expensePercent,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final tx = transactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Slidable(
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
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    child: Card(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: transactions.length),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => const AddTransactionSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard(int balance, int income, int expenses) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              '₹$balance',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountSummary('Income', income, Colors.green),
                _buildAmountSummary('Expenses', expenses, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSection(
    int income,
    int expenses,
    String incomePercent,
    String expensePercent,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            SizedBox(
              width: 180,
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                  sections: (income == 0 && expenses == 0)
                      ? [
                          PieChartSectionData(
                            value: 1,
                            title: '',
                            radius: 45,
                            color: Colors.grey.shade300,
                          ),
                        ]
                      : [
                          PieChartSectionData(
                            value: income.toDouble(),
                            title: '',
                            radius: 45,
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade700,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          PieChartSectionData(
                            value: expenses.toDouble(),
                            title: '',
                            radius: 45,
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade300,
                                Colors.red.shade700,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ],
                ),
              ),
            ),
            if (income == 0 && expenses == 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No transactions yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegend('Savings', incomePercent, Colors.green),
            const SizedBox(height: 12),
            _buildLegend('Expenses', expensePercent, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountSummary(String label, int amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color)),
        const SizedBox(height: 4),
        Text(
          '₹$amount',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, String percent, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 8),
        Text('$label ($percent%)'),
      ],
    );
  }
}
