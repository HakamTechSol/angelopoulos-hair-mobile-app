import 'package:flutter/material.dart';
import 'package:loyalty_app/Services/language_service.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5; // Equal width for all 5 icons

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: localizations.home,
                width: itemWidth,
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.card_giftcard_outlined,
                activeIcon: Icons.card_giftcard,
                label: localizations.rewards,
                width: itemWidth,
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.qr_code_scanner_outlined,
                activeIcon: Icons.qr_code_scanner,
                label: localizations.scan,
                isCenter: true,
                width: itemWidth,
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: Icons.notifications_none_outlined,
                activeIcon: Icons.notifications,
                label: localizations.alerts,
                width: itemWidth,
              ),
              _buildNavItem(
                context,
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: localizations.account,
                width: itemWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required double width,
    bool isCenter = false,
  }) {
    final isSelected = currentIndex == index;

    return SizedBox(
      width: width, // Fixed equal width — keeps center perfectly aligned
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: isCenter ? 8 : 6,
            vertical: isCenter ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isCenter ? Colors.black : Colors.black.withOpacity(0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(isCenter ? 30 : 12),
            boxShadow: isSelected && isCenter
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? (isCenter ? Colors.white : Colors.black)
                      : Colors.grey.shade600,
                  size: isCenter ? 28 : 22,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isCenter ? Colors.white : Colors.black)
                        : Colors.grey.shade600,
                  ),
                  child: Text(label, maxLines: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
