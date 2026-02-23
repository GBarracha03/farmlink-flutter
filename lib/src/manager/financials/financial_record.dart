class FinancialRecord {
  final String id;
  final String orderId;
  final double amount;
  final DateTime transactionDate;
  final String userId;

  FinancialRecord({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.transactionDate,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'transactionDate': transactionDate.toIso8601String(),
      'userId': userId,
    };
  }

  factory FinancialRecord.fromMap(Map<String, dynamic> map) {
    return FinancialRecord(
      id: map['id'],
      orderId: map['orderId'],

      amount: map['amount'],
      transactionDate: DateTime.parse(map['transactionDate']),
      userId: map['userId'],
    );
  }
}
