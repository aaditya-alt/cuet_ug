import 'package:cuet/providers/du_community_service.dart';
import '../../providers/du_tracker_provider.dart';
import '../../providers/du_campus_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/notification_service.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/du_preference_service.dart';
import '../../models/du_models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeCategory = 'communications';
  String _activePanel = 'notifications';

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

  // CSAS Tracker Deadline Controllers
  final _trackerP1Controller = TextEditingController(text: '2026-06-15 23:59:59');
  final _trackerP2Controller = TextEditingController(text: '2026-07-05 23:59:59');
  final _trackerP3Controller = TextEditingController(text: '2026-07-20 23:59:59');
  bool _isSavingDeadlines = false;

  // Campus Hub Form Controllers
  final _campusFormKey = GlobalKey<FormState>();
  final _campusCollegeNameController = TextEditingController();
  final _campusNearestMetroController = TextEditingController();
  final _campusWalkingDistanceController = TextEditingController(text: '10');
  final _campusRickshawFareController = TextEditingController(text: '10');
  final _campusPgRentController = TextEditingController(text: '10000');
  final _campusDescriptionController = TextEditingController();
  String _campusSelectedType = 'North';
  String _campusSelectedLine = 'Yellow';
  double _campusSelectedSafety = 4.8;
  bool _isPublishingCampusGuide = false;

  // Preference sheets tab variables
  List<DuPreferenceSheet> _adminSheets = [];
  bool _isLoadingSheets = false;

  // Chat Mod tab variables
  List<CommunityMessage> _adminMessages = [];
  String _selectedModChannel = 'All';
  bool _isLoadingMessages = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _fetchUsers();
    _fetchPreferenceSheets();
    _fetchCommunityMessages();
    Provider.of<DuCampusService>(context, listen: false).fetchGuides();
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
    _trackerP1Controller.dispose();
    _trackerP2Controller.dispose();
    _trackerP3Controller.dispose();
    _campusCollegeNameController.dispose();
    _campusNearestMetroController.dispose();
    _campusWalkingDistanceController.dispose();
    _campusRickshawFareController.dispose();
    _campusPgRentController.dispose();
    _campusDescriptionController.dispose();
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
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'DUVerse Admin Portal 👑',
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
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // ── Tier 1: Main Category Segments ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161C24) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  _buildCategorySegment(
                    label: 'COMMUNS',
                    icon: LucideIcons.messageSquare,
                    category: 'communications',
                    defaultPanel: 'notifications',
                    theme: theme,
                  ),
                  _buildCategorySegment(
                    label: 'ACADEMICS',
                    icon: LucideIcons.bookOpen,
                    category: 'academics',
                    defaultPanel: 'study_material',
                    theme: theme,
                  ),
                  _buildCategorySegment(
                    label: 'CORE SYSTEM',
                    icon: LucideIcons.settings,
                    category: 'system',
                    defaultPanel: 'timeline',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Tier 2: Sub-Panel Chips ──────────────────────────────────────
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _buildSubPanelChips(theme),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── Selected Dashboard Panel Content ──────────────────────────────
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0D121B) : const Color(0xFFFAF9FF),
              child: _buildSelectedPanel(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySegment({
    required String label,
    required IconData icon,
    required String category,
    required String defaultPanel,
    required ThemeData theme,
  }) {
    final isSelected = _activeCategory == category;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeCategory = category;
            _activePanel = defaultPanel;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 16, 
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected 
                      ? Colors.white 
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSubPanelChips(ThemeData theme) {
    if (_activeCategory == 'communications') {
      return [
        _buildChip(
          label: 'Announcements Publisher',
          icon: LucideIcons.bell,
          panel: 'notifications',
          theme: theme,
        ),
        _buildChip(
          label: 'Dashboard Banners',
          icon: LucideIcons.image,
          panel: 'banners',
          theme: theme,
        ),
        _buildChip(
          label: 'Community Chats Moderator',
          icon: LucideIcons.messageSquare,
          panel: 'forums',
          theme: theme,
        ),
      ];
    } else if (_activeCategory == 'academics') {
      return [
        _buildChip(
          label: 'Study Guides Panel',
          icon: LucideIcons.bookOpen,
          panel: 'study_material',
          theme: theme,
        ),
        _buildChip(
          label: 'Preference Sheets Auditor',
          icon: LucideIcons.listOrdered,
          panel: 'preference_sheets',
          theme: theme,
        ),
      ];
    } else {
      return [
        _buildChip(
          label: 'CSAS Timeline Planner',
          icon: LucideIcons.calendar,
          panel: 'timeline',
          theme: theme,
        ),
        _buildChip(
          label: 'Campus guides Moderator',
          icon: LucideIcons.mapPin,
          panel: 'campus_guides',
          theme: theme,
        ),
        _buildChip(
          label: 'System configurations',
          icon: LucideIcons.sliders,
          panel: 'config',
          theme: theme,
        ),
        _buildChip(
          label: 'Student Directory',
          icon: LucideIcons.users,
          panel: 'users',
          theme: theme,
        ),
      ];
    }
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required String panel,
    required ThemeData theme,
  }) {
    final isSelected = _activePanel == panel;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon, 
          size: 14, 
          color: isSelected ? Colors.white : theme.colorScheme.primary,
        ),
        label: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
          ),
        ),
        selected: isSelected,
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.cardColor,
        onSelected: (val) {
          if (val) setState(() => _activePanel = panel);
        },
      ),
    );
  }

  Widget _buildSelectedPanel(ThemeData theme) {
    switch (_activePanel) {
      case 'notifications':
        return _buildAnnouncementsTab(theme);
      case 'banners':
        return _buildBannersTab(theme);
      case 'forums':
        return _buildChatModTab(theme);
      case 'study_material':
        return _buildGuideTab(theme);
      case 'preference_sheets':
        return _buildPreferenceSheetsTab(theme);
      case 'timeline':
        return _buildTimelineTab(theme);
      case 'campus_guides':
        return _buildCampusHubModTab(theme);
      case 'config':
        return _buildConfigTab(theme);
      case 'users':
        return _buildUsersTab(theme);
      default:
        return _buildAnnouncementsTab(theme);
    }
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
          Text(
            'Push Dashboard Banner',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                      decoration: const InputDecoration(
                        labelText: 'Banner Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bannerSubtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bannerActionUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Action URL (Optional Deep Link)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bannerBgColorController,
                      decoration: const InputDecoration(
                        labelText: 'Background Hex Color (e.g. #FF5555)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isPublishingBanner ? null : _publishBanner,
                        icon: _isPublishingBanner
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.send),
                        label: Text(
                          _isPublishingBanner
                              ? 'Publishing...'
                              : 'Publish Banner',
                        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Banner published!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          Text(
            'Add Timeline Event',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _timelineDateController,
                            decoration: const InputDecoration(
                              labelText: 'Date (e.g. 28 May 2026)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _timelineTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Time (e.g. 11:00 AM)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timelineDescController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timelineSortController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sort Order (0, 1, 2...)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isPublishingTimeline
                            ? null
                            : _publishTimelineEvent,
                        icon: _isPublishingTimeline
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.calendarPlus),
                        label: Text(
                          _isPublishingTimeline ? 'Adding...' : 'Add Event',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            'Configure CSAS Target Deadlines',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Modify the real-time countdown targets shown to students across all tracker checkpoints.',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    controller: _trackerP1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Phase 1 Target Deadline (YYYY-MM-DD HH:MM:SS)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.calendar),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _trackerP2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Phase 2 Target Deadline (YYYY-MM-DD HH:MM:SS)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.calendar),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _trackerP3Controller,
                    decoration: const InputDecoration(
                      labelText: 'Phase 3 Target Deadline (YYYY-MM-DD HH:MM:SS)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.calendar),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSavingDeadlines ? null : () async {
                        setState(() => _isSavingDeadlines = true);
                        try {
                          final p1 = DateTime.parse(_trackerP1Controller.text.trim());
                          final p2 = DateTime.parse(_trackerP2Controller.text.trim());
                          final p3 = DateTime.parse(_trackerP3Controller.text.trim());

                          final success = await Provider.of<DuTrackerProvider>(context, listen: false)
                              .updateDeadlines(p1: p1, p2: p2, p3: p3);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success 
                                    ? 'Admissions deadlines synced & updated successfully!' 
                                    : 'Updated locally (Supabase table connection skipped).'),
                                backgroundColor: success ? Colors.green : Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invalid Date/Time Format: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isSavingDeadlines = false);
                          }
                        }
                      },
                      icon: _isSavingDeadlines
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.save),
                      label: Text(
                        _isSavingDeadlines ? 'Saving & Syncing...' : 'Save & Sync Target Deadlines',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Timeline event added!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade200,
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
                          content: Text(
                            val
                                ? 'Premium features tab enabled system-wide! 👑'
                                : 'Premium features tab disabled system-wide!',
                          ),
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

  Future<void> _fetchPreferenceSheets() async {
    if (!mounted) return;
    setState(() => _isLoadingSheets = true);
    try {
      final sheets = await Provider.of<DuPreferenceService>(
        context,
        listen: false,
      ).fetchAllSheetsForAdmin();
      if (mounted) {
        setState(() {
          _adminSheets = sheets;
          _isLoadingSheets = false;
        });
      }
    } catch (e) {
      debugPrint('Admin error fetching sheets: $e');
      if (mounted) {
        // Fallback to local storage sheets so admin can test offline/local fallback!
        final localService = Provider.of<DuPreferenceService>(
          context,
          listen: false,
        );
        await localService.loadLocalSheets();
        setState(() {
          _adminSheets = localService.localSheets;
          _isLoadingSheets = false;
        });
      }
    }
  }

  void _confirmDeleteSheet(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              'Delete Report?',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this student\'s preference sheet report?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );
              await Provider.of<DuPreferenceService>(
                context,
                listen: false,
              ).deleteSheet(id, fromSupabaseOnly: true);
              if (mounted) {
                Navigator.pop(context);
                _fetchPreferenceSheets();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewGeneratedSheet(DuPreferenceSheet sheet) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sheet.userName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            sheet.userEmail,
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: sheet.sheetData.length,
                    itemBuilder: (context, index) {
                      final item = sheet.sheetData[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF161C24)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index < 3
                                    ? theme.colorScheme.primary
                                    : Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.outfit(
                                  color: index < 3
                                      ? Colors.white
                                      : theme.textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['collegeName'] ?? '',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['programName'] ?? '',
                                    style: GoogleFonts.outfit(
                                      color: theme.colorScheme.secondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySheetsState() {
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
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.listOrdered,
                  size: 64,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Generated Sheets Yet',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh. Once students generate preference sheets in the app, their customized reports will appear here in real-time!',
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

  Widget _buildPreferenceSheetsTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF161C24) : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Preference Sheet Reports',
                style: GoogleFonts.outfit(
                  fontSize: 16,
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
                  '${_adminSheets.length} Generated',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchPreferenceSheets,
            child: _isLoadingSheets && _adminSheets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _adminSheets.isEmpty
                ? _buildEmptySheetsState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _adminSheets.length,
                    itemBuilder: (context, index) {
                      final sheet = _adminSheets[index];
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sheet.userName,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sheet.userEmail,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDate(sheet.createdAt),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                _buildSheetBadge(
                                  'Campus',
                                  sheet.campusPreference,
                                  Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                _buildSheetBadge(
                                  'Priority',
                                  sheet.priorityFactor,
                                  Colors.blue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Target Courses:',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: sheet.targetCourses.map((c) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    c,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _viewGeneratedSheet(sheet),
                                    icon: const Icon(LucideIcons.eye, size: 16),
                                    label: const Text('View Full List'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteSheet(sheet.id),
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

  Future<void> _fetchCommunityMessages() async {
    if (!mounted) return;
    setState(() => _isLoadingMessages = true);
    try {
      final messages = await Provider.of<DuCommunityService>(
        context,
        listen: false,
      ).fetchAllMessagesForAdmin();
      if (mounted) {
        setState(() {
          _adminMessages = messages;
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      debugPrint('Admin error fetching messages: $e');
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  void _confirmDeleteMessage(CommunityMessage msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(LucideIcons.alertTriangle, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Remove Message?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this message by "${msg.userName}" from the Community Hub?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );
              await Provider.of<DuCommunityService>(
                context,
                listen: false,
              ).deleteMessage(msg.id, msg.channel);
              if (mounted) {
                Navigator.pop(context);
                _fetchCommunityMessages();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _getChannelColor(String channel) {
    switch (channel) {
      case 'general':
        return Colors.indigo;
      case 'commerce':
        return Colors.green;
      case 'science':
        return Colors.orange;
      case 'humanities':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }

  Widget _buildChatModTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    final filteredMessages = _adminMessages.where((msg) {
      if (_selectedModChannel == 'All') return true;
      return msg.channel == _selectedModChannel.toLowerCase();
    }).toList();

    return Column(
      children: [
        // Channel filter header
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF161C24) : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Moderation Hub',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _selectedModChannel,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(16),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                items: ['All', 'General', 'Commerce', 'Science', 'Humanities']
                    .map((ch) {
                      return DropdownMenuItem<String>(
                        value: ch,
                        child: Text(ch),
                      );
                    })
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedModChannel = val);
                  }
                },
              ),
            ],
          ),
        ),

        // Messages Mod List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchCommunityMessages,
            child: _isLoadingMessages && filteredMessages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredMessages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.messageSquare,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Messages Found',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No messages match the active channel filter, or no messages have been generated yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredMessages.length,
                    itemBuilder: (context, index) {
                      final msg = filteredMessages[index];
                      final badgeColor = _getChannelColor(msg.channel);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            msg.userName,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              msg.channel.toUpperCase(),
                                              style: GoogleFonts.outfit(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: badgeColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        msg.userEmail,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _confirmDeleteMessage(msg),
                                  tooltip: 'Delete and Moderate Message',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF161C24)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                msg.message,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                _formatDate(msg.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
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

  Widget _buildCampusHubModTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final campusService = Provider.of<DuCampusService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campus Hub content manager',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create or moderate illustrated PG rentals and metro transit guides in real-time.',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Add / Edit Form Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _campusFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _campusCollegeNameController,
                      decoration: const InputDecoration(
                        labelText: 'College Name',
                        hintText: 'E.g. Shri Ram College of Commerce (SRCC)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.school),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _campusSelectedType,
                            decoration: const InputDecoration(
                              labelText: 'Campus Cluster',
                              border: OutlineInputBorder(),
                            ),
                            items: ['North', 'South', 'Off'].map((c) {
                              return DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _campusSelectedType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _campusSelectedLine,
                            decoration: const InputDecoration(
                              labelText: 'Metro Line',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Yellow', 'Pink', 'Violet', 'Blue'].map((c) {
                              return DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _campusSelectedLine = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _campusNearestMetroController,
                      decoration: const InputDecoration(
                        labelText: 'Nearest Metro Station',
                        hintText: 'E.g. Vishwa Vidyalaya',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.train),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _campusWalkingDistanceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Walking Distance (mins)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _campusRickshawFareController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Rickshaw Fare (₹)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _campusPgRentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Avg PG Rent (₹)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<double>(
                      value: _campusSelectedSafety,
                      decoration: const InputDecoration(
                        labelText: 'Safety Index / Rating',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.shieldCheck),
                      ),
                      items: [4.0, 4.2, 4.5, 4.7, 4.8, 5.0].map((s) {
                        return DropdownMenuItem<double>(
                          value: s,
                          child: Text('$s / 5.0 Safety Rating'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _campusSelectedSafety = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _campusDescriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Transit & PG Description details',
                        hintText: 'Mention PG localities nearby, shared rickshaw details, or tips...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isPublishingCampusGuide ? null : () async {
                          if (!_campusFormKey.currentState!.validate()) return;
                          setState(() => _isPublishingCampusGuide = true);

                          final college = _campusCollegeNameController.text.trim();
                          final id = '${college.split(' ').first.toLowerCase()}_guide_${DateTime.now().millisecondsSinceEpoch}';

                          final newItem = CampusGuideItem(
                            id: id,
                            collegeName: college,
                            campusType: _campusSelectedType.toLowerCase(),
                            nearestMetro: _campusNearestMetroController.text.trim(),
                            metroLine: _campusSelectedLine,
                            walkingDistanceMins: int.tryParse(_campusWalkingDistanceController.text) ?? 10,
                            eRickshawFare: int.tryParse(_campusRickshawFareController.text) ?? 10,
                            avgPgRent: int.tryParse(_campusPgRentController.text) ?? 10000,
                            safetyIndex: _campusSelectedSafety,
                            description: _campusDescriptionController.text.trim(),
                          );

                          final success = await Provider.of<DuCampusService>(context, listen: false)
                              .addOrUpdateGuide(newItem);

                          setState(() => _isPublishingCampusGuide = false);

                          if (mounted) {
                            _campusCollegeNameController.clear();
                            _campusNearestMetroController.clear();
                            _campusDescriptionController.clear();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success 
                                    ? 'Campus guide details published successfully!' 
                                    : 'Updated locally (Supabase table connection skipped).'),
                                backgroundColor: success ? Colors.green : Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: _isPublishingCampusGuide
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(LucideIcons.plusCircle),
                        label: Text(
                          _isPublishingCampusGuide ? 'Publishing...' : 'Publish Guide Card',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Active guides list
          Text(
            'Active Campus Guide Cards',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          campusService.guides.isEmpty
              ? const Center(child: Text('No guides active.'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: campusService.guides.length,
                  itemBuilder: (context, index) {
                    final g = campusService.guides[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.collegeName,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Metro: ${g.nearestMetro} (${g.metroLine} Line) | PG: ₹${g.avgPgRent}',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                            onPressed: () async {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Guide Card?'),
                                  content: Text('Are you sure you want to permanently delete the campus guide for "${g.collegeName}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await Provider.of<DuCampusService>(context, listen: false).deleteGuide(g.id);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

