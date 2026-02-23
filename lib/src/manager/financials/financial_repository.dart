import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:projeto/src/manager/financials/financial_record.dart';

class FinancialRepository {
  final CollectionReference _financialRecords = FirebaseFirestore.instance
      .collection('financialRecords');

  Future<void> addFinancialRecord(FinancialRecord record) async {
    try {
      print('Tentando adicionar registo financeiro: ${record.toMap()}');
      await _financialRecords.doc(record.id).set(record.toMap());
      print('Registo financeiro adicionado com sucesso!');
    } catch (e) {
      print('Erro ao adicionar registo financeiro: $e');
      rethrow;
    }
  }

  Future<void> deleteAllUserRecords(String userId) async {
    try {
      print('Iniciando exclusão de registos para o usuário: $userId');

      final querySnapshot =
          await _financialRecords.where('userId', isEqualTo: userId).get();

      if (querySnapshot.docs.isEmpty) {
        print('Nenhum registro encontrado para deletar');
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        print('Marcando documento ${doc.id} para exclusão');
      }

      await batch.commit();
      print('Todos os registos foram deletados com sucesso');
    } catch (e) {
      print('Erro ao deletar registos: $e');
      throw Exception('Falha ao deletar registos: $e');
    }
  }

  Future<List<FinancialRecord>> getFinancialRecordsByUser(String userId) async {
    final querySnapshot =
        await _financialRecords
            .where('userId', isEqualTo: userId)
            .orderBy('transactionDate', descending: true)
            .get();

    return querySnapshot.docs
        .map(
          (doc) => FinancialRecord.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<double> getTotalRevenueByUser(String userId) async {
    final querySnapshot =
        await _financialRecords.where('userId', isEqualTo: userId).get();

    double total = 0.0;
    for (final doc in querySnapshot.docs) {
      final record = FinancialRecord.fromMap(
        doc.data() as Map<String, dynamic>,
      );
      total += record.amount;
    }
    return total;
  }
}
