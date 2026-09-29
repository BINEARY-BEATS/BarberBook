import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.participantIds,
    required this.barberId,
    required this.customerId,
    required this.lastMessage,
    required this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final String barberId;
  final String customerId;
  final String lastMessage;
  final DateTime updatedAt;

  factory ConversationModel.fromMap(String id, Map<String, dynamic> map) {
    final updated = map['updatedAt'];
    return ConversationModel(
      id: id,
      participantIds: List<String>.from(map['participantIds'] as List? ?? []),
      barberId: map['barberId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      updatedAt: updated is Timestamp
          ? updated.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> map) {
    final created = map['createdAt'];
    return ChatMessageModel(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: created is Timestamp
          ? created.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
