import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projeto/src/manager/stock/product.dart';
import 'package:projeto/src/manager/stock/products_repository.dart';
import 'package:projeto/src/store/advertisement.dart';
import 'package:projeto/src/store/advertisement_repository.dart';

class AdvertisementEdit extends StatefulWidget {
  final Advertisement advertisement;
  final List<Product> products;

  const AdvertisementEdit({
    super.key,
    required this.advertisement,
    required this.products,
  });

  @override
  State<AdvertisementEdit> createState() => _AdvertisementEditState();
}

class _AdvertisementEditState extends State<AdvertisementEdit> {
  final _formKey = GlobalKey<FormState>();
  final _advertisementNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  late List<bool> _deliverySelections;
  late String _selectedCategory;
  Product? _selectedProduct;
  File? _imageFile;
  String? _tempImageUrl;

  final AdvertisementRepository _repository = AdvertisementRepository();
  final List<String> _deliveryOptions = ['Retirada', 'Domicílio'];
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

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _advertisementNameController.text = widget.advertisement.advertisementName;
    _descriptionController.text = widget.advertisement.description ?? '';
    _quantityController.text = widget.advertisement.quantity.toString();
    _priceController.text = widget.advertisement.price.toString();
    _selectedCategory = widget.advertisement.category;
    _tempImageUrl = widget.advertisement.imageUrl;

    _deliverySelections = List.generate(
      _deliveryOptions.length,
      (index) => widget.advertisement.deliveryOptions.contains(
        _deliveryOptions[index],
      ),
    );

    final matching = widget.products.where(
      (p) => p.id == widget.advertisement.productId,
    );
    _selectedProduct = matching.isNotEmpty ? matching.first : null;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _tempImageUrl = null;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      try {
        final enteredQty = double.tryParse(_quantityController.text);
        if (enteredQty == null || enteredQty <= 0) {
          _showMessage('Quantidade inválida');
          return;
        }

        final ads = await _repository.getAdvertisementsByProduct(
          _selectedProduct!.id!,
        );
        final totalAnunciado = ads.fold<double>(
          0.0,
          (sum, ad) => sum + ad.quantity,
        );
        final originalQty = (_selectedProduct!.quantity ?? 0) + totalAnunciado;

        final otherAdsQty = ads
            .where((ad) => ad.id != widget.advertisement.id)
            .fold<double>(0.0, (sum, ad) => sum + ad.quantity);

        final maxAnunciavel = originalQty - otherAdsQty;

        if (enteredQty > maxAnunciavel) {
          _showMessage(
            'Stock insuficiente. Máximo permitido: ${maxAnunciavel.toStringAsFixed(2)} ${_selectedProduct!.unity}',
          );
          return;
        }

        final previousQty = widget.advertisement.quantity;
        final diff = enteredQty - previousQty;
        final newStock = (_selectedProduct!.quantity ?? 0) - diff;

        final updatedProduct = _selectedProduct!.copyWith(quantity: newStock);

        final updatedAd = widget.advertisement.copyWith(
          advertisementName: _advertisementNameController.text,
          description:
              _descriptionController.text.isNotEmpty
                  ? _descriptionController.text
                  : null,
          quantity: enteredQty,
          price: double.parse(_priceController.text),
          unity: _selectedProduct!.unity ?? 'kg',
          category: _selectedCategory,
          deliveryOptions:
              _deliveryOptions
                  .asMap()
                  .entries
                  .where((e) => _deliverySelections[e.key])
                  .map((e) => e.value)
                  .toList(),
          imageUrl: _tempImageUrl,
        );

        await _repository.updateAdvertisementWithImage(
          advertisement: updatedAd,
          newImageFile: _imageFile,
          oldImageUrl: widget.advertisement.imageUrl,
        );

        await ProductRepository().updateProduct(updatedProduct);

        if (mounted) {
          _showMessage('Anúncio atualizado com sucesso!');
          Navigator.pop(context, updatedAd);
        }
      } catch (e) {
        _showMessage('Erro ao atualizar: ${e.toString()}');
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildDeliveryCheckbox(int index, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _deliverySelections[index],
          onChanged:
              (bool? value) =>
                  setState(() => _deliverySelections[index] = value ?? false),
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
                'Editar Anúncio',
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
                          : _tempImageUrl != null
                          ? ClipOval(
                            child: Image.network(
                              _tempImageUrl!,
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
                decoration: const InputDecoration(
                  labelText: 'Nome do Anúncio*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o nome do anúncio';
                  }
                  if (value.length < 3) {
                    return 'Nome muito curto (mín. 3 caracteres)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Produto:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    _selectedProduct?.name ?? '',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
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

              const SizedBox(height: 25),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria*',
                  border: OutlineInputBorder(),
                ),
                items:
                    _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (c) => setState(() => _selectedCategory = c!),
                validator: (v) => v == null ? 'Selecione uma categoria' : null,
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
                enabled: _selectedProduct != null,
                decoration: const InputDecoration(
                  labelText: 'Quantidade*',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_selectedProduct == null) return null;
                  if (v == null || v.isEmpty) return 'Informe a quantidade';
                  return double.tryParse(v) == null ? 'Valor inválido' : null;
                },
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
                    (v) =>
                        v == null || v.isEmpty
                            ? 'Informe o preço'
                            : double.tryParse(v) == null
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
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Salvar Alterações',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
