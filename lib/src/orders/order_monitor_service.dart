import 'dart:async';
import 'package:projeto/src/orders/order_repository.dart';
import 'package:projeto/src/notifications/notification_service.dart';

class OrderMonitorService {
  final OrderRepository _orderRepository = OrderRepository();
  final NotificationService _notificationService;

  String _userId;
  int _lastOrderCount = 0;
  StreamSubscription? _subscription;
  bool _initialLoad = true;

  OrderMonitorService(this._userId, this._notificationService);

  Future<void> startMonitoring() async {
    await _notificationService.initNotification();

    await _subscription?.cancel();

    _subscription = _orderRepository
        .getOrdersByProducer(_userId, status: 'pendente')
        .listen((orders) async {
          if (_initialLoad) {
            _lastOrderCount = orders.length;
            _initialLoad = false;
            return;
          }

          if (orders.length > _lastOrderCount) {
            try {
              print('[DEBUG] Tentando mostrar notificação...');
              await _notificationService.showNotification(
                title: 'Nova Encomenda',
                body:
                    'Você tem ${orders.length - _lastOrderCount} nova(s) encomenda(s)!',
              );
              print('[DEBUG] Notificação exibida com sucesso');
            } catch (e) {
              print('[ERROR] Falha ao mostrar notificação: $e');
            }
          }
          _lastOrderCount = orders.length;
        });
  }

  Future<void> stopMonitoring() async {
    await _subscription?.cancel();
    _initialLoad = true;
    _lastOrderCount = 0;
  }
}
