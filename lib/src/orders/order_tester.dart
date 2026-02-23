import 'package:flutter/material.dart';
import 'package:projeto/src/orders/order.dart';
import 'package:projeto/src/orders/order_repository.dart';
import 'package:projeto/src/store/advertisement_repository.dart';

class OrderSeedTester extends StatelessWidget {
  final String userId;

  const OrderSeedTester({super.key, required this.userId});

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
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _createTestOrders(context);
          },

          child: const Text('Criar Encomendas para Teste'),
        ),
      ),
    );
  }

  Future<void> _createTestOrders(BuildContext context) async {
    const clientId = 'cliente123';
    final adRepo = AdvertisementRepository();
    final orderRepo = OrderRepository();

    final ads = await adRepo.getUserAdvertisements(userId).first;

    if (ads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum anúncio do produtor encontrado.')),
      );
      return;
    }

    final now = DateTime.now();
    final sampleOrders = [
      Order(
        clientId: clientId,
        producerId: userId,

        advertisementId: ads[0].id!,
        advertisementName: ads[0].advertisementName,

        address: "Rua da Liberdade, 123, 1250-144 Lisboa, Portugal",

        deliveryOption: ads[0].deliveryOptions.first,
        createdAt: now,
        status: 'pendente',

        price: ads[0].price,
        adLat: ads[0].latitude,
        adLng: ads[0].longitude,
      ),
    ];

    for (var order in sampleOrders) {
      await orderRepo.addOrder(order);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Encomendas de teste criadas com sucesso!')),
    );
  }
}
