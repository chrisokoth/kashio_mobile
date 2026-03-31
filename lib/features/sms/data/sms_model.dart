class Transaction {
  final String transactionCode;
  final double amount;
  final String type;
  final String? counterpartyName;
  final String? counterpartyPhone;
  final DateTime dateTime;
  final double? balanceAfter;
  final double? transactionCost;
  final String rawMessage;
  final String sender;

  Transaction({
    required this.transactionCode,
    required this.amount,
    required this.type,
    this.counterpartyName,
    this.counterpartyPhone,
    required this.dateTime,
    this.balanceAfter,
    this.transactionCost,
    required this.rawMessage,
    required this.sender,
  });

  bool get isIncome => type == 'RECEIVED';

  bool get isExpense => [
    'SENT', 'WITHDRAWAL', 'PAYBILL', 'BUY_GOODS',
    'AIRTIME', 'MSHWARI_DEPOSIT', 'FULIZA_REPAYMENT',
  ].contains(type);

  String get displayName {
    if (counterpartyName != null && counterpartyName!.isNotEmpty) {
      return counterpartyName!;
    }
    if (counterpartyPhone != null && counterpartyPhone!.isNotEmpty) {
      return counterpartyPhone!;
    }
    return typeLabel;
  }

  String get typeLabel {
    switch (type) {
      case 'SENT': return 'Sent';
      case 'RECEIVED': return 'Received';
      case 'WITHDRAWAL': return 'Withdrawal';
      case 'PAYBILL': return 'Paybill';
      case 'BUY_GOODS': return 'Buy Goods';
      case 'AIRTIME': return 'Airtime';
      case 'POCHI': return 'Pochi La Biashara';
      case 'MSHWARI_DEPOSIT': return 'M-Shwari Deposit';
      case 'MSHWARI_LOAN': return 'M-Shwari Loan';
      case 'FULIZA_CHARGE': return 'Fuliza Charge';
      case 'FULIZA_REPAYMENT': return 'Fuliza Repayment';
      case 'REVERSAL': return 'Reversal';
      case 'GLOBAL': return 'M-PESA Global';
      default: return 'Unknown';
    }
  }

  Map<String, dynamic> toApiJson(String deviceId) {
    return {
      'sender': sender,
      'body': rawMessage,
      'timestamp': dateTime.toIso8601String(),
    };
  }
}

class RawSmsMessage {
  final String sender;
  final String body;
  final DateTime timestamp;

  RawSmsMessage({
    required this.sender,
    required this.body,
    required this.timestamp,
  });
}