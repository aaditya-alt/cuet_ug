import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/notification_service.dart';
import '../../providers/app_settings_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Notification Form Controllers
  final _notifyFormKey = GlobalKey<FormState>();
  final _mainTextController = TextEditingController();
  final _subTextController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublishingNotification = false;

  // Guide Form Controllers
  final _guideFormKey = GlobalKey<FormState>();
  final _guideTitleController = TextEditingController();
  final _guideContentController = TextEditingController();
  String _selectedCategory = 'CSAS Guide';
  bool _isPublishingGuide = false;

  // Users Tab Variables & Controllers
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoadingUsers = false;
  final _searchController = TextEditingController();

  // Banner Form Controllers
  final _bannerFormKey = GlobalKey<FormState>();
  final _bannerTitleController = TextEditingController();
  final _bannerSubtitleController = TextEditingController();
  final _bannerActionUrlController = TextEditingController();
  final _bannerBgColorController = TextEditingController(text: '#3498FF');
  bool _isPublishingBanner = false;

  // Timeline Form Controllers
  final _timelineFormKey = GlobalKey<FormState>();
  final _timelineTitleController = TextEditingController();
  final _timelineDateController = TextEditingController();
  final _timelineTimeController = TextEditingController();
  final _timelineDescController = TextEditingController();
  final _timelineSortController = TextEditingController(text: '0');
  bool _isPublishingTimeline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mainTextController.dispose();
    _subTextController.dispose();
    _descriptionController.dispose();
    _guideTitleController.dispose();
    _guideContentController.dispose();
    _bannerTitleController.dispose();
    _bannerSubtitleController.dispose();
    _bannerActionUrlController.dispose();
    _bannerBgColorController.dispose();
    _timelineTitleController.dispose();
    _timelineDateController.dispose();
    _timelineTimeController.dispose();
    _timelineDescController.dispose();
    _timelineSortController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_logged_in', false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out of Admin Portal'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingUsers = true);

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .order('created_at', ascending: false);

      if (response != null && response is List) {
        if (mounted) {
          setState(() {
            _users = List<Map<String, dynamic>>.from(response);
            _filteredUsers = _users;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching registered users: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to fetch user list: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  void _filterUsers(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final phone = (user['phone'] ?? '').toString();
        final course = (user['course'] ?? '').toString().toLowerCase();
        return name.contains(q) ||
            email.contains(q) ||
            phone.contains(q) ||
            course.contains(q);
      }).toList();
    });
  }

  Future<void> _publishNotification() async {
    if (_notifyFormKey.currentState!.validate()) {
      setState(() => _isPublishingNotification = true);

      try {
        final client = Supabase.instance.client;

        await client.from('notifications').insert({
          'main_text': _mainTextController.text.trim(),
          'sub_text': _subTextController.text.trim(),
          'description': _descriptionController.text.trim(),
        });

        // Trigger local notification provider reload instantly
        if (mounted) {
          Provider.of<NotificationService>(
            context,
            listen: false,
          ).fetchNotifications();

          _mainTextController.clear();
          _subTextController.clear();
          _descriptionController.clear();

          _showSuccessDialog(
            'Notification Published!',
            'Your announcement was broadcasted successfully to all users.',
          );
        }
      } catch (e) {
        debugPrint('Error publishing notification: $e');
        if (mounted) {
          _showErrorSnackBar('Publishing Failed: ${e.toString()}');
        }
      } finally {
        if (mounted) setState(() => _isPublishingNotification = false);
      }
    }
  }

  Future<void> _publishGuide() async {
    if (_guideFormKey.currentState!.validate()) {
      setState(() => _isPublishingGuide = true);

      try {
        final client = Supabase.instance.client;

        await client.from('updates').insert({
          'title': _guideTitleController.text.trim(),
          'content': _guideContentController.text.trim(),
          'category': _selectedCategory,
        });

        if (mounted) {
          _guideTitleController.clear();
          _guideContentController.clear();

          _showSuccessDialog(
            'CSAS Guide / Update Posted!',
            'The new counselling guide / update is now dynamic inside the app.',
          );
        }
      } catch (e) {
        debugPrint('Error posting guide update: $e');
        if (mounted) {
          // Check if table is missing
          if (e.toString().contains(
            'relation "public.updates" does not exist',
          )) {
            _showSqlMissingDialog();
          } else {
            _showErrorSnackBar('Guide Publishing Failed: ${e.toString()}');
          }
        }
      } finally {
        if (mounted) setState(() => _isPublishingGuide = false);
      }
    }
  }

  void _showSuccessDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(content, style: GoogleFonts.outfit()),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Great'),
          ),
        ],
      ),
    );
  }

  void _showSqlMissingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(
              LucideIcons.alertTriangle,
              color: Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Missing Table "updates"',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'To make guides dynamic, you need to create the "public.updates" table in your Supabase SQL editor.\n\nSql command is documented in the implementation_plan.md artifact.',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E14)
          : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.red),
            onPressed: _handleAdminSignOut,
            tooltip: 'Sign Out Admin',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Study Material'),
            Tab(text: 'Users'),
            Tab(text: 'Banners'),
            Tab(text: 'Timeline'),
            Tab(text: 'Config'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnnouncementsTab(theme),
          _buildGuideTab(theme),
          _buildUsersTab(theme),
          _buildBannersTab(theme),
          _buildTimelineTab(theme),
          _buildConfigTab(theme),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _notifyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Publish Announcements',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sends a dynamic notification with local read tracking to all users.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _mainTextController,
              label: 'Title (main_text)',
              hint: 'E.g. Round 2 Allocation lists are out!',
              icon: LucideIcons.heading,
              validator: (val) => val!.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _subTextController,
              label: 'Short Summary (sub_text)',
              hint: 'A quick 1-sentence recap shown in lists.',
              icon: LucideIcons.fileText,
              validator: (val) => val!.isEmpty ? 'Summary is required' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _descriptionController,
              label: 'Full Description (description)',
              hint: 'Complete, multi-paragraph markdown announcement text...',
              icon: LucideIcons.alignLeft,
              maxLines: 5,
              validator: (val) =>
                  val!.isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isPublishingNotification
                  ? null
                  : _publishNotification,
              icon: const Icon(LucideIcons.send),
              label: Text(
                'Publish Announcement',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _guideFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Post CSAS Guides & Updates',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Publishes structured items for dynamic guides or official alerts.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(LucideIcons.tag, size: 20),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'CSAS Guide',
                  child: Text('CSAS Guide (Dynamic Steps)'),
                ),
                DropdownMenuItem(
                  value: 'Alert',
                  child: Text('Important Alert (Red Highlights)'),
                ),
                DropdownMenuItem(
                  value: 'General Update',
                  child: Text('General counselling updates'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _guideTitleController,
              label: 'Title',
              hint: 'E.g. Phase II Choice filling rules',
              icon: LucideIcons.heading,
              validator: (val) => val!.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _guideContentController,
              label: 'Content Body',
              hint: 'Detailed steps, guidelines, or checklists for students...',
              icon: LucideIcons.alignLeft,
              maxLines: 6,
              validator: (val) =>
                  val!.isEmpty ? 'Content body is required' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isPublishingGuide ? null : _publishGuide,
              icon: const Icon(LucideIcons.filePlus),
              label: Text(
                'Publish Update Card',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        // Summary Stats and Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF161C24) : Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered Users',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_users.length} Total',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, phone, or course...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _filterUsers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0A0E14)
                      : const Color(0xFFF8F9FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // User List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchUsers,
            child: _isLoadingUsers && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? _buildEmptyUsersState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final name = user['name'] ?? 'Anonymous';
                      final email = user['email'] ?? 'No email';
                      final phone = user['phone'] != null
                          ? user['phone'].toString()
                          : 'No phone';
                      final course = user['course'] ?? 'Not specified';
                      final createdAt = user['created_at'] != null
                          ? DateTime.tryParse(user['created_at']) ??
                                DateTime.now()
                          : DateTime.now();

                      final initials = name.isNotEmpty
                          ? name.substring(0, 1).toUpperCase()
                          : 'A';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // User Avatar Circle
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Registered on ${_formatDate(createdAt)}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Course Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    course,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            // Contact details
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.mail,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.copy,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: email),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Email copied to clipboard',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.phone,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    phone,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.copy,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: phone),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Phone number copied to clipboard',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyUsersState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.users,
                  size: 64,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Registered Students',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh or check if students have completed registration in the signup page.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.outfit(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Icon(icon, size: 20),
        ),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildBannersTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Push Dashboard Banner', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _bannerFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _bannerTitleController,
                      decoration: const InputDecoration(labelText: 'Banner Title', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bannerSubtitleController,
                      decoration: const InputDecoration(labelText: 'Subtitle (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bannerActionUrlController,
                      decoration: const InputDecoration(labelText: 'Action URL (Optional Deep Link)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bannerBgColorController,
                      decoration: const InputDecoration(labelText: 'Background Hex Color (e.g. #FF5555)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isPublishingBanner ? null : _publishBanner,
                        icon: _isPublishingBanner
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(LucideIcons.send),
                        label: Text(_isPublishingBanner ? 'Publishing...' : 'Publish Banner'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publishBanner() async {
    if (!_bannerFormKey.currentState!.validate()) return;
    setState(() => _isPublishingBanner = true);
    try {
      await Supabase.instance.client.from('dashboard_banners').insert({
        'title': _bannerTitleController.text,
        'subtitle': _bannerSubtitleController.text,
        'action_url': _bannerActionUrlController.text,
        'bg_color': _bannerBgColorController.text,
      });
      _bannerTitleController.clear();
      _bannerSubtitleController.clear();
      _bannerActionUrlController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner published!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isPublishingBanner = false);
    }
  }

  Widget _buildTimelineTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Timeline Event', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _timelineFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _timelineTitleController,
                      decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _timelineDateController,
                            decoration: const InputDecoration(labelText: 'Date (e.g. 28 May 2026)', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _timelineTimeController,
                            decoration: const InputDecoration(labelText: 'Time (e.g. 11:00 AM)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timelineDescController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timelineSortController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sort Order (0, 1, 2...)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isPublishingTimeline ? null : _publishTimelineEvent,
                        icon: _isPublishingTimeline
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(LucideIcons.calendarPlus),
                        label: Text(_isPublishingTimeline ? 'Adding...' : 'Add Event'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publishTimelineEvent() async {
    if (!_timelineFormKey.currentState!.validate()) return;
    setState(() => _isPublishingTimeline = true);
    try {
      await Supabase.instance.client.from('csas_timeline').insert({
        'title': _timelineTitleController.text,
        'event_date': _timelineDateController.text,
        'event_time': _timelineTimeController.text,
        'description': _timelineDescController.text,
        'sort_order': int.tryParse(_timelineSortController.text) ?? 0,
        'is_completed': false,
      });
      _timelineTitleController.clear();
      _timelineDateController.clear();
      _timelineTimeController.clear();
      _timelineDescController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timeline event added!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isPublishingTimeline = false);
    }
  }
  Widget _buildConfigTab(ThemeData theme) {
    final appSettings = Provider.of<AppSettingsProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Configurations',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toggle system-wide feature flags and access controls locally and remotely.',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161C24) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.crown,
                    color: Colors.amber,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Premium Features Tab',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'When turned on, the "Premium" tab is visible in the bottom navigation bar for all users.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: appSettings.premiumEnabled,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) async {
                    await appSettings.togglePremiumEnabled(val);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val
                              ? 'Premium features tab enabled system-wide! 👑'
                              : 'Premium features tab disabled system-wide!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
