import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:projeto/src/store/advertisement.dart';

class AdvertisementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> addAdvertisement(Advertisement advertisement) async {
    final docRef = await _firestore
        .collection('advertisements')
        .add(advertisement.toMap());
    return docRef.id;
  }

  Future<void> updateAdvertisement(Advertisement advertisement) async {
    await _firestore
        .collection('advertisements')
        .doc(advertisement.id)
        .update(advertisement.toMap());
  }

  Future<List<Advertisement>> getAdvertisementsByProduct(
    String productId,
  ) async {
    final snapshot =
        await _firestore
            .collection('advertisements')
            .where('productId', isEqualTo: productId)
            .get();

    return snapshot.docs
        .map((doc) => Advertisement.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<String?> uploadImage(
    String userId,
    String advertisementId,
    File imageFile,
  ) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('advertisement_images')
          .child('${userId}_$advertisementId.jpg');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<void> deleteAdvertisement(String advertisementId) async {
    await _firestore.collection('advertisements').doc(advertisementId).delete();
  }

  Future<void> deleteAdvertisementWithImage(
    String advertisementId,
    String? imageUrl,
  ) async {
    await deleteAdvertisement(advertisementId);

    if (imageUrl != null) {
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (e) {
        debugPrint('Erro ao deletar imagem: $e');
      }
    }
  }

  Future<void> updateAdvertisementWithImage({
    required Advertisement advertisement,
    required File? newImageFile,
    required String? oldImageUrl,
  }) async {
    String? imageUrl = advertisement.imageUrl;

    if (newImageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('advertisement_images')
          .child('${advertisement.userId}_${advertisement.id}.jpg');

      await ref.putFile(newImageFile);
      imageUrl = await ref.getDownloadURL();

      if (oldImageUrl != null && oldImageUrl != imageUrl) {
        try {
          await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
        } catch (_) {}
      }
    }

    await _firestore.collection('advertisements').doc(advertisement.id).update({
      'advertisementName': advertisement.advertisementName,
      'description': advertisement.description,
      'quantity': advertisement.quantity,
      'price': advertisement.price,
      'unity': advertisement.unity,
      'category': advertisement.category,
      'deliveryOptions': advertisement.deliveryOptions,
      'imageUrl': imageUrl,
    });
  }

  Stream<List<Advertisement>> getUserAdvertisements(String userId) {
    return _firestore
        .collection('advertisements')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Advertisement.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  Stream<List<Advertisement>> getAdvertisementsByCategory(String category) {
    return _firestore
        .collection('advertisements')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Advertisement.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  Future<Advertisement?> getAdvertisementById(String id) async {
    final doc = await _firestore.collection('advertisements').doc(id).get();
    return doc.exists ? Advertisement.fromMap(doc.id, doc.data()!) : null;
  }
}
