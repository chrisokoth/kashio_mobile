import 'package:intl/intl.dart';
import '../data/sms_model.dart';

class MpesaParser {
  // ── helpers ──────────────────────────────────────────────────────────────
  static double _cleanDecimal(String? raw) {
    if (raw == null || raw.isEmpty) return 0.0;
    return double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
  }

  static DateTime? _parseDateTime(String? date, String? time) {
    if (date == null || time == null) return null;
    final formats = ['d/M/yyyy h:mm a', 'd/M/yy h:mm a'];
    final combined = '$date $time'.trim();
    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parse(combined);
      } catch (_) {}
    }
    return null;
  }

  static String _normalize(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ── patterns ─────────────────────────────────────────────────────────────

  // REVERSAL
  static final _reversalRx = RegExp(
    r'Transaction ([A-Z0-9]{10,12}) has been reversed',
    caseSensitive: false,
  );

  // FULIZA charge (no tx code)
  static final _fulizaChargeRx = RegExp(
    r'Fuliza M-PESA amount is Ksh([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  // FULIZA repayment
  static final _fulizaRepayRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*) paid to Fuliza M-PESA\.'
    r'.*?on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})'
    r'.*?balance is Ksh([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  // M-Shwari loan
  static final _mshwariLoanRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*) received from M-Shwari loan'
    r'.*?on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})'
    r'.*?balance is Ksh([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  // M-Shwari deposit
  static final _mshwariDepositRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*) transferred to M-Shwari'
    r'.*?on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})'
    r'.*?balance is Ksh([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  // POCHI
  static final _pochiRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*) sent to (0\d{9})'
    r' for Pochi La Biashara on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})'
    r'.*?balance is Ksh([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  // RECEIVED
  static final _receivedRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*You have received Ksh([\d,]+\.?\d*) from'
    r' ([A-Za-z0-9 ]+?) on (\d{1,2}/\d{1,2}/\d{2,4})\s*(\d{1,2}:\d{2} [APM]{2})'
    r'.*?balance is Ksh([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  // PAYBILL (has "for account")
  static final _paybillRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*) sent to'
    r' ([A-Za-z0-9 ]+?) for account ([^\s]+) on'
    r' (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})'
    r'.*?balance is Ksh([\d,]+\.?\d*)'
    r'(?:.*?Transaction cost,\s*Ksh([\d,]+\.?\d*))?',
    caseSensitive: false,
    dotAll: true,
  );

  // BUY GOODS (paid to ... on)
  static final _buyGoodsRx = RegExp(
    r"([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*) paid to"
    r" ([A-Za-z0-9'\- ]+?)\.\s*on (\d{1,2}/\d{1,2}/\d{2,4}) at"
    r" (\d{1,2}:\d{2} [APM]{2}).*?balance is Ksh([\d,]+\.?\d*)"
    r"(?:.*?Transaction cost,\s*Ksh([\d,]+\.?\d*))?",
    caseSensitive: false,
    dotAll: true,
  );

  // AIRTIME
  static final _airtimeRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*)'
    r' (?:sent to (0\d{9}) for airtime|paid for airtime)'
    r'.*?on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})'
    r'.*?balance is Ksh([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  // WITHDRAWAL agent
  static final _withdrawalAgentRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*) withdrawn from'
    r' (\d+) - ([A-Za-z0-9 ]+?) on'
    r' (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})'
    r'.*?balance is Ksh([\d,]+\.?\d*)'
    r'(?:.*?Transaction cost,\s*Ksh([\d,]+\.?\d*))?',
    caseSensitive: false,
    dotAll: true,
  );

  // WITHDRAWAL ATM
  static final _withdrawalAtmRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*) withdrawn from ATM'
    r'.*?on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})'
    r'.*?balance is Ksh([\d,]+\.?\d*)'
    r'(?:.*?Transaction cost,\s*Ksh([\d,]+\.?\d*))?',
    caseSensitive: false,
    dotAll: true,
  );

  // GLOBAL
  static final _globalRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*) sent to'
    r' ([A-Za-z ]+?) via M-PESA Global'
    r'.*?on (\d{1,2}/\d{1,2}/\d{2,4}) at (\d{1,2}:\d{2} [APM]{2})'
    r'.*?balance is Ksh([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  // SENT (most generic — must come last)
  static final _sentRx = RegExp(
    r'([A-Z0-9]{10,12}) Confirmed\.?\s*Ksh([\d,]+\.?\d*) sent to'
    r' ([A-Za-z ]+?)\s*(0\d{9})? on (\d{1,2}/\d{1,2}/\d{2,4}) at'
    r' (\d{1,2}:\d{2} [APM]{2}).*?balance is Ksh([\d,]+\.?\d*)'
    r'(?:.*?Transaction cost,\s*Ksh([\d,]+\.?\d*))?',
    caseSensitive: false,
    dotAll: true,
  );

  // ── public API ────────────────────────────────────────────────────────────

  static Transaction? parse(RawSmsMessage raw) {
    final msg = _normalize(raw.body);
    try {
      return _tryReversal(msg, raw) ??
          _tryFulizaCharge(msg, raw) ??
          _tryFulizaRepay(msg, raw) ??
          _tryMshwariLoan(msg, raw) ??
          _tryMshwariDeposit(msg, raw) ??
          _tryPochi(msg, raw) ??
          _tryReceived(msg, raw) ??
          _tryPaybill(msg, raw) ??
          _tryBuyGoods(msg, raw) ??
          _tryAirtime(msg, raw) ??
          _tryWithdrawalAtm(msg, raw) ??
          _tryWithdrawalAgent(msg, raw) ??
          _tryGlobal(msg, raw) ??
          _trySent(msg, raw) ??
          _fallback(msg, raw);
    } catch (_) {
      return _fallback(msg, raw);
    }
  }

  // ── individual parsers ────────────────────────────────────────────────────

  static Transaction? _tryReversal(String msg, RawSmsMessage raw) {
    final m = _reversalRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: 0,
      type: 'REVERSAL',
      dateTime: raw.timestamp,
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryFulizaCharge(String msg, RawSmsMessage raw) {
    if (!msg.toLowerCase().contains('fuliza m-pesa amount is')) return null;
    final m = _fulizaChargeRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: 'FULIZA-${raw.timestamp.millisecondsSinceEpoch}',
      amount: _cleanDecimal(m.group(1)),
      type: 'FULIZA_CHARGE',
      counterpartyName: 'Fuliza M-PESA',
      dateTime: raw.timestamp,
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryFulizaRepay(String msg, RawSmsMessage raw) {
    final m = _fulizaRepayRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'FULIZA_REPAYMENT',
      counterpartyName: 'Fuliza M-PESA',
      dateTime: _parseDateTime(m.group(3), m.group(4)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(5)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryMshwariLoan(String msg, RawSmsMessage raw) {
    final m = _mshwariLoanRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'MSHWARI_LOAN',
      counterpartyName: 'M-Shwari',
      dateTime: _parseDateTime(m.group(3), m.group(4)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(5)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryMshwariDeposit(String msg, RawSmsMessage raw) {
    final m = _mshwariDepositRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'MSHWARI_DEPOSIT',
      counterpartyName: 'M-Shwari',
      dateTime: _parseDateTime(m.group(3), m.group(4)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(5)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryPochi(String msg, RawSmsMessage raw) {
    final m = _pochiRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'POCHI',
      counterpartyPhone: m.group(3),
      dateTime: _parseDateTime(m.group(4), m.group(5)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(6)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryReceived(String msg, RawSmsMessage raw) {
    final m = _receivedRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'RECEIVED',
      counterpartyName: m.group(3)?.trim(),
      dateTime: _parseDateTime(m.group(4), m.group(5)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(6)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryPaybill(String msg, RawSmsMessage raw) {
    final m = _paybillRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'PAYBILL',
      counterpartyName: m.group(3)?.trim(),
      dateTime: _parseDateTime(m.group(5), m.group(6)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(7)),
      transactionCost: _cleanDecimal(m.group(8)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryBuyGoods(String msg, RawSmsMessage raw) {
    if (RegExp(r'\bfor account\b', caseSensitive: false).hasMatch(msg)) return null;
    if (RegExp(r'fuliza m-pesa', caseSensitive: false).hasMatch(msg)) return null;
    final m = _buyGoodsRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'BUY_GOODS',
      counterpartyName: m.group(3)?.trim(),
      dateTime: _parseDateTime(m.group(4), m.group(5)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(6)),
      transactionCost: _cleanDecimal(m.group(7)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryAirtime(String msg, RawSmsMessage raw) {
    final m = _airtimeRx.firstMatch(msg);
    if (m == null) return null;
    // groups: 1=code, 2=amount, 3=phone(optional), 4=date, 5=time, 6=balance
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'AIRTIME',
      counterpartyPhone: m.group(3),
      dateTime: _parseDateTime(m.group(4), m.group(5)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(6)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryWithdrawalAtm(String msg, RawSmsMessage raw) {
    if (!msg.toLowerCase().contains('withdrawn from atm')) return null;
    final m = _withdrawalAtmRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'WITHDRAWAL',
      counterpartyName: 'ATM',
      dateTime: _parseDateTime(m.group(3), m.group(4)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(5)),
      transactionCost: _cleanDecimal(m.group(6)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryWithdrawalAgent(String msg, RawSmsMessage raw) {
    final m = _withdrawalAgentRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'WITHDRAWAL',
      counterpartyName: '${m.group(3)} - ${m.group(4)?.trim()}',
      dateTime: _parseDateTime(m.group(5), m.group(6)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(7)),
      transactionCost: _cleanDecimal(m.group(8)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _tryGlobal(String msg, RawSmsMessage raw) {
    final m = _globalRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'GLOBAL',
      counterpartyName: m.group(3)?.trim(),
      dateTime: _parseDateTime(m.group(4), m.group(5)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(6)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction? _trySent(String msg, RawSmsMessage raw) {
    if (RegExp(r'\bfor account\b', caseSensitive: false).hasMatch(msg)) return null;
    if (RegExp(r'pochi la biashara', caseSensitive: false).hasMatch(msg)) return null;
    final m = _sentRx.firstMatch(msg);
    if (m == null) return null;
    return Transaction(
      transactionCode: m.group(1)!,
      amount: _cleanDecimal(m.group(2)),
      type: 'SENT',
      counterpartyName: m.group(3)?.trim(),
      counterpartyPhone: m.group(4),
      dateTime: _parseDateTime(m.group(5), m.group(6)) ?? raw.timestamp,
      balanceAfter: _cleanDecimal(m.group(7)),
      transactionCost: _cleanDecimal(m.group(8)),
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }

  static Transaction _fallback(String msg, RawSmsMessage raw) {
    return Transaction(
      transactionCode: 'UNKNOWN-${raw.timestamp.millisecondsSinceEpoch}',
      amount: 0,
      type: 'UNKNOWN',
      dateTime: raw.timestamp,
      rawMessage: raw.body,
      sender: raw.sender,
    );
  }
}