import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:projeto/src/manager/stock/product.dart';
import 'package:projeto/src/manager/stock/products_repository.dart';
import 'package:projeto/src/store/advertisement.dart';
import 'package:projeto/src/store/advertisement_repository.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

class AdvertisementAdd extends StatefulWidget {
  final String userId;
  final List<Product> products;

  const AdvertisementAdd({
    super.key,
    required this.userId,
    required this.products,
  });

  @override
  State<AdvertisementAdd> createState() => _AdvertisementAddState();
}

class _AdvertisementAddState extends State<AdvertisementAdd> {
  final _formKey = GlobalKey<FormState>();
  final _advertisementNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final AdvertisementRepository _advertisementRepository =
      AdvertisementRepository();
  final ProductRepository _productRepository = ProductRepository();

  File? _imageFile;
  Product? _selectedProduct;
  String? _selectedCategory;
  final List<bool> _deliverySelections = [true, false];

  final List<String> _deliveryOptions = ['Retirada', 'Domicílio'];
  LatLng? _selectedLocation;
  final List<String> _categories = [
    'Frutos',
    'Leguminosas',
    'Tubérculos',
    'Raízes',
    'Folhas',
    'Hastes',
    'Flores',
    'Cereais',
  ];
  final MapController _mapController = MapController();

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Ative o GPS no dispositivo');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse) {
          throw Exception('Permissão de localização negada');
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao obter localização: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('advertisement_images')
          .child(
            '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<void> _submitAdvertisement() async {
    if (_formKey.currentState!.validate() &&
        _selectedProduct != null &&
        _selectedCategory != null) {
      if (_selectedLocation == null) {
        _showMessage('Defina a localização do anúncio');
        return;
      }

      try {
        String? imageUrl;
        if (_imageFile != null) imageUrl = await _uploadImage(_imageFile!);

        final enteredQty = double.tryParse(_quantityController.text);
        if (enteredQty == null || enteredQty <= 0) {
          _showMessage('Quantidade inválida');
          return;
        }

        final productQty = _selectedProduct!.quantity ?? 0;

        if (enteredQty > productQty) {
          final remaining = productQty;
          _showMessage(
            'Quantidade excede o stock disponível: ${remaining.toStringAsFixed(2)}',
          );
          return;
        }

        final selectedDeliveryOptions = <String>[];
        for (var i = 0; i < _deliverySelections.length; i++) {
          if (_deliverySelections[i])
            selectedDeliveryOptions.add(_deliveryOptions[i]);
        }

        final advertisement = Advertisement(
          userId: widget.userId,
          productId: _selectedProduct!.id!,
          advertisementName: _advertisementNameController.text,
          category: _selectedCategory!,
          description:
              _descriptionController.text.isNotEmpty
                  ? _descriptionController.text
                  : null,
          imageUrl: imageUrl,
          deliveryOptions: selectedDeliveryOptions,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          quantity: enteredQty,
          unity: _selectedProduct!.unity ?? 'kg',
          price: double.parse(_priceController.text),
          createdAt: DateTime.now(),
        );

        final updatedProduct = _selectedProduct!.copyWith(
          quantity: (_selectedProduct!.quantity ?? 0) - enteredQty,
        );

        await _advertisementRepository.addAdvertisement(advertisement);

        await _productRepository.updateProduct(updatedProduct);

        if (mounted) {
          _showMessage('Anúncio publicado com sucesso!');
          Navigator.pop(context);
        }
      } catch (e) {
        _showMessage('Erro ao publicar anúncio: ${e.toString()}');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildDeliveryCheckbox(int index, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _deliverySelections[index],
          onChanged: (bool? value) {
            setState(() => _deliverySelections[index] = value ?? false);
          },
          checkColor: Theme.of(context).primaryColor,
          fillColor: MaterialStateProperty.all(Colors.white),
          side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        Text(label),
      ],
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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Adicionar Anúncio',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.grey[300],
                  child:
                      _imageFile != null
                          ? ClipOval(
                            child: Image.file(
                              _imageFile!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey,
                          ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _advertisementNameController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Nome do Anúncio*',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Informe o nome do anúncio'
                            : value.length < 3
                            ? 'Nome inválido'
                            : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<Product>(
                value: _selectedProduct,
                decoration: const InputDecoration(
                  labelText: 'Produto*',
                  border: OutlineInputBorder(),
                ),
                items:
                    widget.products
                        .map(
                          (product) => DropdownMenuItem(
                            value: product,
                            child: Text(product.name ?? 'Sem nome'),
                          ),
                        )
                        .toList(),
                onChanged:
                    (product) => setState(() => _selectedProduct = product),
                validator:
                    (value) => value == null ? 'Selecione um produto' : null,
              ),
              if (_selectedProduct != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Unidade do produto: ${_selectedProduct!.unity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria*',
                  border: OutlineInputBorder(),
                ),
                items:
                    _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (cat) => setState(() => _selectedCategory = cat),
                validator:
                    (value) => value == null ? 'Selecione uma categoria' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade*',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Informe a quantidade'
                            : double.tryParse(value) == null
                            ? 'Valor inválido'
                            : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Preço*',
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Informe o preço'
                            : double.tryParse(value) == null
                            ? 'Valor inválido'
                            : null,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Opções de Entrega:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildDeliveryCheckbox(0, 'Retirada'),
                  const SizedBox(width: 20),
                  _buildDeliveryCheckbox(1, 'Domicílio'),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAdvertisement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Publicar Anúncio',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Localização do Anúncio:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    _selectedLocation != null
                        ? FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: latlong.LatLng(
                              _selectedLocation!.latitude,
                              _selectedLocation!.longitude,
                            ),
                            initialZoom: 15.0,
                            onTap: (_, latlong.LatLng latLng) {
                              setState(() {
                                _selectedLocation = LatLng(
                                  latLng.latitude,
                                  latLng.longitude,
                                );
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: latlong.LatLng(
                                    _selectedLocation!.latitude,
                                    _selectedLocation!.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                        : const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 10),
              Text(
                _selectedLocation != null
                    ? 'Coordenadas: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}'
                    : 'Obtendo localização...',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
