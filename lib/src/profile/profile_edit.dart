import 'package:flutter/material.dart';
import 'package:projeto/src/profile/user_profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({
    super.key,
    required this.userId,
    required this.initialProfile,
  });

  final String userId;
  final UserProfile initialProfile;

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController numberController;
  late TextEditingController marketsController;
  File? _imageFile;
  bool _isSaving = false;

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira um nome';
    }
    return null;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira um número de contacto';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Número inválido (apenas dígitos)';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialProfile.name);
    numberController = TextEditingController(
      text: widget.initialProfile.phoneNumber,
    );
    marketsController = TextEditingController(
      text: widget.initialProfile.usualMarkets?.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    numberController.dispose();
    marketsController.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? imageUrl = widget.initialProfile.profileImageUrl;

      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${widget.userId}.jpg');

        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final updatedProfile = UserProfile(
        userId: widget.userId,
        name: nameController.text,
        phoneNumber: numberController.text,
        profileImageUrl: imageUrl ?? widget.initialProfile.profileImageUrl,
        usualMarkets:
            marketsController.text.split(',').map((e) => e.trim()).toList(),
        rating: widget.initialProfile.rating,
      );

      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .update({
            'name': nameController.text,
            'phoneNumber': numberController.text,
            if (imageUrl != null) 'profileImageUrl': imageUrl,
            'usualMarkets':
                marketsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
          });

      if (mounted) {
        Navigator.pop(context, updatedProfile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao guardar perfil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Editar Perfil',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => pickImage(ImageSource.gallery),
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
                                  : widget.initialProfile.profileImageUrl !=
                                      null
                                  ? ClipOval(
                                    child: Image.network(
                                      widget.initialProfile.profileImageUrl!,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : widget.initialProfile.name != null
                                  ? Text(
                                    widget.initialProfile.name![0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nome de utilizador:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Insere o teu nome',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Número de Contacto:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: numberController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Insere o teu número',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateNumber,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mercados Habituais:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: marketsController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Mercado de Azeitão, Palmela...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            'Guardar',
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
