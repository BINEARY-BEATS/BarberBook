import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_keys.dart';
import '../models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

class ChatRepository {
  ChatRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection(FirestoreKeys.conversations);

  /// Deterministic id so customer↔barber share one thread.
  String conversationIdFor({
    required String barberId,
    required String customerId,
  }) {
    return '${barberId}_$customerId';
  }

  Future<String> getOrCreateConversation({
    required String barberId,
    required String customerId,
  }) async {
    final id = conversationIdFor(barberId: barberId, customerId: customerId);
    final ref = _conversations.doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        FirestoreKeys.conversationParticipantIds: [barberId, customerId],
        FirestoreKeys.conversationBarberId: barberId,
        FirestoreKeys.conversationCustomerId: customerId,
        FirestoreKeys.conversationLastMessage: '',
        FirestoreKeys.conversationUpdatedAt: FieldValue.serverTimestamp(),
        FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  Stream<List<ConversationModel>> watchInbox(String uid) {
    return _conversations
        .where(FirestoreKeys.conversationParticipantIds, arrayContains: uid)
        .orderBy(FirestoreKeys.conversationUpdatedAt, descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ConversationModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<ChatMessageModel>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection(FirestoreKeys.messages)
        .orderBy(FirestoreKeys.messageCreatedAt)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatMessageModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final batch = _db.batch();
    final msgRef = _conversations
        .doc(conversationId)
        .collection(FirestoreKeys.messages)
        .doc();
    batch.set(msgRef, {
      FirestoreKeys.messageSenderId: senderId,
      FirestoreKeys.messageText: trimmed,
      FirestoreKeys.messageCreatedAt: FieldValue.serverTimestamp(),
    });
    batch.update(_conversations.doc(conversationId), {
      FirestoreKeys.conversationLastMessage: trimmed,
      FirestoreKeys.conversationUpdatedAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<ConversationModel?> getConversation(String id) async {
    final snap = await _conversations.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return ConversationModel.fromMap(snap.id, snap.data()!);
  }
}
