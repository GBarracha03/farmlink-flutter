import 'package:flutter/material.dart';
import 'package:projeto/src/orders/order.dart';
import 'package:projeto/src/orders/order_monitor_service.dart';
import 'package:projeto/src/orders/order_repository.dart';
import 'package:projeto/src/notifications/notification_service.dart';

class OrderPendingPage extends StatefulWidget {
  final String userId;
  final String status;
  const OrderPendingPage({
    super.key,
    required this.userId,
    this.status = 'pendente',
  });

  @override
  State<OrderPendingPage> createState() => _OrderPendingPageState();
}

class _OrderPendingPageState extends State<OrderPendingPage> {
  late final OrderMonitorService _orderMonitor;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _orderMonitor = OrderMonitorService(widget.userId, _notificationService);
    _orderMonitor.startMonitoring();
  }

  @override
  void dispose() {
    _orderMonitor.startMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        title: Image.asset('assets/images/logo.jpeg'),
      ),
      backgroundColor: const Color(0xFFECECEC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
            child: Text(
              'Encomendas Pendentes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: OrderRepository().getOrdersByProducer(
                widget.userId,
                status: 'pendente',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.hourglass_empty,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma encomenda pendente.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.pending_actions,
                          size: 32,
                          color: Colors.orange,
                        ),
                        title: Text(
                          order.advertisementName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Destino: ${order.address}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              tooltip: 'Aceitar',
                              onPressed:
                                  () => _updateStatus(context, order, 'aceito'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Recusar',
                              onPressed:
                                  () =>
                                      _updateStatus(context, order, 'recusado'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(
    BuildContext context,
    Order order,
    String newStatus,
  ) async {
    try {
      await OrderRepository().updateOrderStatus(order.id!, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Encomenda ${newStatus == 'aceito' ? 'aceita' : 'recusada'} com sucesso!',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar status: $e')));
    }
  }
}
