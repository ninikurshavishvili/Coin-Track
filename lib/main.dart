import 'dart:ui';

import 'package:flutter/material.dart';
import "package:flutter_riverpod/flutter_riverpod.dart";

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';

void main() {
  runApp(const ProviderScope(child: CoinTrackApp()));
}

class CoinTrackApp extends StatelessWidget {
  const CoinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoinTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const CoinTrackShell(),
    );
  }
}

class CoinTrackShell extends StatefulWidget {
  const CoinTrackShell({super.key});

  @override
  State<CoinTrackShell> createState() => _CoinTrackShellState();
}

class _CoinTrackShellState extends State<CoinTrackShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          WishlistScreen(onExplore: () => _selectTab(2)),
          const SearchScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _GlassNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }
}

class _GlassNavigationBar extends StatelessWidget {
  const _GlassNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.88),
            border: const Border(
              top: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.star_outline_rounded),
                  selectedIcon: Icon(Icons.star_rounded),
                  label: 'Wishlist',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded),
                  selectedIcon: Icon(Icons.saved_search_rounded),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_circle_outlined),
                  selectedIcon: Icon(Icons.account_circle_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
