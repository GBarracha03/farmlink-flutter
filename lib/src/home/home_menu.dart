import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto/src/notifications/notifications_menu.dart';
import 'package:projeto/src/profile/profile_menu.dart';
import 'package:projeto/src/widgets/navigator_helper.dart';
import '../widgets/bottom_navigator_bar.dart';
import 'package:light/light.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key, required this.userId});

  final String userId;

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  int _selectedIndex = 0;
  StreamSubscription<int>? _subscription;
  int? light;
  String? _userName;
  int _totalOrders = 0;
  int _acceptedOrders = 0;
  int _pendingOrders = 0;
  List<Map<String, dynamic>> _myAds = [];

  @override
  void initState() {
    super.initState();
    _initLightSensor();
    _fetchUserName();
    _fetchOrderStats();
    _fetchMyAds();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchMyAds() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('advertisements')
            .where('userId', isEqualTo: widget.userId)
            .get();

    setState(() {
      _myAds = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _fetchOrderStats() async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('producerId', isEqualTo: widget.userId)
              .get();

      setState(() {
        _acceptedOrders =
            query.docs
                .where(
                  (doc) => doc['status']?.toString().toLowerCase() == 'aceito',
                )
                .length;

        _pendingOrders =
            query.docs
                .where(
                  (doc) =>
                      doc['status']?.toString().toLowerCase() == 'pendente',
                )
                .length;

        _totalOrders =
            query.docs
                .where(
                  (doc) =>
                      doc['status']?.toString().toLowerCase() == 'entregue',
                )
                .length;
      });
    } catch (e) {
      debugPrint('Erro ao buscar estatísticas: $e');
      setState(() {
        _acceptedOrders = 0;
        _pendingOrders = 0;
        _totalOrders = 0;
      });
    }
  }

  Future<void> _fetchUserName() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(widget.userId)
              .get();

      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'Utilizador';
        });
      } else {
        setState(() {
          _userName = 'Utilizador';
        });
      }
    } catch (e) {
      setState(() {
        _userName = 'Erro ao carregar';
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia 👋';
    if (hour < 18) return 'Boa tarde 👋';
    return 'Boa noite 🌙';
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _userName ?? 'Carregando...',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(
          'Entregues',
          '$_totalOrders',
          Icons.check_circle_outline,
        ),
        _buildStatCard('Por entregar', '$_acceptedOrders', Icons.shopping_bag),
        _buildStatCard('Pendentes', '$_pendingOrders', Icons.hourglass_top),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightResponseWidget() {
    if (light == null) {
      return const Text("Sensor de luz indisponível no dispositivo.");
    }

    const veryDark = 10;
    const dark = 50;
    const normal = 1000;
    const bright = 5000;

    IconData icon;
    Color iconColor;
    String message;

    if (light! < veryDark) {
      icon = Icons.dark_mode;
      iconColor = Colors.indigo;
      message = 'Ambiente muito escuro';
    } else if (light! < dark) {
      icon = Icons.bedtime;
      iconColor = Colors.blueGrey;
      message = 'Luz baixa – cuidado com os olhos';
    } else if (light! < normal) {
      icon = Icons.lightbulb;
      iconColor = Colors.amber;
      message = 'Ambiente ideal para concentração';
    } else if (light! < bright) {
      icon = Icons.sunny;
      iconColor = Colors.orange;
      message = 'Ambiente iluminado';
    } else {
      icon = Icons.brightness_high;
      iconColor = Colors.redAccent;
      message = 'Luz intensa – ajuste seu brilho';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$light lux',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnuncioCarousel(List<Map<String, dynamic>> ads) {
    if (ads.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text('Ainda não tens anúncios publicados.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            'Os teus anúncios',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ads.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final ad = ads[index];
              return Container(
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad['advertisementName'] ?? 'Sem título',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ad['description'] ?? 'Sem descrição',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${ad['price'] ?? '0'}€',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _initLightSensor() {
    _subscription = Light().lightSensorStream.listen(
      (int event) {
        setState(() {
          light = event;
        });
      },
      onError: (e) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Falhou a obter dados do sensor de luz!'),
              backgroundColor: Colors.red,
            ),
          );
      },
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.jpeg'),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFECECEC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ProfileMenu(userId: widget.userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person),
                    color: Theme.of(context).primaryColor,
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsMenu(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications),
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
            _buildGreeting(),
            const SizedBox(height: 8),
            _buildDashboardStats(),
            const SizedBox(height: 8),
            _buildLightResponseWidget(),
            const SizedBox(height: 8),
            _buildAnuncioCarousel(_myAds),
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
}
