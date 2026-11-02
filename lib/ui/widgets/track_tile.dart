import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../state/player_provider.dart';
import '../../state/store_provider.dart';
import 'common.dart';

/// صف مقطع صوتي مع كل الإجراءات (تشغيل، مفضلة، تنزيل...).
class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.number,
    required this.onTap,
    this.showReciter = false,
    this.removable = false,
  });

  final Track track;
  final int number;
  final VoidCallback onTap;
  final bool showReciter;

  /// إظهار زر حذف المقطع من القائمة (شاشة قائمة التشغيل).
  final bool removable;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final store = context.watch<StoreProvider>();
    final isCurrent = player.currentTrack?.id == track.id;
    final favorite = store.isFavorite(track.id);
    final downloaded = store.isDownloaded(track.id);
    final progress = store.progressFor(track.id);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isCurrent
          ? AppColors.gold.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: isCurrent
                      ? const EqualizerBars(height: 17)
                      : Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.glassFillStrong,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$number',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.titleAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.decorative,
                        fontSize: 16.5,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isCurrent
                            ? AppColors.goldLight
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (showReciter && track.reciterName != null) ...[
                          Flexible(
                            child: Text(
                              track.reciterName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall,
                            ),
                          ),
                          Text(' • ', style: textTheme.bodySmall),
                        ],
                        if (track.duration != null)
                          Text(track.durationLabel,
                              style: textTheme.bodySmall),
                        if (downloaded) ...[
                          Text(' • ', style: textTheme.bodySmall),
                          const Icon(Icons.download_done,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 3),
                          Text('منزّل',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                              )),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (progress != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      value: progress >= 1 ? null : progress,
                      strokeWidth: 2.4,
                    ),
                  ),
                )
              else
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => store.toggleFavorite(track),
                  icon: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border_rounded,
                    size: 21,
                    color: favorite ? AppColors.gold : AppColors.textSecondary,
                  ),
                ),
              if (removable)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => player.removeAt(
                    player.queue.indexWhere((t) => t.id == track.id),
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (action) =>
                      _handleAction(context, action, player, store),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'play',
                      child: _MenuLabel(
                        icon: Icons.play_arrow_rounded,
                        text: 'تشغيل الآن',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'next',
                      child: _MenuLabel(
                        icon: Icons.queue_music_rounded,
                        text: 'تشغيل التالي',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'queue',
                      child: _MenuLabel(
                        icon: Icons.playlist_add_rounded,
                        text: 'إضافة إلى القائمة',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'fav',
                      child: _MenuLabel(
                        icon: favorite
                            ? Icons.favorite
                            : Icons.favorite_border_rounded,
                        text: favorite
                            ? 'إزالة من المفضلة'
                            : 'إضافة إلى المفضلة',
                      ),
                    ),
                    downloaded
                        ? const PopupMenuItem(
                            value: 'delete',
                            child: _MenuLabel(
                              icon: Icons.delete_outline_rounded,
                              text: 'حذف التنزيل',
                            ),
                          )
                        : const PopupMenuItem(
                            value: 'download',
                            child: _MenuLabel(
                              icon: Icons.download_rounded,
                              text: 'تنزيل للاستماع بدون إنترنت',
                            ),
                          ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    String action,
    PlayerProvider player,
    StoreProvider store,
  ) async {
    switch (action) {
      case 'play':
        onTap();
      case 'next':
        await player.insertNext(track);
        if (context.mounted) {
          AppUtils.showSnack(context, 'سيُشغَّل بعد المقطع الحالي');
        }
      case 'queue':
        await player.addLast(track);
        if (context.mounted) {
          AppUtils.showSnack(context, 'أُضيف إلى قائمة التشغيل');
        }
      case 'fav':
        store.toggleFavorite(track);
      case 'download':
        try {
          await store.download(track);
          if (context.mounted) {
            AppUtils.showSnack(context, 'تم تنزيل المقطع ✓');
          }
        } catch (_) {
          if (context.mounted) {
            AppUtils.showSnack(context, 'فشل التنزيل، تحقّق من الاتصال');
          }
        }
      case 'delete':
        await store.deleteDownload(track.id);
        if (context.mounted) {
          AppUtils.showSnack(context, 'حُذف التنزيل');
        }
    }
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: AppColors.gold),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
