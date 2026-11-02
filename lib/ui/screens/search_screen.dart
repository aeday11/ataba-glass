import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/api.dart';
import '../../state/library_provider.dart';
import '../../state/player_provider.dart';
import '../widgets/common.dart';
import '../widgets/track_tile.dart';
import 'reciter_screen.dart';

/// البحث عن رادد أو مقطع.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<SearchResults>? _results;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {}); // لتحديث زر المسح فوراً
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _results = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _query = query;
        _results = context.read<LibraryProvider>().search(query);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final player = context.watch<PlayerProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text('البحث', style: textTheme.displaySmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث باسم الرادد أو المقطع...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        Expanded(
          child: _results == null
              ? const EmptyState(
                  icon: Icons.manage_search_rounded,
                  title: 'ابحث في الرواديد',
                  message: 'اكتب اسم الرادد أو المقطع وستظهر النتائج فوراً. '
                      'البحث يشمل الأسماء العربية والإنجليزية.',
                )
              : FutureBuilder<SearchResults>(
                  future: _results,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final results =
                        snapshot.data ?? const SearchResults();
                    if (results.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'لا توجد نتائج',
                        message: 'لم نجد ما يطابق "$_query"، جرّب اسماً آخر.',
                      );
                    }

                    final reciters = results.reciters;
                    final tracks = results.tracks;

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (reciters.isNotEmpty) ...[
                          const SectionHeader(title: 'الرواديد'),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: reciters
                                  .map(
                                    (reciter) => ActionChip(
                                      avatar: ReciterAvatar(
                                        reciter: reciter,
                                        size: 26,
                                      ),
                                      label: Text(reciter.nameAr),
                                      backgroundColor: AppColors.glassFillStrong,
                                      side: const BorderSide(
                                        color: AppColors.divider,
                                      ),
                                      labelStyle: const TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ReciterScreen(
                                            reciter: reciter,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                        if (tracks.isNotEmpty) ...[
                          const SectionHeader(title: 'المقاطع'),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              children: [
                                for (var i = 0; i < tracks.length; i++)
                                  TrackTile(
                                    track: tracks[i],
                                    number: i + 1,
                                    showReciter: true,
                                    onTap: () => player.playQueue(
                                      tracks,
                                      startIndex: i,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
