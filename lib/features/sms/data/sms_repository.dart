import 'package:telephony/telephony.dart';
import 'sms_model.dart';
import 'sms_service.dart';
import '../domain/parser.dart';

class SmsRepository {
  final SmsService smsService;
  final Telephony _telephony = Telephony.instance;

  SmsRepository({required this.smsService});

  Future<bool> requestPermission() async {
    final granted = await _telephony.requestSmsPermissions;
    return granted ?? false;
  }

  Future<List<Transaction>> getTransactions() async {
    final rawMessages = await smsService.fetchMpesaSms();
    return rawMessages
        .map((raw) => MpesaParser.parse(raw))
        .where((t) => t != null && t.type != 'UNKNOWN')
        .cast<Transaction>()
        .toList();
  }
}