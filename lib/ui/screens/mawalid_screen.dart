import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/mawalid_data.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import 'reciter_screen.dart';

/// شاشة «الموالد»: فهرس شامل لرواديد وفرق المواليد مُرتَّباً حسب البلدان،
/// بروح الفرح والسرور (هوية خضراء) لأنّها مناسبات أهل البيت (ع) السعيدة.
class MawalidScreen extends StatefulWidget {
  const MawalidScreen({super.key});

  @override
  State<MawalidScreen> createState() => _MawalidScreenState();
}

class _MawalidScreenState extends State<MawalidScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  /// اسم البلد المختار، وnull يعني «الكل».
  String? _country;

  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// إجمالي الرواديد في الفهرس.
  int get _totalReciters =>
      mawalidGroups.fold(0, (sum, g) => sum + g.reciters.length);

  /// تطبيق البحث وفلتر البلد على المجموعات.
  List<(MawalidGroup, List<MawalidReciter>)> get _visible {
    final q = AppUtils.normalize(_query);
    final out = <(MawalidGroup, List<MawalidReciter>)>[];

    for (final g in mawalidGroups) {
      if (_country != null && g.title != _country) continue;

      final reciters = g.reciters.where((r) {
        if (q.isEmpty) return true;
        if (AppUtils.normalize(r.nameAr).contains(q)) return true;
        if (r.cityAr != null && AppUtils.normalize(r.cityAr!).contains(q)) {
          return true;
        }
        for (final k in r.searchKeys) {
          if (AppUtils.normalize(k).contains(q)) return true;
        }
        return false;
      }).toList();

      if (reciters.isNotEmpty) out.add((g, reciters));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sections = _visible;
    final visibleCount =
        sections.fold<int>(0, (sum, s) => sum + s.$2.length);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الموالد', style: textTheme.displaySmall),
                const SizedBox(height: 4),
                Text(
                  '$_totalReciters رادداً وفرقة — أبتهال وسرور مواليد أهل البيت (ع)',
                  style: textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 12),
                // بحث فوري داخل الفهرس.
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم الرادد أو البلد...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // شريط اختيار البلد (أفقي).
        SliverToBoxAdapter(
          child: SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              children: [
                _CountryChip(
                  label: 'الكل',
                  flag: '🌍',
                  selected: _country == null,
                  onTap: () => setState(() => _country = null),
                ),
                for (final g in mawalidGroups)
                  _CountryChip(
                    label: g.title,
                    flag: g.flag,
                    selected: _country == g.title,
                    onTap: () => setState(
                      () => _country = _country == g.title ? null : g.title,
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (sections.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'لا نتائج',
              message: 'جرّب اسماً آخر أو أعد اختيار «الكل».',
            ),
          )
        else
          for (final (group, reciters) in sections) ...[
            SliverToBoxAdapter(
              child: _CountryHeader(
                group: group,
                count: reciters.length,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _MawalidCard(radid: reciters[index]),
                  childCount: reciters.length,
                ),
              ),
            ),
          ],

        // مساحة سفلية لشريط التنقل والمشغّل المصغّر.
        const SliverToBoxAdapter(child: SizedBox(height: 130)),

        // ملاحظة أسفل القائمة.
        if (sections.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Text(
                visibleCount == _totalReciters
                    ? 'المصدر: فهرس مواليد وأفراح shiavoice.com مُضمَّناً في التطبيق، مُرتَّباً حسب البلدان — أبتهال وتسابيح وأهازيج الفرح، لا رثاءً ولا نوحًا. يُفتح الأبتهال المتوفر مباشرة.'
                    : '‏$visibleCount من $_totalReciters رادداً مطابقاً لبحثك.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  height: 1.7,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// شريحة بلد في الشريط الأفقي.
class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.green.withValues(alpha: 0.18)
                : AppColors.glassFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.green.withValues(alpha: 0.5)
                  : AppColors.glassBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.goldLight
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ترويسة قسم البلد: العلم + الاسم + الوصف + عدد الرواديد.
class _CountryHeader extends StatelessWidget {
  const _CountryHeader({required this.group, required this.count});

  final MawalidGroup group;
  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.glassFillStrong,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(group.flag, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.title, style: textTheme.titleLarge),
                if (group.note != null)
                  Text(
                    group.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(fontSize: 11.5),
                  ),
              ],
            ),
          ),
          GlassCapsule(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              '$count',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.goldLight,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة رادد داخل قسم البلد.
class _MawalidCard extends StatelessWidget {
  const _MawalidCard({required this.radid});

  final MawalidReciter radid;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reciter = resolveMawalidReciter(radid);
    final playable = isPlayableMawalid(reciter);

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
              label: AppUtils.initial(radid.nameAr),
              image: reciter.imageUrl,
              size: 74,
              tint: AppColors.green,
            ),
            const SizedBox(height: 10),
            Text(
              radid.nameAr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            if (radid.cityAr != null)
              GlassCapsule(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(
                  radid.cityAr!,
                  style: textTheme.labelSmall?.copyWith(fontSize: 11),
                ),
              ),
            const SizedBox(height: 8),
            // شارة تشغيل صحيحة: تظهر فقط إن توفرت أبتهالات مواليد حقيقية.
            if (playable)
              _PlayBadge(count: mawalidCountOf(reciter))
            else
              Text(
                'أبتهالاته قريباً',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// شارة تشغيل خضراء تُظهر عدد أبتهالات المواليد المتوفرة.
class _PlayBadge extends StatelessWidget {
  const _PlayBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_arrow_rounded,
            size: 13,
            color: AppColors.green,
          ),
          const SizedBox(width: 3),
          Text(
            count > 0 ? '$count أبتهال' : 'أبتهال',
            style: textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}
