import 'dart:convert';

import 'package:uuid/uuid.dart';

class UserCreativePreset {
  final String id;
  final String name;
  final String type;
  final String sourceItemId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserCreativePreset({
    required this.id,
    required this.name,
    required this.type,
    required this.sourceItemId,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserCreativePreset.create({
    required String name,
    required String type,
    required String sourceItemId,
    required Map<String, dynamic> payload,
  }) {
    final now = DateTime.now();

    return UserCreativePreset(
      id: const Uuid().v4(),
      name: name,
      type: type,
      sourceItemId: sourceItemId,
      payload: payload,
      createdAt: now,
      updatedAt: now,
    );
  }

  String get payloadJson => jsonEncode(payload);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'sourceItemId': sourceItemId,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
