import 'dart:convert';

class DigitalSignature {
  final String primaryKey;
  final String publicKey;
  final String signature;
  final DateTime timeExecuted;
  final String message;

  DigitalSignature({
    required this.primaryKey,
    required this.publicKey,
    required this.signature,
    required this.timeExecuted,
    required this.message,
  });

  factory DigitalSignature.fromJson(Map<String, dynamic> json) {
    return DigitalSignature(
      primaryKey: json['primaryKey'],
      publicKey: json['publicKey'],
      signature: json['signature'],
      timeExecuted: DateTime.parse(json['timeExecuted']),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryKey': primaryKey,
      'publicKey': publicKey,
      'signature': signature,
      'timeExecuted': timeExecuted.toIso8601String(),
      'message': message,
    };
  }
}
