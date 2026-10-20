import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../explore/presentation/explore_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'widgets/create_need_sheet.dart';

/// Root navigation shell managing bottom bar destinations and create modal trigger.
/// Uses IndexedStack for zero-overhead, state-preserving tab switching.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (index == 2) {
      _showCreateSheet();
      return;
    }
    // Map tab indices: 0 -> Home (0), 1 -> Explore (1), 3 -> Chats (2), 4 -> Profile (3)
    final mappedIndex = index > 2 ? index - 1 : index;
    if (_currentIndex != mappedIndex) {
      setState(() {
        _currentIndex = mappedIndex;
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onSearchTap: () => setState(() => _currentIndex = 1),
            onCategoryTap: (cat) => setState(() => _currentIndex = 1),
            onAvatarTap: () => setState(() => _currentIndex = 3),
            onCreateNeedTap: _showCreateSheet,
          ),
          const ExploreScreen(),
          const ChatScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _NivaBottomBar(
        selectedBarIndex: _currentIndex >= 2
            ? _currentIndex + 1
            : _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

class _NivaBottomBar extends StatelessWidget {
  const _NivaBottomBar({required this.selectedBarIndex, required this.onTap});

  final int selectedBarIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _BarItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: selectedBarIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _BarItem(
                  icon: Icons.search_rounded,
                  label: 'Explore',
                  isSelected: selectedBarIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              // Central Create "+" Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onTap(2),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPurple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x335B4BDB),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.textOnPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _BarItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chats',
                  isSelected: selectedBarIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
              Expanded(
                child: _BarItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: selectedBarIndex == 4,
                  onTap: () => onTap(4),
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
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryPurple : AppColors.textTertiary;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.captionSmall.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
