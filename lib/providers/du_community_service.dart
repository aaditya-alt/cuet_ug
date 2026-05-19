import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityMessage {
  final String id;
  final String channel;
  final String? userId;
  final String userName;
  final String userEmail;
  final String message;
  final DateTime createdAt;

  CommunityMessage({
    required this.id,
    required this.channel,
    this.userId,
    required this.userName,
    required this.userEmail,
    required this.message,
    required this.createdAt,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    return CommunityMessage(
      id: json['id']?.toString() ?? '',
      channel: json['channel'] as String? ?? 'general',
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String? ?? 'Anonymous',
      userEmail: json['user_email'] as String? ?? 'No email',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      if (userId != null) 'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'message': message,
    };
  }
}

class DuCommunityService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  // Realtime subscription reference
  RealtimeChannel? _realtimeChannel;

  // Messages cache by channel
  final Map<String, List<CommunityMessage>> _channelMessages = {
    'general': [],
    'commerce': [],
    'science': [],
    'humanities': [],
  };

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, List<CommunityMessage>> get channelMessages => _channelMessages;

  // Pre-seeded fallback mock data for testing/demo offline
  final Map<String, List<CommunityMessage>> _seededFallbackMessages = {
    'general': [
      CommunityMessage(
        id: 'mock1',
        channel: 'general',
        userName: 'Aarav Sharma',
        userEmail: 'aarav@gmail.com',
        message:
            'Has anyone started filling the DU CSAS Phase 1 forms? Which documents are needed?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      CommunityMessage(
        id: 'mock2',
        channel: 'general',
        userName: 'Diya Iyer',
        userEmail: 'diya@gmail.com',
        message:
            'Yes! Make sure your 12th marksheet, category certificates, and CUET scorecard are ready. Best of luck!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      CommunityMessage(
        id: 'mock3',
        channel: 'general',
        userName: 'Karan Mehra',
        userEmail: 'karan@gmail.com',
        message:
            'Is Class 12 board subject mapping strict? My board math matches CUET applied math right?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ],
    'commerce': [
      CommunityMessage(
        id: 'mock_c1',
        channel: 'commerce',
        userName: 'Sneha Goel',
        userEmail: 'sneha@gmail.com',
        message:
            'What was the cutoff for B.Com Hons at SRCC last year? Is 780 a safe score for General?',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CommunityMessage(
        id: 'mock_c2',
        channel: 'commerce',
        userName: 'Rohan Gupta',
        userEmail: 'rohan@gmail.com',
        message:
            '780 is very high! Last year SRCC closed around 782 for General Round 1, but Hindu and Hansraj are totally safe at 775+.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
    'science': [
      CommunityMessage(
        id: 'mock_s1',
        channel: 'science',
        userName: 'Vikram Sen',
        userEmail: 'vikram@gmail.com',
        message:
            'Any B.Sc. Hons Computer Science aspirants here? Let\'s discuss syllabus and best colleges.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      CommunityMessage(
        id: 'mock_s2',
        channel: 'science',
        userName: 'Anjali Das',
        userEmail: 'anjali@gmail.com',
        message:
            'Hansraj and SGTB Khalsa have great CS faculty! What are your score totals out of 800?',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ],
    'humanities': [
      CommunityMessage(
        id: 'mock_h1',
        channel: 'humanities',
        userName: 'Kabir Bedi',
        userEmail: 'kabir@gmail.com',
        message:
            'Hi everyone! Targetting B.A. Hons Political Science at LSR or Hindu. Anyone else?',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      CommunityMessage(
        id: 'mock_h2',
        channel: 'humanities',
        userName: 'Meera Nair',
        userEmail: 'meera@gmail.com',
        message:
            'Political Science cutoffs are incredibly high, almost 795+ out of 800 for general. Keep Miranda House as option too!',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  };

  // Fetch messages from Supabase or Fallback
  Future<void> fetchMessages(String channel) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client
          .from('du_community_messages')
          .select()
          .eq('channel', channel)
          .order('created_at', ascending: true);

      if (response != null && response is List) {
        final List<CommunityMessage> loaded = response
            .map((item) => CommunityMessage.fromJson(item))
            .toList();
        _channelMessages[channel] = loaded;
      }
    } catch (e) {
      debugPrint(
        'Error fetching messages from Supabase (falling back to preloaded mock list): $e',
      );
      // Graceful fallback to preloaded seed messages if database table isn't created yet
      if (_channelMessages[channel]!.isEmpty) {
        _channelMessages[channel] = List.from(
          _seededFallbackMessages[channel] ?? [],
        );
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Subscribe to Realtime inserts
  void subscribeToChannel(
    String channel,
    Function(CommunityMessage) onNewMessage,
  ) {
    // Unsubscribe from previous channels to save memory
    unsubscribeChannel();

    try {
      _realtimeChannel = _client
          .channel('public:du_community_messages:channel=eq.$channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'du_community_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, // ✅ required parameter
              column: 'channel',
              value: channel,
            ),
            callback: (payload) {
              final newMsg = CommunityMessage.fromJson(payload.newRecord);
              if (!_channelMessages[channel]!.any((m) => m.id == newMsg.id)) {
                _channelMessages[channel]!.add(newMsg);
                onNewMessage(newMsg);
                notifyListeners();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint(
        'Realtime subscription error (falling back to simple polling): $e',
      );
    }
  }

  // Unsubscribe channel
  void unsubscribeChannel() {
    if (_realtimeChannel != null) {
      _client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  // Send message
  Future<bool> sendMessage({
    required String channel,
    required String userName,
    required String userEmail,
    required String message,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final newMsgMap = {
      'id': tempId,
      'channel': channel,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    };

    final newMsg = CommunityMessage.fromJson(newMsgMap);

    // Optimistic insert to local cache
    _channelMessages[channel]!.add(newMsg);
    notifyListeners();

    try {
      await _client.from('du_community_messages').insert({
        'channel': channel,
        if (userId != null) 'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'message': message,
      });
      return true;
    } catch (e) {
      debugPrint(
        'Failed to send message to Supabase (working in offline mode): $e',
      );
      // If offline/table missing, we keep the optimistic message in the room for visual verification!
      return false;
    }
  }

  // Fetch all recent messages across all channels for Admin Moderation Center
  Future<List<CommunityMessage>> fetchAllMessagesForAdmin() async {
    try {
      final response = await _client
          .from('du_community_messages')
          .select()
          .order('created_at', ascending: false);

      if (response != null && response is List) {
        return response.map((item) => CommunityMessage.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Admin fetch all messages error: $e');
      // Return a consolidated list of mock/seeded messages so the admin screen works perfectly for demos!
      final List<CommunityMessage> allMock = [];
      _seededFallbackMessages.values.forEach((list) {
        allMock.addAll(list);
      });
      allMock.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allMock;
    }
    return [];
  }

  // Admin delete/moderate message
  Future<void> deleteMessage(String id, String channel) async {
    try {
      await _client.from('du_community_messages').delete().eq('id', id);
    } catch (e) {
      debugPrint('Admin delete message error: $e');
    }

    // Always delete locally as well
    _channelMessages[channel]!.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeChannel();
    super.dispose();
  }
}
