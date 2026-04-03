import 'sms_model.dart';
import 'sms_service.dart';
import '../domain/parser.dart';

class SmsRepository {
  final SmsService smsService;

  SmsRepository({required this.smsService});

  Future<List<Transaction>> getTransactions() async {
    final rawMessages = await smsService.fetchMpesaSms();
    return rawMessages
        .map((raw) => MpesaParser.parse(raw))
        .where((t) => t != null && t.type != 'UNKNOWN')
        .cast<Transaction>()
        .toList();
  }
}