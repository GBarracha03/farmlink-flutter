import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projeto/src/manager/stock/products_repository.dart';
import 'package:projeto/src/manager/stock/product.dart';
import 'package:projeto/src/store/advertisement.dart';
import 'package:projeto/src/store/advertisement_add.dart';
import 'package:projeto/src/store/advertisement_edit.dart';
import 'package:projeto/src/store/advertisement_repository.dart';
import 'package:projeto/src/widgets/bottom_navigator_bar.dart';
import 'package:projeto/src/widgets/navigator_helper.dart';

class AdvertisementList extends StatefulWidget {
  final String userId;

  const AdvertisementList({super.key, required this.userId});

  @override
  State<AdvertisementList> createState() => _AdvertisementListState();
}

class _AdvertisementListState extends State<AdvertisementList> {
  final AdvertisementRepository _repository = AdvertisementRepository();
  final ProductRepository _productRepo = ProductRepository();
  int _selectedIndex = 2;
  String? _searchQuery;
  Map<String, Product> _productMap = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _productRepo.getProducts(widget.userId).first;
    setState(() {
      _productMap = {for (var p in products) p.id!: p};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.jpeg'),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFFECECEC),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Anúncios",
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar anúncios...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Advertisement>>(
              stream: _repository.getUserAdvertisements(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allAds = snapshot.data ?? [];
                final filteredAds =
                    _searchQuery == null || _searchQuery!.isEmpty
                        ? allAds
                        : allAds.where((ad) {
                          final productName =
                              _productMap[ad.productId]?.name ?? '';
                          return productName.toLowerCase().contains(
                                _searchQuery!.toLowerCase(),
                              ) ||
                              ad.advertisementName.toLowerCase().contains(
                                _searchQuery!.toLowerCase(),
                              );
                        }).toList();

                if (filteredAds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sell, size: 50),
                        const SizedBox(height: 16),
                        const Text('Nenhum anúncio encontrado'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            final products =
                                await _productRepo
                                    .getProducts(widget.userId)
                                    .first;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AdvertisementAdd(
                                      userId: widget.userId,
                                      products: products,
                                    ),
                              ),
                            );
                          },
                          child: const Text('Criar primeiro anúncio'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredAds.length,
                  itemBuilder: (context, index) {
                    final ad = filteredAds[index];
                    final productName =
                        _productMap[ad.productId]?.name ?? 'Produto';

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading:
                            ad.imageUrl != null
                                ? CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  child: ClipOval(
                                    child: Image.network(
                                      ad.imageUrl!,
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                                : CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  child: const Icon(
                                    Icons.sell,
                                    color: Colors.white,
                                  ),
                                ),
                        title: Text(ad.advertisementName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(productName),
                            Text('€ ${ad.price.toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final orderSnapshot =
                                await FirebaseFirestore.instance
                                    .collection('orders')
                                    .where('advertisementId', isEqualTo: ad.id!)
                                    .limit(1)
                                    .get();

                            if (orderSnapshot.docs.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Não é possível excluir. Anúncio vinculado a uma encomenda.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Confirmar exclusão'),
                                    content: const Text(
                                      'Deseja realmente excluir este anúncio?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              await _repository.deleteAdvertisement(ad.id!);
                            }
                          },
                        ),
                        onTap: () async {
                          final products =
                              await _productRepo
                                  .getProducts(widget.userId)
                                  .first;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AdvertisementEdit(
                                    advertisement: ad,
                                    products: products,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        onPressed: () async {
          final products = await _productRepo.getProducts(widget.userId).first;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AdvertisementAdd(
                    userId: widget.userId,
                    products: products,
                  ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigatorBarDefault(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
          NavigationHelper.onItemTapped(context, index, widget.userId);
        },
      ),
    );
  }
}
