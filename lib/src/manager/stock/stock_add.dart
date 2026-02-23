import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:projeto/src/manager/stock/product.dart';

class StockAdd extends StatefulWidget {
  const StockAdd({super.key, required this.userId});

  final String userId;

  @override
  State<StockAdd> createState() => _StockAddState();
}

class _StockAddState extends State<StockAdd> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _imageFile;
  String? _selectedUnit;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final productId = _firestore.collection('products').doc().id;

      final ref = _storage
          .ref()
          .child('product_images')
          .child('${widget.userId}_$productId.jpg');

      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer upload da imagem: ${e.toString()}'),
        ),
      );
      return null;
    }
  }

  Future<void> _saveProduct() async {
    setState(() => _isSaving = true);

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um nome para o produto'),
        ),
      );
      setState(() => _isSaving = false);
      return;
    }
    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira uma quantidade de produto'),
        ),
      );
      setState(() => _isSaving = false);
      return;
    }
    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira uma unidade de medida'),
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    try {
      final imageUrl = await _uploadImage();
      final quantity = double.tryParse(_quantityController.text);

      final newProduct = Product(
        userId: widget.userId,
        name: _nameController.text,
        quantity: quantity,
        unity: _selectedUnit,
        imageUrl: imageUrl,
      );

      await _firestore.collection('products').add(newProduct.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto adicionado com sucesso')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar produto: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      body:
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Adicionar Produto',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildImageSection(),
                    const SizedBox(height: 20),
                    _buildNameField(),
                    const SizedBox(height: 20),
                    _buildQuantityField(),
                    const SizedBox(height: 20),
                    _buildUnitSelection(),
                    const SizedBox(height: 30),
                    _buildSaveButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
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
                : const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nome do Produto:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Nome do produto',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantidade:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Quantidade',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unidade:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildUnitCheckbox('kg', 'Quilogramas'),
            const SizedBox(width: 20),
            _buildUnitCheckbox('unidade', 'Unidades'),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitCheckbox(String value, String label) {
    return Row(
      children: [
        Checkbox(
          value: _selectedUnit == value,
          onChanged: (bool? selected) {
            setState(() {
              _selectedUnit = selected == true ? value : null;
            });
          },
          checkColor: Theme.of(context).primaryColor,
          fillColor: MaterialStateProperty.all(Colors.white),
          side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text(
          'Adicionar Produto',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
