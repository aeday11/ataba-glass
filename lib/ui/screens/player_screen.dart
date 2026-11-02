import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../state/player_provider.dart';
import '../../state/store_provider.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

/// فتح شاشة المشغّل الكاملة بحركة انزلاق.
void openPlayerScreen(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      opaque: false,
      fullscreenDialog: true,
      pageBuilder: (_, _, _) => const PlayerScreen(),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// المشغّل: خلفية ضبابية ملء الشاشة وبطاقة زجاجية مركزية تتوهّج أحمر.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static const List<double> _speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final store = context.watch<StoreProvider>();
    final textTheme = Theme.of(context).textTheme;
    final track = player.currentTrack;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // الخلفية الضبابية
          _BlurBackground(track: track),
          // شمعة النوم khi النوم مفعّل
          if (player.sleepActive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 260,
              child: _CandleGlow(remaining: player.sleepRemaining),
            ),
          SafeArea(
            child: !player.hasQueue
                ? const EmptyState(
                    icon: Icons.queue_music_rounded,
                    title: 'لا يوجد ما يُشغَّل',
                    message: 'اختر رادداً أو لطمية من المكتبة لتبدأ.',
                  )
                : Column(
                    children: [
                      // رأس الشاشة
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 32,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'قيد التشغيل',
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: player.queue.length > 1
                                  ? () => _showQueueSheet(context, player)
                                  : null,
                              icon: const Icon(
                                Icons.queue_music_rounded,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            child: GlassCard(
                              blur: true,
                              glow: true,
                              radius: 30,
                              padding: const EdgeInsets.fromLTRB(
                                  20, 22, 20, 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _Artwork(track: track),
                                  const SizedBox(height: 18),

                                  // الاسم كأنه محفور بالذهب
                                  GoldGlowText(
                                    track?.titleAr ?? '',
                                    fontSize: 23,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    track?.reciterName ?? '',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),

                                  if (player.error != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            size: 17,
                                            color: AppColors.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              player.error!,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: player.clearError,
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 14),

                                  // شريط التقدّم
                                  StreamBuilder<Duration>(
                                    stream: player.positionStream,
                                    builder: (context, snapshot) {
                                      final position =
                                          snapshot.data ?? Duration.zero;
                                      final duration = player.duration;
                                      final maxMs = (duration >
                                                  Duration.zero
                                              ? duration
                                              : position)
                                          .inMicroseconds
                                          .toDouble();
                                      final value = maxMs <= 0
                                          ? 0.0
                                          : (position.inMicroseconds / maxMs)
                                              .clamp(0.0, 1.0);
                                      return Column(
                                        children: [
                                          Slider(
                                            value: value,
                                            onChanged: duration >
                                                    Duration.zero
                                                ? (v) => player.seek(
                                                      Duration(
                                                        microseconds: (v *
                                                                maxMs)
                                                            .round(),
                                                      ),
                                                    )
                                                : null,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Text(
                                                AppUtils.formatDuration(
                                                    position),
                                                style:
                                                    textTheme.bodySmall,
                                              ),
                                              Text(
                                                duration > Duration.zero
                                                    ? AppUtils
                                                        .formatDuration(
                                                            duration)
                                                    : '--:--',
                                                style:
                                                    textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 10),

                                  // أزرار التحكم الرئيسية
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _RoundControl(
                                        icon: Icons.skip_previous_rounded,
                                        enabled: player.hasPrevious ||
                                            player.hasQueue,
                                        onTap: player.previous,
                                      ),
                                      _RoundControl(
                                        icon: Icons.replay_10_rounded,
                                        size: 29,
                                        onTap: player.skipBackward,
                                      ),
                                      SizedBox(
                                        width: 74,
                                        height: 74,
                                        child: FilledButton(
                                          onPressed: player.togglePlay,
                                          style: FilledButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            shape: const CircleBorder(),
                                            backgroundColor:
                                                AppColors.redDeep,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                          ),
                                          child: player.isLoading
                                              ? const SizedBox(
                                                  width: 30,
                                                  height: 30,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 3,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Icon(
                                                  player.playing
                                                      ? Icons
                                                          .pause_rounded
                                                      : Icons
                                                          .play_arrow_rounded,
                                                  size: 44,
                                                ),
                                        ),
                                      ),
                                      _RoundControl(
                                        icon: Icons.forward_10_rounded,
                                        size: 29,
                                        onTap: player.skipForward,
                                      ),
                                      _RoundControl(
                                        icon: Icons.skip_next_rounded,
                                        enabled: player.hasNext,
                                        onTap: player.next,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // السرعة والنوم والتكرار والمفضلة والتنزيل
                                  Wrap(
                                    spacing: 14,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      InkWell(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        onTap: () => _showSpeedSheet(
                                            context, player),
                                        child: GlassCapsule(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 8),
                                          child: Text(
                                            '${_speedLabel(player.speed)}×',
                                            style: TextStyle(
                                              color: AppColors.goldLight,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // مؤقّت النوم
                                      InkWell(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        onTap: () =>
                                            _showSleepSheet(context, player),
                                        child: GlassCapsule(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8),
                                          color: player.sleepActive
                                              ? AppColors.red
                                                  .withValues(alpha: 0.18)
                                              : null,
                                          child: Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.nightlight_round,
                                                size: 15,
                                                color: player.sleepActive
                                                    ? AppColors.goldLight
                                                    : AppColors
                                                        .textSecondary,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                player.sleepActive
                                                    ? AppUtils
                                                        .formatDuration(
                                                            player
                                                                .sleepRemaining)
                                                    : 'نام بعد',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: player.sleepActive
                                                      ? AppColors
                                                          .goldLight
                                                      : AppColors
                                                          .textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      _RoundControl(
                                        icon: player.loopMode ==
                                                LoopMode.one
                                            ? Icons.repeat_one_rounded
                                            : Icons.repeat_rounded,
                                        enabled: player.loopMode !=
                                            LoopMode.off,
                                        color: player.loopMode ==
                                                LoopMode.off
                                            ? AppColors.textSecondary
                                            : AppColors.gold,
                                        size: 24,
                                        onTap: player.cycleLoopMode,
                                      ),
                                      if (track != null)
                                        _RoundControl(
                                          icon: store.isFavorite(track.id)
                                              ? Icons.favorite_rounded
                                              : Icons
                                                  .favorite_border_rounded,
                                          color:
                                              store.isFavorite(track.id)
                                                  ? AppColors.red
                                                  : AppColors
                                                      .textSecondary,
                                          size: 24,
                                          onTap: () =>
                                              store.toggleFavorite(track),
                                        ),
                                      if (track != null)
                                        _DownloadControl(
                                          track: track,
                                          store: store,
                                        ),
                                    ],
                                  ),

                                  if (player.speed != 1.0) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'سرعة التشغيل: ${player.speed}×',
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static String _speedLabel(double speed) =>
      speed == speed.roundToDouble() ? speed.toInt().toString() : '$speed';

  static void _showSpeedSheet(BuildContext context, PlayerProvider player) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سرعة التشغيل',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _speeds.map((speed) {
                  final selected = (player.speed - speed).abs() < 0.01;
                  return ChoiceChip(
                    label: Text('${_speedLabel(speed)}×'),
                    selected: selected,
                    onSelected: (_) async {
                      await player.setSpeed(speed);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    selectedColor: AppColors.redDeep,
                    labelStyle: TextStyle(
                      color:
                          selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: AppColors.glassFillStrong,
                    side: BorderSide(
                      color: selected
                          ? AppColors.red
                          : AppColors.glassBorder,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ورقة اختيار مدة النوم — الصوت يهدأ تدريجياً حتى النوم.
  static void _showSleepSheet(BuildContext context, PlayerProvider player) {
    const options = [
      (15, 'ربع ساعة'),
      (30, 'نصف ساعة'),
      (45, 'أربع وربع'),
      (60, 'ساعة'),
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نوم الحسين — يهدأ الصوت تدريجياً',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'في آخر دقيقتين ينزل الصوت شوي شوي حتى تنام.',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (minutes, label) in options)
                    ActionChip(
                      avatar: Icon(
                        Icons.nightlight_round,
                        size: 16,
                        color: AppColors.goldLight,
                      ),
                      label: Text('$minutes دقيقة — $label'),
                      onPressed: () {
                        player.startSleepTimer(
                          Duration(minutes: minutes),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      backgroundColor: AppColors.glassFillStrong,
                      side: const BorderSide(color: AppColors.glassBorder),
                      labelStyle: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (player.sleepActive)
                    ActionChip(
                      avatar: const Icon(
                        Icons.alarm_off_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      label: const Text('إلغاء المؤقّت'),
                      onPressed: () {
                        player.cancelSleepTimer();
                        Navigator.of(sheetContext).pop();
                      },
                      backgroundColor:
                          AppColors.error.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                      labelStyle: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
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

  static void _showQueueSheet(BuildContext context, PlayerProvider player) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'قائمة التشغيل (${player.queue.length})',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                itemCount: player.queue.length,
                itemBuilder: (context, index) {
                  final queued = player.queue[index];
                  return _QueueTile(
                    track: queued,
                    index: index + 1,
                    isCurrent: player.currentIndex == index,
                    onTap: () {
                      Navigator.of(context).pop();
                      player.playAt(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.onTap,
  });

  final Track track;
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      onTap: onTap,
      leading: isCurrent
          ? const EqualizerBars(height: 16)
          : SizedBox(
              width: 30,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ),
      title: Text(
        track.titleAr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppFonts.decorative,
          fontSize: 16,
          color: isCurrent ? AppColors.goldLight : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(track.durationLabel, style: textTheme.bodySmall),
      trailing: IconButton(
        icon: const Icon(
          Icons.close_rounded,
          size: 19,
          color: AppColors.textSecondary,
        ),
        onPressed: () => _remove(context),
      ),
    );
  }

  void _remove(BuildContext context) {
    final player = context.read<PlayerProvider>();
    player.removeAt(index - 1);
    if (player.queue.length <= 1) Navigator.of(context).pop();
  }
}

/// خلفية ضبابية: صورة الغلاف تملأ الشاشة خلف تمويه قوي.
class _BlurBackground extends StatelessWidget {
  const _BlurBackground({required this.track});

  final Track? track;

  @override
  Widget build(BuildContext context) {
    final artUrl = track?.artUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (artUrl != null && artUrl.isNotEmpty)
          Image.network(
            artUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _FallbackGradient(),
          )
        else
          const _FallbackGradient(),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.2,
              colors: [AppColors.vignette, AppColors.background],
              stops: [0.0, 0.75],
            ),
          ),
        ),
      ],
    );
  }
}

class _FallbackGradient extends StatelessWidget {
  const _FallbackGradient();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [AppColors.redDark, AppColors.background],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

/// وهج شمعة يهتزّ أسفل الشاشة أثناء النوم الحسيني.
class _CandleGlow extends StatefulWidget {
  const _CandleGlow({required this.remaining});

  final Duration remaining;

  @override
  State<_CandleGlow> createState() => _CandleGlowState();
}

class _CandleGlowState extends State<_CandleGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final flicker = 0.55 + 0.45 * _controller.value;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.30 * flicker),
                      AppColors.red.withValues(alpha: 0.12 * flicker),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: Text(
                  'نام — ينتهي بعد ${AppUtils.formatDuration(widget.remaining)}',
                  style: TextStyle(
                    fontFamily: AppFonts.decorative,
                    fontSize: 15,
                    color: AppColors.goldLight,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// غلاف المقطع داخل دائرة زجاجية متوهّجة — كأنه محفور بالزجاج.
class _Artwork extends StatelessWidget {
  const _Artwork({required this.track});

  final Track? track;

  @override
  Widget build(BuildContext context) {
    final artUrl = track?.artUrl;
    final art = artUrl != null && artUrl.isNotEmpty
        ? Image.network(
            artUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _ArtworkFallback(),
          )
        : const _ArtworkFallback();

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.glassBorderStrong),
        boxShadow: [
          BoxShadow(
            color: AppColors.redGlow,
            blurRadius: 60,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipOval(child: art),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [AppColors.redDark, AppColors.background],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.mosque_rounded,
          size: 62,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.size = 27,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      iconSize: size,
      icon: Icon(
        icon,
        color: enabled ? color : color.withValues(alpha: 0.35),
      ),
    );
  }
}

class _DownloadControl extends StatelessWidget {
  const _DownloadControl({required this.track, required this.store});

  final Track track;
  final StoreProvider store;

  @override
  Widget build(BuildContext context) {
    final progress = store.progressFor(track.id);
    final downloaded = store.isDownloaded(track.id);

    if (progress != null) {
      return SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          value: progress >= 1 ? null : progress,
          strokeWidth: 2.6,
        ),
      );
    }

    return _RoundControl(
      icon: downloaded
          ? Icons.download_done_rounded
          : Icons.download_rounded,
      color: downloaded ? AppColors.success : AppColors.textSecondary,
      size: 24,
      onTap: () async {
        if (downloaded) return;
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
      },
    );
  }
}
