import 'package:flutter/material.dart';
import 'package:projeto/src/manager/financials/financial_record.dart';
import 'package:projeto/src/manager/financials/financial_repository.dart';

class FinancesMenu extends StatefulWidget {
  final String userId;

  const FinancesMenu({super.key, required this.userId});

  @override
  State<FinancesMenu> createState() => _FinancesMenuState();
}

class _FinancesMenuState extends State<FinancesMenu> {
  final FinancialRepository _repository = FinancialRepository();
  late Future<double> _totalRevenue;
  late Future<List<FinancialRecord>> _records;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _totalRevenue = _repository.getTotalRevenueByUser(widget.userId);
      _records = _repository.getFinancialRecordsByUser(widget.userId);
    });
  }

  Future<void> _resetFinancialData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar ação'),
            content: const Text(
              'Tem certeza que deseja limpar todo o histórico financeiro e zerar a faturação? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteAllUserRecords(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Histórico financeiro limpo com sucesso!'),
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao limpar histórico: $e')),
          );
        }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _resetFinancialData,
            tooltip: 'Limpar histórico',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFECECEC),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relatório Financeiro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<double>(
                  future: _totalRevenue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Erro: ${snapshot.error}');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Faturação Total',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${snapshot.data?.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Histórico de Transações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<FinancialRecord>>(
                future: _records,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma transação registrada'),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final record = snapshot.data![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(record.orderId),
                          subtitle: Text(
                            '${record.transactionDate.day}/${record.transactionDate.month}/${record.transactionDate.year}',
                          ),
                          trailing: Text(
                            '${record.amount.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
      ),
    );
  }
}
