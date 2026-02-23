import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto/src/manager/stock/product.dart';
import 'package:projeto/src/manager/stock/stock_edit.dart';
import 'package:projeto/src/manager/stock/stock_add.dart';

class StockMenu extends StatefulWidget {
  const StockMenu({super.key, required this.userId});

  final String userId;

  @override
  State<StockMenu> createState() => _StockMenuState();
}

class _StockMenuState extends State<StockMenu> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int selectedIndex = -1;
  String? _searchQuery;

  Future<void> _deleteProduct(String productId) async {
    try {
      final adSnapshot =
          await _firestore
              .collection('advertisements')
              .where('productId', isEqualTo: productId)
              .get();

      if (adSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não é possível remover: produto está a ser usado num anúncio.',
            ),
          ),
        );
        return;
      }

      await _firestore.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto removido com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover produto: ${e.toString()}')),
      );
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

      body: Column(
        children: [
          Text(
            "Inventário",
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
                hintText: 'Pesquisar produtos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _searchQuery == null || _searchQuery!.isEmpty
                      ? _firestore
                          .collection('products')
                          .where('userId', isEqualTo: widget.userId)
                          .orderBy('name')
                          .snapshots()
                      : _firestore
                          .collection('products')
                          .where('userId', isEqualTo: widget.userId)
                          .orderBy('name')
                          .startAt([_searchQuery])
                          .endAt(['${_searchQuery!}\uf8ff'])
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products =
                    snapshot.data!.docs.map((doc) {
                      return Product.fromMap(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      );
                    }).toList();

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory, size: 50),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum produto encontrado',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clique no botão + para adicionar',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Dismissible(
                      key: Key(product.id!),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        final adSnapshot =
                            await _firestore
                                .collection('advertisements')
                                .where('productId', isEqualTo: product.id!)
                                .get();

                        if (adSnapshot.docs.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Produto não pode ser removido. Está em uso em anúncios.',
                              ),
                            ),
                          );
                          return false;
                        }

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Confirmar'),
                                content: const Text('Remover este produto?'),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: const Text('Remover'),
                                  ),
                                ],
                              ),
                        );

                        if (confirm == true) {
                          await _deleteProduct(product.id!);
                          return true;
                        }

                        return false;
                      },

                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading:
                              product.imageUrl != null
                                  ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      product.imageUrl!,
                                    ),
                                  )
                                  : CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    child: const Icon(
                                      Icons.inventory,
                                      color: Colors.white,
                                    ),
                                  ),
                          title: Text(product.name ?? 'Sem nome'),
                          subtitle: Text(
                            '${product.quantity?.toStringAsFixed(2)} ${product.unity ?? ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => StockEdit(
                                        product: product,
                                        userId: widget.userId,
                                      ),
                                ),
                              ),
                        ),
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
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StockAdd(userId: widget.userId),
              ),
            ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
