import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'sms_model.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  Future<List<RawSmsMessage>> fetchMpesaSms() async {
    try {
      // Fetch all SMS and filter manually — telephony LIKE filter is unreliable on some devices
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      );

      if (messages.isEmpty) return [];

      final result = <RawSmsMessage>[];

      for (final msg in messages) {
        final address = (msg.address ?? '').toUpperCase();
        final body = msg.body ?? '';

        // Strict M-PESA sender filter
        if (!address.contains('MPESA') && !address.contains('M-PESA')) continue;
        if (body.isEmpty) continue;

        final date = msg.date;
        final timestamp = date != null
            ? DateTime.fromMillisecondsSinceEpoch(date)
            : DateTime.now();

        result.add(RawSmsMessage(
          sender: msg.address ?? 'MPESA',
          body: body,
          timestamp: timestamp,
        ));
      }

      result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return result;
    } catch (e) {
      debugPrint('[SmsService] Error fetching SMS: $e');
      return [];
    }
  }
}