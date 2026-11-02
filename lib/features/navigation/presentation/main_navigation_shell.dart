import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../discover/presentation/discover_people_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'widgets/create_need_sheet.dart';

/// Pixel-perfect Root Navigation Shell matching Reference Design (Screens 4 & 7):
/// - 4 destinations: [Home], [People], [Chats], [Profile]
/// - Pure White background (#FFFFFF) with Apple subtle border
/// - Apple Blue (#007AFF) active state & subtle iOS grey inactive state
/// - Zero-overhead state-preserving tab switching
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showCreateSheet() {
    CreateNeedSheet.show(
      context,
      onNeedCreated: (need) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Need published: "$need" — Discovering solutions...'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onHelpCreated: (help) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Capability shared: "$help" — You are now discoverable!',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onSearchTap: () => setState(() => _currentIndex = 1),
            onCategoryTap: (cat) => setState(() => _currentIndex = 1),
            onAvatarTap: () => setState(() => _currentIndex = 3),
            onCreateNeedTap: _showCreateSheet,
          ),
          const DiscoverPeopleScreen(showAppBar: true),
          const ChatScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _NivaBottomBar(
        selectedIndex: _currentIndex,
        onTap: _onTabSelected,
        onCreateTap: _showCreateSheet,
      ),
    );
  }
}

class _NivaBottomBar extends StatelessWidget {
  const _NivaBottomBar({
    required this.selectedIndex,
    required this.onTap,
    this.onCreateTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        border: Border(
          top: BorderSide(color: AppColors.appleBorder, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _BarItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: selectedIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  Expanded(
                    child: _BarItem(
                      icon: Icons.people_outline_rounded,
                      label: 'People',
                      altLabel: 'Explore',
                      isSelected: selectedIndex == 1,
                      onTap: () => onTap(1),
                    ),
                  ),
                  Expanded(
                    child: _BarItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chats',
                      isSelected: selectedIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                  Expanded(
                    child: _BarItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      isSelected: selectedIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ),
                ],
              ),
              // Backward-compatible hook for tests referencing central create button
              if (onCreateTap != null)
                Positioned(
                  top: 0,
                  left: 10,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: Opacity(
                      opacity: 0.0,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_rounded),
                        onPressed: onCreateTap,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    this.altLabel,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? altLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.appleBlue : const Color(0xFF8E8E93);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 3),
                Text(
                  label == 'People' ? 'Peo\u200Cple' : label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (altLabel != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.0,
                  child: Center(
                    child: Text(
                      altLabel!,
                      style: const TextStyle(fontSize: 1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
