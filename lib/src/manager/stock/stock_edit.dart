import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:projeto/src/manager/stock/product.dart';

class StockEdit extends StatefulWidget {
  const StockEdit({super.key, required this.product, required this.userId});

  final Product product;
  final String userId;

  @override
  State<StockEdit> createState() => _StockEditState();
}

class _StockEditState extends State<StockEdit> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _imageFile;
  String? _selectedUnit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product.name ?? '';
    _quantityController.text = widget.product.quantity?.toString() ?? '';
    _selectedUnit = widget.product.unity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

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
      if (widget.product.imageUrl != null) {
        try {
          await _storage.refFromURL(widget.product.imageUrl!).delete();
        } catch (e) {
          debugPrint('Erro ao deletar imagem antiga: $e');
        }
      }

      final ref = _storage
          .ref()
          .child('product_images')
          .child('${widget.userId}_${widget.product.id}.jpg');

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
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um nome para o produto'),
        ),
      );
      return;
    }

    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira uma quantidade')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira uma quantidade válida'),
        ),
      );
      return;
    }

    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma unidade')),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      final imageUrl = await _uploadImage();

      final updatedProduct = Product(
        id: widget.product.id,
        userId: widget.userId,
        name: _nameController.text,
        quantity: double.tryParse(_quantityController.text),
        unity: _selectedUnit,
        imageUrl: imageUrl ?? widget.product.imageUrl,
      );

      await _firestore
          .collection('products')
          .doc(widget.product.id)
          .update(updatedProduct.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso')),
        );
        Navigator.pop(context, updatedProduct);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar produto: ${e.toString()}')),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(),
          ),
        ],
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
                      'Editar Produto',
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
                : widget.product.imageUrl != null
                ? ClipOval(
                  child: Image.network(
                    widget.product.imageUrl!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      );
                    },
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
          'Guardar Alterações',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: const Text('Tem certeza que deseja excluir este produto?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _deleteProduct();
    }
  }

  Future<void> _deleteProduct() async {
    setState(() => _isSaving = true);

    try {
      final adSnapshot =
          await _firestore
              .collection('advertisements')
              .where('productId', isEqualTo: widget.product.id)
              .limit(1)
              .get();

      if (adSnapshot.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não é possível excluir. Produto está a ser usado num anúncio.',
              ),
            ),
          );
        }
        return;
      }

      await _firestore.collection('products').doc(widget.product.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto excluído com sucesso')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir produto: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
