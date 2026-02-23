import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeto/src/auth/authentication_page.dart';
import 'package:projeto/src/manager/authors/authors_menu.dart';
import 'package:projeto/src/manager/financials/finances_menu.dart';
import 'package:projeto/src/manager/stock/stock_menu.dart';
import 'package:projeto/src/widgets/bottom_navigator_bar.dart';
import 'package:projeto/src/widgets/navigator_helper.dart';

class GestaoMenu extends StatefulWidget {
  final String userId;

  const GestaoMenu({super.key, required this.userId});

  @override
  State<GestaoMenu> createState() => _GestaoMenuState();
}

class _GestaoMenuState extends State<GestaoMenu> {
  int _selectedIndex = 3;

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthenticationPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao terminar sessão: ${e.toString()}')),
      );
    }
  }

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
              'Gestão',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildManagementButton(
              context,
              label: 'Inventário',
              icon: Icons.inventory,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StockMenu(userId: widget.userId),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            _buildManagementButton(
              context,
              label: 'Finanças',
              icon: Icons.attach_money,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FinancesMenu(userId: widget.userId),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            _buildManagementButton(
              context,
              label: 'Autores',
              icon: Icons.person,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthorsMenu()),
                  ),
            ),
            const SizedBox(height: 32),
            Center(child: _buildSignOutButton(context)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigatorBarDefault(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() => _selectedIndex = index);
          NavigationHelper.onItemTapped(context, index, widget.userId);
        },
      ),
    );
  }

  Widget _buildManagementButton(
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

  Widget _buildSignOutButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text(
        'Terminar Sessão',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Terminar Sessão'),
              content: const Text(
                'Tem a certeza que deseja terminar a sessão?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _signOut();
                  },
                  child: const Text(
                    'Sair',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
