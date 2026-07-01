import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/watchlist_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(watchlistProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          112,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CoinTrack User',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$count saved ${count == 1 ? 'coin' : 'coins'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Theme',
            value: 'Dark only',
          ),
          _SettingsTile(
            icon: Icons.attach_money_rounded,
            title: 'Currency',
            value: 'USD',
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'App version',
            value: '1.0.0',
          ),
          _SettingsTile(
            icon: Icons.storage_rounded,
            title: 'Market data',
            value: 'CoinPaprika',
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: count == 0
                ? null
                : () => ref.read(watchlistProvider.notifier).clear(),
            icon: const Icon(Icons.delete_sweep_rounded),
            label: const Text('Clear watchlist'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'About / Data provided by CoinPaprika',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: Text(value, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
