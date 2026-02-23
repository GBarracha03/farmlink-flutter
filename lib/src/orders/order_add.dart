// src/orders/order_add.dart
/*import 'package:flutter/material.dart';
import 'package:projeto/src/manager/stock/product.dart';
import 'package:projeto/src/orders/order.dart';
import 'package:projeto/src/orders/order_repository.dart';

class OrderAdd extends StatefulWidget {
  final String clientId;
  final String producerId;
  final List<Product> products;

  const OrderAdd({
    super.key,
    required this.clientId,
    required this.producerId,
    required this.products,
  });

  @override
  State<OrderAdd> createState() => _OrderAddState();
}

class _OrderAddState extends State<OrderAdd> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  Product? _selectedProduct;
  String _selectedDeliveryOption = 'domicílio';

  final _deliveryOptions = ['domicílio', 'retirada'];
  final _orderRepo = OrderRepository();

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      final quantity = double.tryParse(_quantityController.text);
      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Quantidade inválida')));
        return;
      }

      final order = Order(
        clientId: widget.clientId,
        producerId: widget.producerId,
        productId: _selectedProduct!.id!,
        productName: _selectedProduct!.name ?? '',
        quantity: quantity,
        unity: _selectedProduct!.unity ?? '',
        location: _locationController.text,
        latitude: latitude,
        longitude: longitude,
        deliveryOption: _selectedDeliveryOption,
        status: 'pendente',
        createdAt: DateTime.now(),
      );

      await _orderRepo.addOrder(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encomenda enviada com sucesso!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Encomenda')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Product>(
                value: _selectedProduct,
                items:
                    widget.products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name ?? 'Sem nome'),
                          ),
                        )
                        .toList(),
                onChanged: (p) => setState(() => _selectedProduct = p),
                decoration: const InputDecoration(
                  labelText: 'Produto',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) => value == null ? 'Selecione um produto' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Informe a quantidade'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Localidade',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Informe a localidade'
                            : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDeliveryOption,
                items:
                    _deliveryOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                onChanged:
                    (option) =>
                        setState(() => _selectedDeliveryOption = option!),
                decoration: const InputDecoration(
                  labelText: 'Opção de entrega',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitOrder,
                child: const Text('Enviar Encomenda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/