import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../state/library_provider.dart';
import '../../state/player_provider.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import 'reciter_screen.dart';
import 'search_screen.dart';

/// شاشة اللطميات: كل رادد بختمه الزجاجي بضوء أحمر خفيف.
class RecitersScreen extends StatelessWidget {
  const RecitersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final player = context.watch<PlayerProvider>();
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: library.load,
      color: AppColors.red,
      backgroundColor: AppColors.vignette,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اللطميات', style: textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${library.reciters.length} رادداً — اختر مجلسك',
                    style: textTheme.bodySmall?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  // بحث زجاجي
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    child: GlassCard(
                      radius: 18,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ابحث باسم الرادد أو اللطمية...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall
                                  ?.copyWith(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (player.needsLoad && player.hasQueue)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: _ContinueGlassCard(
                  title: player.currentTrack?.titleAr ?? 'آخر جلسة استماع',
                  reciter: player.currentTrack?.reciterName ?? '',
                  onPlay: player.resumeLastSession,
                ),
              ),
            ),

          if (library.loading && library.reciters.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (library.reciters.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.people_alt_rounded,
                title: 'لا يوجد راددون',
                message: library.error,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final reciter = library.reciters[index];
                    return _RadidGlassCard(
                      reciter: reciter,
                      trackCount: library.trackCountOf(reciter.id),
                    );
                  },
                  childCount: library.reciters.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// بطاقة الرادد: ختم دائري زجاجي بضوء أحمر + اسم + عدد المجالس.
class _RadidGlassCard extends StatelessWidget {
  const _RadidGlassCard({required this.reciter, required this.trackCount});

  final Reciter reciter;
  final int trackCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReciterScreen(reciter: reciter),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassSeal(
              label: AppUtils.initial(reciter.nameAr),
              image: reciter.imageUrl,
              size: 74,
            ),
            const SizedBox(height: 10),
            Text(
              reciter.nameAr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            GlassCapsule(
              child: Text(
                trackCount > 0 ? '$trackCount مجلس' : 'قريباً',
                style: textTheme.labelSmall?.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة "استكمال الاستماع" الزجاجية.
class _ContinueGlassCard extends StatelessWidget {
  const _ContinueGlassCard({
    required this.title,
    required this.reciter,
    required this.onPlay,
  });

  final String title;
  final String reciter;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      glow: true,
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.redGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.redGlow,
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'استكمال الاستماع',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.goldLight,
                  ),
                ),
                Text(
                  '$title — $reciter',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.play_circle_fill_rounded,
              size: 34,
              color: AppColors.gold,
            ),
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}
