import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_service.dart';
import '../../providers/du_community_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String channelId;
  final String channelTitle;

  const ChatRoomScreen({
    super.key,
    required this.channelId,
    required this.channelTitle,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<DuCommunityService>(context, listen: false);
      service.fetchMessages(widget.channelId).then((_) => _scrollToBottom());
      service.subscribeToChannel(widget.channelId, (_) => _scrollToBottom());
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Client-side moderation check
  bool _containsProfanity(String text) {
    final lower = text.toLowerCase();
    final List<String> flaggedWords = ['abuse', 'scam', 'fake', 'spam', 'fraud', 'cheat', 'crap'];
    return flaggedWords.any((word) => lower.contains(word));
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_containsProfanity(text)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(LucideIcons.shieldAlert, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Community Guidelines'),
            ],
          ),
          content: const Text(
            'Let\'s keep the DUVerse community hub safe, supportive, and clean! Please refrain from using flagged words, spam, or promotional material.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Understand'),
            ),
          ],
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final communityService = Provider.of<DuCommunityService>(context, listen: false);

    final user = authService.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Student';
    final userEmail = user?.email ?? 'No email';

    setState(() => _isSending = true);
    _messageController.clear();

    final success = await communityService.sendMessage(
      channel: widget.channelId,
      userName: userName,
      userEmail: userEmail,
      message: text,
    );

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);
    final communityService = Provider.of<DuCommunityService>(context);

    final currentUserEmail = authService.currentUser?.email ?? '';
    final messages = communityService.channelMessages[widget.channelId] ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.channelTitle,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Realtime Admissions Board',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => communityService.fetchMessages(widget.channelId).then((_) => _scrollToBottom()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner informing about realtime stream
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.green.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.radio, size: 14, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Connected to Realtime Network Gateway',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: communityService.isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.userEmail == currentUserEmail;
                      
                      return _buildMessageBubble(msg, isMe, theme, isDark);
                    },
                  ),
          ),

          // Input Composer
          _buildInputComposer(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(CommunityMessage msg, bool isMe, ThemeData theme, bool isDark) {
    final avatarColor = _getAvatarColor(msg.userName);
    final initials = msg.userName.isNotEmpty ? msg.userName.trim().substring(0, 1).toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: avatarColor,
              child: Text(
                initials,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Username label
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                    child: Text(
                      msg.userName,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                
                // Bubble container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? theme.colorScheme.primary
                        : isDark
                            ? const Color(0xFF161C24)
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
                      height: 1.4,
                    ),
                  ),
                ),
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    _formatTime(msg.createdAt),
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: Text(
                initials,
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputComposer(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C2430) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type an admission query...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _sendMessage,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final hash = name.hashCode;
    final List<Color> colors = [
      Colors.indigo.shade600,
      Colors.teal.shade600,
      Colors.orange.shade700,
      Colors.pink.shade600,
      Colors.blue.shade600,
      Colors.purple.shade600,
    ];
    return colors[hash % colors.length];
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }
}
