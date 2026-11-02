import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/player_provider.dart';
import '../screens/player_screen.dart';
import 'glass.dart';

/// المشغّل المصغّر — بطاقة زجاجية عائمة أعلى شريط التنقّل.
///
/// - سحب لأعلى: يفتح شاشة "قيد التشغيل".
/// - سحب لأسفل: يُخفي البطاقة (يظهر مؤشّر صغير لاستعادتها).
/// - اختيار نغمة جديدة يُعيد البطاقة تلقائياً.
class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _hidden = false;
  double _dragDy = 0;
  String? _lastTrackId;

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragDy = (_dragDy + d.delta.dy).clamp(-110.0, 110.0);
    });
  }

  void onDragEnd(DragEndDetails d, BuildContext context) {
    final v = d.primaryVelocity ?? 0;
    final up = _dragDy < -55 || v < -650;
    final down = _dragDy > 55 || v > 650;
    setState(() {
      if (!_hidden) {
        if (down) {
          _hidden = true; // إخفاء بالسحب لأسفل.
        } else if (up) {
          openPlayerScreen(context); // فتح بالسحب لأعلى.
        }
      } else if (up) {
        _hidden = false; // استعادة بالسحب لأعلى.
      }
      _dragDy = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    if (!player.hasQueue) return const SizedBox.shrink();

    // إعادة ظهور تلقائية عند اختيار نغمة جديدة.
    final currentId = player.currentTrack?.id;
    if (_hidden && currentId != null && currentId != _lastTrackId) {
      _lastTrackId = currentId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hidden = false;
            _dragDy = 0;
          });
        }
      });
    } else {
      _lastTrackId = currentId;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: (d) => onDragEnd(d, context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _dragDy, 0),
          transformAlignment: Alignment.center,
          child: _hidden
              ? _buildPill(context, player)
              : _buildCard(context, player),
        ),
      ),
    );
  }

  /// المؤشّر الصغير بعد الإخفاء — اضغط أو اسحب لأعلى لاستعادة البطاقة.
  Widget _buildPill(BuildContext context, PlayerProvider player) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openPlayerScreen(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 18,
              color: player.playing ? AppColors.goldLight : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            const Text(
              'المشغّل مخفي — اضغط لفتحه',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, PlayerProvider player) {
    final track = player.currentTrack;
    final textTheme = Theme.of(context).textTheme;
    final showProgress = track != null && player.duration > Duration.zero;

    return GlassCard(
      radius: 20,
      padding: EdgeInsets.zero,
      glow: player.playing,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openPlayerScreen(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final value = showProgress
                      ? (position.inMicroseconds /
                              player.duration.inMicroseconds)
                          .clamp(0.0, 1.0)
                      : 0.0;
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 2.4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.goldLight,
                    ),
                  );
                },
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    if (track != null && track.artUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          track.artUrl!,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _MiniArtFallback(),
                        ),
                      )
                    else
                      const _MiniArtFallback(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track?.titleAr ?? 'مستكمل الاستماع',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppFonts.decorative,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            player.needsLoad
                                ? 'آخر جلسة استماع — اضغط للمتابعة'
                                : (track?.reciterName ?? ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall
                                ?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.redGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.redGlow,
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: player.togglePlay,
                        iconSize: 26,
                        padding: EdgeInsets.zero,
                        icon: player.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                player.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    IconButton(
                      onPressed: player.hasNext ? player.next : null,
                      iconSize: 30,
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: player.hasNext
                            ? AppColors.textPrimary
                            : AppColors.textSecondary
                                .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniArtFallback extends StatelessWidget {
  const _MiniArtFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppColors.redGradient,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note_rounded,
        size: 22,
        color: AppColors.goldLight,
      ),
    );
  }
}
