import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../state/library_provider.dart';
import '../../state/player_provider.dart';
import '../../state/store_provider.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/track_tile.dart';
import 'player_screen.dart';

/// صفحة الرادد: ختمه الزجاجي، زر التشغيل العشوائي، وقائمة مجالسه.
class ReciterScreen extends StatefulWidget {
  const ReciterScreen({super.key, required this.reciter});

  final Reciter reciter;

  @override
  State<ReciterScreen> createState() => _ReciterScreenState();
}

class _ReciterScreenState extends State<ReciterScreen> {
  late Future<List<Track>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<LibraryProvider>().tracksFor(widget.reciter);
  }

  Future<void> _reload() async {
    final library = context.read<LibraryProvider>();
    setState(() {
      _future = library.tracksFor(widget.reciter);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final textTheme = Theme.of(context).textTheme;
    final reciter = widget.reciter;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AtabaBackground(
        child: SafeArea(
          child: FutureBuilder<List<Track>>(
            future: _future,
            builder: (context, snapshot) {
              final loading =
                  snapshot.connectionState != ConnectionState.done;
              final tracks = snapshot.data ?? const <Track>[];

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 20, 6),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              size: 32,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        children: [
                          // الختم الزجاجي الكبير
                          GlassSeal(
                            label: AppUtils.initial(reciter.nameAr),
                            image: reciter.imageUrl,
                            size: 110,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            reciter.nameAr,
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall,
                          ),
                          const SizedBox(height: 6),
                          GlassCapsule(
                            child: Text(
                              loading
                                  ? 'جارٍ التحميل...'
                                  // ملفات mw_pf_* مسحوبة من صفحة الرادد
                                  // الشخصية: محتواه مزيج والصنف غير مؤكد،
                                  // فلا نوسمه «مواليد» ادعاءً بلا سند.
                                  : reciter.id.startsWith('mw_pf_')
                                      ? '${tracks.length} مقطعاً'
                                      : reciter.id.startsWith('mw_')
                                          ? '${tracks.length} أبتهال مواليدي'
                                          : '${tracks.length} مجلس حسيني',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldLight,
                              ),
                            ),
                          ),
                          if (!loading && tracks.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        player.playQueue(tracks),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                    ),
                                    label: const Text('تشغيل الكل'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.redDark,
                                    ),
                                    onPressed: () => player.playQueue(
                                      tracks,
                                      shuffle: true,
                                    ),
                                    icon: const Icon(Icons.shuffle_rounded),
                                    label: const Text('عشوائي'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (reciter.searchKeys.length > 1) ...[
                            const SizedBox(height: 12),
                            Text(
                              reciter.searchKeys
                                  .skip(1)
                                  .take(3)
                                  .join(' • '),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall
                                  ?.copyWith(fontSize: 11.5),
                            ),
                          ],
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  if (loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (tracks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.library_music_rounded,
                        title: 'لا توجد مقاطع لهذا الرادد',
                        message:
                            'لم تُضمَّن مقاطع ${reciter.nameAr} إلى مكتبة التطبيق بعد.',
                        action: FilledButton.tonalIcon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 130),
                      sliver: SliverList.separated(
                        itemCount: tracks.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return GlassCard(
                            radius: 16,
                            padding: EdgeInsets.zero,
                            child: GestureDetector(
                              onLongPress: () =>
                                  _showTrackActions(context, track),
                              child: TrackTile(
                                track: track,
                                number: index + 1,
                                onTap: () {
                                  // تشغيل + فتح شاشة "قيد التشغيل" فوراً.
                                  player.playQueue(
                                    tracks,
                                    startIndex: index,
                                  );
                                  openPlayerScreen(context);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// قائمة الإجراءات الزجاجية: دوسة طويلة على اللطمية.
  static void _showTrackActions(BuildContext context, Track track) {
    final store = context.read<StoreProvider>();
    final favorite = store.isFavorite(track.id);

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.titleAr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                track.reciterName ?? '',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _GlassAction(
                icon: favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor:
                    favorite ? AppColors.red : AppColors.textPrimary,
                title: favorite ? 'محفوظة في مكتبتك' : 'حفظ في مكتبتي',
                subtitle: 'قلب أحمر بجانبها دائماً',
                onTap: () {
                  store.toggleFavorite(track);
                  Navigator.of(sheetContext).pop();
                },
              ),
              _GlassAction(
                icon: Icons.download_rounded,
                title: 'تنزيل للاستماع بدون نت',
                subtitle: 'ملف MP3 داخل جهازك',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    await store.download(track);
                    if (context.mounted) {
                      AppUtils.showSnack(context, 'تم التنزيل ✓');
                    }
                  } catch (_) {
                    if (context.mounted) {
                      AppUtils.showSnack(context, 'فشل التنزيل');
                    }
                  }
                },
              ),
              _GlassAction(
                icon: Icons.share_rounded,
                title: 'مشاركة اللطمية',
                subtitle: 'أرسل الاسم والرابط لأصدقائك',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  SharePlus.instance.share(
                    ShareParams(
                      text: '${track.titleAr} — ${track.reciterName ?? ''}\n'
                          '${track.audioUrl}',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassAction extends StatelessWidget {
  const _GlassAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            children: [
              GlassIcon(icon: icon, size: 19, color: iconColor ?? AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                size: 24,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
