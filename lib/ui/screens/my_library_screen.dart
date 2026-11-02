import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../state/player_provider.dart';
import '../../state/store_provider.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/track_tile.dart';

/// مكتبتي: كل ما حفظته ونزّلته — مرتّبة كحبّات المسبحة.
class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  int _section = 0; // 0 = المفضلة، 1 = التنزيلات

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final player = context.watch<PlayerProvider>();
    final textTheme = Theme.of(context).textTheme;
    final favorites = store.favorites;
    final downloads = store.downloads.values.toList();
    final items = _section == 0
        ? favorites
        : downloads.map((d) => d.track).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Expanded(child: Text('مكتبتي', style: textTheme.displaySmall)),
              if (_section == 1 && downloads.isNotEmpty)
                Text(
                  AppUtils.formatBytes(
                    downloads.fold<int>(0, (sum, d) => sum + d.sizeBytes),
                  ),
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.gold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),

        // التبديل الزجاجي
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: GlassCard(
            radius: 18,
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _SectionButton(
                  label: 'المفضلة',
                  icon: Icons.favorite_rounded,
                  count: favorites.length,
                  selected: _section == 0,
                  onTap: () => setState(() => _section = 0),
                ),
                _SectionButton(
                  label: 'التنزيلات',
                  icon: Icons.download_rounded,
                  count: downloads.length,
                  selected: _section == 1,
                  onTap: () => setState(() => _section = 1),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: _section == 0
                      ? Icons.favorite_border_rounded
                      : Icons.download_rounded,
                  title: _section == 0
                      ? 'مكتبتك فارغة'
                      : 'لا توجد تنزيلات',
                  message: _section == 0
                      ? 'اضغط القلب على أي لطمية لتحفظها هنا كحبّة مسبحة.'
                      : 'نزّل المقاطع من قائمة أي رادد لتستمع بدون إنترنت.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 130),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final track = items[index];
                    return TrackTile(
                      track: track,
                      number: index + 1,
                      showReciter: true,
                      onTap: () =>
                          player.playQueue(items, startIndex: index),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SectionButton extends StatelessWidget {
  const _SectionButton({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.red.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.red.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    selected ? AppColors.goldLight : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Text(
                '$label ($count)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
