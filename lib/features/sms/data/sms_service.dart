import 'package:telephony/telephony.dart';
import 'sms_model.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  Future<bool> requestPermission() async {
    final granted = await _telephony.requestSmsPermissions;
    return granted ?? false;
  }

  Future<List<RawSmsMessage>> fetchMpesaSms() async {
    try {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS)
            .like('%MPESA%')
            .or(SmsColumn.ADDRESS)
            .like('%mpesa%'),
      );

      final result = <RawSmsMessage>[];
      for (final msg in messages) {
        final address = msg.address ?? '';
        final body = msg.body ?? '';
        final date = msg.date;

        if (!address.toUpperCase().contains('MPESA')) continue;
        if (body.isEmpty) continue;

        final timestamp = date != null
            ? DateTime.fromMillisecondsSinceEpoch(date)
            : DateTime.now();

        result.add(RawSmsMessage(
          sender: address,
          body: body,
          timestamp: timestamp,
        ));
      }

      // Sort newest first
      result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return result;
    } catch (e) {
      return [];
    }
  }
}