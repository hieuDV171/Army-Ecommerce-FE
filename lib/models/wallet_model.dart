import 'model_helpers.dart';

class WalletBalanceModel {
  final num available;
  final num pending;

  const WalletBalanceModel({required this.available, required this.pending});

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      available: readNum(json, [
        'available_balance',
        'available',
        'balance',
        'current_balance',
      ]),
      pending: readNum(json, ['pending', 'pending_balance']),
    );
  }
}

class WalletHistoryModel {
  final int historyId;
  final String objectId;
  final String title;
  final String detail;
  final num balance;
  final String date;
  final String type;

  const WalletHistoryModel({
    required this.historyId,
    required this.objectId,
    required this.title,
    required this.detail,
    required this.balance,
    required this.date,
    required this.type,
  });

  factory WalletHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawHistoryId = json['history_id'] ?? json['id'];
    int parsedId = 0;
    if (rawHistoryId is int) {
      parsedId = rawHistoryId;
    } else if (rawHistoryId != null) {
      parsedId = int.tryParse(rawHistoryId.toString()) ?? 0;
    }

    final balance = readNum(json, ['balance', 'amount']);

    return WalletHistoryModel(
      historyId: parsedId,
      objectId: readString(json, ['object_id']),
      title: readString(json, ['title'], fallback: 'Biến động số dư'),
      detail: readString(json, ['detail', 'description']),
      balance: balance,
      date: readString(json, ['date', 'created_at', 'createdAt']),
      type: readString(json, [
        'type',
      ], fallback: balance >= 0 ? 'income' : 'expense'),
    );
  }

  MarketplaceItem toItem() {
    return MarketplaceItem(
      id: historyId.toString(),
      title: title,
      subtitle: date,
      trailing: balance.toString(),
    );
  }
}
