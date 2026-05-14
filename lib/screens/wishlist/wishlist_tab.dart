import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/college_model.dart';
import 'package:provider/provider.dart';
import '../../providers/wishlist_provider.dart';

import 'package:share_plus/share_plus.dart';

class WishlistTab extends StatefulWidget {
  const WishlistTab({super.key});

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab> {

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final wishlist = wishlistProvider.wishlist;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Preference List'),
        actions: [
          if (wishlist.isNotEmpty) ...[
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear List?'),
                    content: const Text('Are you sure you want to remove all colleges from your preference list?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
                        child: const Text('Clear All', style: TextStyle(color: Colors.red)),
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
                String text = 'My CUET Preference List:\n\n';
                for (int i = 0; i < wishlist.length; i++) {
                  text += '${i + 1}. ${wishlist[i].name} (${wishlist[i].campus})\n';
                }
                text += '\nCreated using Cuet Predictor app.';
                Share.share(text);
              },
              icon: const Icon(LucideIcons.share2),
              tooltip: 'Share List',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.listOrdered, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preference List Strategy',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Your top choices should be at the top. DU will allot seats based on this order.',
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700),
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
                        Icon(LucideIcons.heart, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Your Preference List is Empty',
                          style: GoogleFonts.outfit(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add colleges from the Predictor results\nto start building your dream list.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
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
                        child: const Icon(LucideIcons.trash2, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        wishlistProvider.toggleWishlist(college);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${college.name} removed'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () => wishlistProvider.toggleWishlist(college),
                            ),
                          ),
                        );
                      },
                      child: Container(
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
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                              ],
                            ),
                            child: Image.network(college.logoUrl, fit: BoxFit.contain),
                          ),
                          title: Text(
                            college.name,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${college.campus} • ${college.type}',
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: const Icon(LucideIcons.gripVertical, color: Colors.grey),
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
      floatingActionButton: wishlist.isNotEmpty 
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preferences saved successfully!'))
                );
              },
              icon: const Icon(LucideIcons.save),
              label: Text('Save Preferences', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
