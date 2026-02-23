import 'package:flutter/material.dart';
import 'package:projeto/src/orders/order_abandoned.dart';
import 'package:projeto/src/orders/order_history.dart';
import 'package:projeto/src/orders/order_pending.dart';
import 'package:projeto/src/orders/order_tester.dart';
import 'package:projeto/src/orders/order_upcoming.dart';
import 'package:projeto/src/widgets/bottom_navigator_bar.dart';
import 'package:projeto/src/widgets/navigator_helper.dart';

class OrdersMenu extends StatefulWidget {
  final String userId;

  const OrdersMenu({super.key, required this.userId});

  @override
  State<OrdersMenu> createState() => _OrdersMenuState();
}

class _OrdersMenuState extends State<OrdersMenu> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.jpeg'),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFFECECEC),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Encomendas',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildOrderButton(
              context,
              label: 'Próximas Encomendas',
              icon: Icons.local_shipping,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderUpcomingPage(userId: widget.userId),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            _buildOrderButton(
              context,
              label: 'Encomendas Abandonadas',
              icon: Icons.cancel,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderAbandonedPage(userId: widget.userId),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            _buildOrderButton(
              context,
              label: 'Histórico de Encomendas',
              icon: Icons.history,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderHistory(userId: widget.userId),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            _buildOrderButton(
              context,
              label: 'Pendentes (Aceitar/Recusar)',
              icon: Icons.pending_actions,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderPendingPage(userId: widget.userId),
                    ),
                  ),
            ),
            const SizedBox(height: 32),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderSeedTester(userId: widget.userId),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Gerar Encomendas de Teste'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigatorBarDefault(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
          NavigationHelper.onItemTapped(context, index, widget.userId);
        },
      ),
    );
  }

  Widget _buildOrderButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
