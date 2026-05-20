import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/college_model.dart';
import 'package:provider/provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/du_wishlist_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/mock_data.dart';

class WishlistTab extends StatefulWidget {
  const WishlistTab({super.key});

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final wishlist = wishlistProvider.wishlist;
    final duWishlist = Provider.of<DuWishlistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Preference List'),
            Tab(text: 'Predictor Saved'),
          ],
        ),
        actions: [
          if (_tabController.index == 0 && wishlist.isNotEmpty) ...[
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear List?'),
                    content: const Text(
                      'Are you sure you want to remove all colleges from your preference list?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          wishlistProvider.clearWishlist();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All colleges removed from list'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(LucideIcons.trash2, color: Colors.grey),
              tooltip: 'Clear All',
            ),
            IconButton(
              onPressed: () {
                final names = wishlist.map((c) => Uri.encodeComponent(c.name)).join(',');
                final shareUrl =
                    'https://cuet.collegemitra.net.in/wishlist?names=$names';
                String text =
                    '🎒 Check out my DU CUET UG Preference List! 🎓\n\n';
                for (int i = 0; i < wishlist.length; i++) {
                  text +=
                      '${i + 1}. ${wishlist[i].name} (${wishlist[i].campus})\n';
                }
                text +=
                    '\n🔗 Open and import my preference list inside the app:\n$shareUrl\n\n';
                text +=
                    '🔥 Predict your own dream college with 99% accuracy using DU Cutoff Predictor 2025! Find out your chances instantly!';
                Share.share(text);
              },
              icon: const Icon(LucideIcons.share2),
              tooltip: 'Share List',
            ),
          ] else if (_tabController.index == 1 &&
              duWishlist.items.isNotEmpty) ...[
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Predictor List?'),
                    content: const Text(
                      'Are you sure you want to remove all saved colleges from your predictor list?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          duWishlist.clear();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All predictor colleges removed'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(LucideIcons.trash2, color: Colors.grey),
              tooltip: 'Clear All',
            ),
            IconButton(
              onPressed: () {
                final items = duWishlist.items;
                final names = items.map((i) => Uri.encodeComponent(i.collegeName)).join(',');
                final shareUrl =
                    'https://cuet.collegemitra.net.in/wishlist?names=$names';
                String text =
                    '🎓 Check out my DU CUET UG College Predictor Saved List! 🎯\n\n';
                for (int i = 0; i < items.length; i++) {
                  final item = items[i];
                  text += '${i + 1}. ${item.collegeName}\n';
                  if (item.programs.isNotEmpty) {
                    text +=
                        '   • ${item.programs.map((p) => '${p.name} (${p.chance})').join(', ')}\n';
                  }
                }
                text +=
                    '\n🔗 Open and import my preference list inside the app:\n$shareUrl\n\n';
                text +=
                    '🔥 Predict your own dream college with 99% accuracy using DU Cutoff Predictor 2025!';
                Share.share(text);
              },
              icon: const Icon(LucideIcons.share2),
              tooltip: 'Share List',
            ),
          ],
        ],
      ),
      // ── TabBarView needs exactly 2 children matching the 2 tabs ──
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: Preference List ────────────────────────────────
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.listOrdered,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preference List Strategy',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Your top choices should be at the top. DU will allot seats based on this order.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    final wishlist = wishlistProvider.wishlist;
                    if (wishlist.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.heart,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your Preference List is Empty',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Explore colleges in the Cutoff Explorer, open\ndetails, and tap "Add to List" or "❤️" to build\nyour custom ordered Preference List.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: wishlist.length,
                      onReorder: wishlistProvider.reorderWishlist,
                      itemBuilder: (context, index) {
                        final college = wishlist[index];
                        final theme = Theme.of(context);
                        return Dismissible(
                          key: Key(college.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              LucideIcons.trash2,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            wishlistProvider.toggleWishlist(college);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${college.name} removed'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () =>
                                      wishlistProvider.toggleWishlist(college),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            key: Key('item_$index'),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                width: 50,
                                height: 50,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.building2,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                college.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${college.campus} • ${college.type}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: const Icon(
                                LucideIcons.gripVertical,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // ── TAB 2: Predictor Saved ────────────────────────────────
          Consumer<DuWishlistProvider>(
            builder: (context, duWishlist, child) {
              final items = duWishlist.items;
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.bookmark,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Predictor Results Saved',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Heart colleges in the Predictor results\nto save them here for later.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final theme = Theme.of(context);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: item.logoUrl != null
                                    ? Image.network(
                                        item.logoUrl!,
                                        fit: BoxFit.contain,
                                      )
                                    : const Icon(
                                        LucideIcons.building2,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.collegeName,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (item.campusType != null)
                                      Text(
                                        item.campusType!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Find/resolve college from MockData
                              Builder(
                                builder: (context) {
                                  final resolvedCollege = MockData.colleges.firstWhere(
                                    (c) =>
                                        c.name.toLowerCase() ==
                                        item.collegeName.toLowerCase(),
                                    orElse: () => CollegeModel(
                                      id: item.collegeName
                                          .toLowerCase()
                                          .replaceAll(
                                            RegExp(r'[^a-z0-9]'),
                                            '_',
                                          ),
                                      name: item.collegeName,
                                      campus: item.campusType ?? 'Off Campus',
                                      type: 'Government',
                                      gender: 'Co-ed',
                                      logoUrl:
                                          item.logoUrl ??
                                          'https://upload.wikimedia.org/wikipedia/en/4/41/DU_logo.png',
                                      photos: const [],
                                      nirfRanking: 999,
                                      courses: const [],
                                      description:
                                          'A constituent college of Delhi University.',
                                      address: 'University of Delhi, Delhi',
                                      nearbyMetro: 'N/A',
                                      rankings: const [],
                                      facilities: const [],
                                    ),
                                  );
                                  final inPreferenceList = wishlistProvider
                                      .isInWishlist(resolvedCollege.id);

                                  return IconButton(
                                    icon: Icon(
                                      inPreferenceList
                                          ? LucideIcons.checkCircle2
                                          : LucideIcons.listPlus,
                                      color: inPreferenceList
                                          ? Colors.green
                                          : Colors.grey.shade500,
                                      size: 20,
                                    ),
                                    tooltip: inPreferenceList
                                        ? 'Added to Preference List'
                                        : 'Add to Preference List',
                                    onPressed: () {
                                      wishlistProvider.toggleWishlist(
                                        resolvedCollege,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            inPreferenceList
                                                ? '${resolvedCollege.name} removed from Preference List'
                                                : '${resolvedCollege.name} added to Preference List 📋',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  LucideIcons.trash2,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () {
                                  duWishlist.removeByName(item.collegeName);
                                },
                              ),
                            ],
                          ),
                          if (item.programs.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            ...item.programs
                                .take(2)
                                .map(
                                  (p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (p.chance == 'High Chance' ||
                                                    p.chance == 'Safe')
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.orange.withOpacity(
                                                    0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            p.chance,
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  (p.chance == 'High Chance' ||
                                                      p.chance == 'Safe')
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            if (item.programs.length > 2)
                              Text(
                                '+ ${item.programs.length - 2} more programs',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: wishlist.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preferences saved successfully!'),
                  ),
                );
              },
              icon: const Icon(LucideIcons.save),
              label: Text(
                'Save Preferences',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
