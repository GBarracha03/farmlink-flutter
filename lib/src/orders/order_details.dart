import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:projeto/src/manager/financials/financial_record.dart';
import 'package:projeto/src/manager/financials/financial_repository.dart';
import 'package:projeto/src/orders/order.dart';
import 'package:projeto/src/orders/order_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:projeto/src/store/advertisement_repository.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:projeto/src/manager/invoices/invoice_service.dart';

class OrderDetailsPage extends StatefulWidget {
  final Order order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Future<LatLng?> _customerCoords;
  late Future<LatLng?> _advertisementCoords;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _advertisementCoords = Future.value(
      widget.order.adLat != null && widget.order.adLng != null
          ? LatLng(widget.order.adLat!, widget.order.adLng!)
          : null,
    );
    _customerCoords = _addressToLatLng(widget.order.address);
  }

  Future<void> generateInvoicePdf(BuildContext context, Order order) async {
    final pdf = pw.Document();

    final date = order.createdAt.toLocal();
    final formattedDate =
        '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';

    pdf.addPage(
      pw.Page(
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Fatura de Encomenda',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('ID da Entrega: ${order.id}'),
                pw.Text('Anúncio: ${order.advertisementName}'),
                pw.Text(
                  'Preço: ${order.price?.toStringAsFixed(2) ?? 'N/A'} Eur',
                ),
                pw.Text('Opção de Entrega: ${order.deliveryOption}'),
                pw.Text('Local de Entrega: ${order.address}'),
                pw.Text('Data: $formattedDate'),
              ],
            ),
      ),
    );

    final bytes = await pdf.save();

    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        throw Exception('Permissão negada para guardar PDF.');
      }
    }

    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!downloadsDir.existsSync()) {
      throw Exception('Diretório de Downloads não encontrado');
    }

    final filePath = '${downloadsDir.path}/fatura_${order.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Fatura guardada em: $filePath')));
  }

  Future<LatLng?> _addressToLatLng(String address) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$address',
      );
      final response = await http.get(url);
      final data = json.decode(response.body) as List;

      if (data.isNotEmpty) {
        return LatLng(
          double.parse(data[0]['lat']),
          double.parse(data[0]['lon']),
        );
      }
      return null;
    } catch (e) {
      print('Erro no Geocoding: $e');
      return null;
    }
  }

  Future<void> _markAsDelivered() async {
    try {
      final orderRepo = OrderRepository();
      final adRepo = AdvertisementRepository();

      final financeRepo = FinancialRepository();

      debugPrint('Dados do registro:');
      debugPrint('ID: ${widget.order.id}');
      debugPrint('Preço: ${widget.order.price}');
      debugPrint('UserID: ${widget.order.producerId}');

      await financeRepo.addFinancialRecord(
        FinancialRecord(
          id: widget.order.id!,
          orderId: widget.order.id!,
          amount: widget.order.price!,
          transactionDate: DateTime.now(),
          userId: widget.order.producerId,
        ),
      );

      await orderRepo.updateOrderStatus(widget.order.id!, 'entregue');

      await adRepo.deleteAdvertisement(widget.order.advertisementId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Encomenda marcada como entregue e anúncio removido!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar: ${e.toString()}')),
        );
      }
    }
  }

  Future<List<LatLng>> _getRoutePoints(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry'];
        if (geometry['type'] == 'LineString') {
          final coordinates = geometry['coordinates'] as List;
          return coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar rota: $e');
      return [];
    }
  }

  Widget _infoLabelValue(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Encomenda',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLabelValue(
                        context,
                        'ID da Entrega',
                        '${widget.order.id}',
                      ),
                      _infoLabelValue(
                        context,
                        'Anúncio',
                        widget.order.advertisementName,
                      ),
                      _infoLabelValue(
                        context,
                        'Local de Entrega',
                        widget.order.address,
                      ),
                      _infoLabelValue(
                        context,
                        'Opção de Entrega',
                        widget.order.deliveryOption,
                      ),
                      _infoLabelValue(context, 'Status', widget.order.status),
                      _infoLabelValue(
                        context,
                        'Preço',
                        '${widget.order.price?.toStringAsFixed(2) ?? 'N/A'} €',
                      ),
                      _infoLabelValue(
                        context,
                        'Data',
                        widget.order.createdAt.toLocal().toString(),
                      ),
                    ],
                  ),
                ),
              ),

              FutureBuilder(
                future: Future.wait([
                  _customerCoords,
                  _advertisementCoords,
                  Future.wait([
                    _advertisementCoords,
                    _customerCoords,
                  ]).then((coords) => _getRoutePoints(coords[0]!, coords[1]!)),
                ]),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 300,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Text('Erro ao carregar o mapa'),
                    );
                  }

                  final deliveryCoords = snapshot.data?[0] as LatLng?;
                  final adCoords = snapshot.data?[1] as LatLng?;
                  final routePoints = snapshot.data?[2] as List<LatLng>? ?? [];

                  if (deliveryCoords == null) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Text('Local de entrega não encontrado'),
                    );
                  }

                  final markers = <Marker>[
                    Marker(
                      point: deliveryCoords,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                    if (adCoords != null)
                      Marker(
                        point: adCoords,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.blue,
                          size: 50,
                        ),
                      ),
                  ];

                  final bounds =
                      adCoords != null
                          ? LatLngBounds.fromPoints([deliveryCoords, adCoords])
                          : LatLngBounds.fromPoints([deliveryCoords]);

                  return Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: bounds.center,
                              initialZoom: _calculateZoomLevel(bounds),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.projeto',
                              ),
                              MarkerLayer(markers: markers),
                              if (routePoints.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: routePoints,
                                      color: Colors.blue,
                                      strokeWidth: 4,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (adCoords != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              if (routePoints.isNotEmpty)
                                Text(
                                  'Distância da rota: ${_calculateRouteDistance(routePoints).toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              if (widget.order.status == 'aceito')
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Marcar como Entregue'),
                    onPressed: _markAsDelivered,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(200, 50),
                    ),
                  ),
                ),
              if (widget.order.status == 'entregue')
                Center(
                  child: ElevatedButton.icon(
                    onPressed:
                        () => InvoiceService.generateInvoicePdf(
                          context,
                          widget.order,
                        ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Gerar Fatura PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(200, 50),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateRouteDistance(List<LatLng> routePoints) {
    if (routePoints.length < 2) return 0.0;

    final distance = Distance();
    double total = 0.0;

    const step = 5;

    for (int i = 0; i < routePoints.length - 1; i += step) {
      final nextIndex = (i + step).clamp(0, routePoints.length - 1);
      total += distance.as(
        LengthUnit.Kilometer,
        routePoints[i],
        routePoints[nextIndex],
      );
    }

    final straightDistance = distance.as(
      LengthUnit.Kilometer,
      routePoints.first,
      routePoints.last,
    );

    return max(total, straightDistance);
  }

  double _calculateZoomLevel(LatLngBounds bounds) {
    final distance = Distance();
    final km = distance.as(
      LengthUnit.Kilometer,
      LatLng(bounds.southWest.latitude, bounds.southWest.longitude),
      LatLng(bounds.northEast.latitude, bounds.northEast.longitude),
    );

    if (km < 1) return 14;
    if (km < 5) return 12;
    if (km < 10) return 10;
    if (km < 50) return 8;
    return 6;
  }
}
