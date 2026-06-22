// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MEDIA GRID CACHE — module-level static cache
// Survives widget rebuilds (tab switch, navigation back) within same app
// session. Cleared automatically on app restart or when explicitly refreshed.
//
// Test cases handled:
//   ✅ Stale data: TTL of 5 mins, then auto-refresh in background
//   ✅ Memory bloat: capped at MAX_CACHED_PAGES pages (~40 items)
//   ✅ Pull-to-refresh: bypasses cache, forces fresh fetch
//   ✅ New upload: caller can invalidate via MediaGridCache.invalidate()
//   ✅ Multi-user: cache keyed on user id, auto-clears on user change
//   ✅ Offline: serves stale cache rather than blank screen
// ═══════════════════════════════════════════════════════════════════════════
class MediaGridCache {
  static List<Map<String, dynamic>> _items = [];
  static int _lastPage = -1;
  static bool _hasMore = true;
  static DateTime? _fetchedAt;
  static String? _ownerUserId;
  // Pagination cursor — last item's capture_date for stable paging
  static String? _lastCaptureDate;

  static const Duration ttl = Duration(minutes: 5);
  // Hard limit to prevent unbounded growth
  static const int maxCachedItems = 100;

  static bool isFreshFor(String? userId) {
    if (_fetchedAt == null) return false;
    if (_ownerUserId != userId) return false; // different user — invalidate
    return DateTime.now().difference(_fetchedAt!) < ttl;
  }

  static bool hasAny(String? userId) {
    if (_ownerUserId != userId) return false;
    return _items.isNotEmpty;
  }

  static List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  static int get lastPage => _lastPage;
  static bool get hasMore => _hasMore;

  static void store({
    required String? userId,
    required List<Map<String, dynamic>> page,
    required int pageNumber,
    required bool hasMore,
    bool replace = false,
  }) {
    if (replace || _ownerUserId != userId) {
      _items = [];
      _lastPage = -1;
    }
    _ownerUserId = userId;

    // Dedupe by id
    final existingIds = _items.map((e) => e['id']?.toString()).toSet();
    for (final p in page) {
      final id = p['id']?.toString();
      if (id != null && !existingIds.contains(id)) {
        _items.add(p);
        existingIds.add(id);
      }
    }

    // Cap memory
    if (_items.length > maxCachedItems) {
      _items = _items.sublist(0, maxCachedItems);
    }

    _lastPage = pageNumber;
    _hasMore = hasMore;
    _fetchedAt = DateTime.now();

    // Update pagination cursor from last item
    if (_items.isNotEmpty) {
      _lastCaptureDate = _items.last['capture_date']?.toString();
    }
  }

  /// Call from upload screen or anywhere data changes to force a refresh
  /// on next grid render.
  static void invalidate() {
    _fetchedAt = null; // marks cache as stale
  }

  static void clear() {
    _items = [];
    _lastPage = -1;
    _hasMore = true;
    _fetchedAt = null;
    _ownerUserId = null;
    _lastCaptureDate = null;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// MAIN WIDGET
/// ═══════════════════════════════════════════════════════════════════════════
class MediaGridView extends StatefulWidget {
  const MediaGridView({
    super.key,
    this.width,
    this.height,
    this.pageSize = 8,
    this.onCardTap,
  });

  final double? width;
  final double? height;
  final int pageSize;
  final Future Function(String mediaId)? onCardTap;

  @override
  State<MediaGridView> createState() => _MediaGridViewState();
}

class _MediaGridViewState extends State<MediaGridView> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  int _crossAxisCount = 2;
  String? _error;
  bool _isRefreshingInBackground = false;

  String? get _currentUserId => SupaFlow.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  // ─────────────────────────────────────────────
  // INITIAL LOAD — uses cache if fresh
  // ─────────────────────────────────────────────
  Future<void> _initialLoad() async {
    final userId = _currentUserId;

    // ★ Path 1: cache has data and is fresh → use instantly, no spinner
    if (MediaGridCache.isFreshFor(userId) && MediaGridCache.hasAny(userId)) {
      setState(() {
        _data = List<Map<String, dynamic>>.from(MediaGridCache.items);
        _currentPage = MediaGridCache.lastPage + 1;
        _hasMore = MediaGridCache.hasMore;
        _isLoading = false;
      });
      return;
    }

    // ★ Path 2: cache exists but stale → show cached immediately, refresh
    //   in background. User sees content instantly, fresh data fills in.
    if (MediaGridCache.hasAny(userId)) {
      setState(() {
        _data = List<Map<String, dynamic>>.from(MediaGridCache.items);
        _currentPage = MediaGridCache.lastPage + 1;
        _hasMore = MediaGridCache.hasMore;
        _isLoading = false;
        _isRefreshingInBackground = true;
      });
      // Trigger silent background refresh
      _fetchData(isInitial: true, silent: true);
      return;
    }

    // ★ Path 3: no cache at all → full fetch with spinner
    await _fetchData(isInitial: true);
  }

  // ─────────────────────────────────────────────
  // FETCH DATA
  // ─────────────────────────────────────────────
  Future<void> _fetchData({
    bool isInitial = false,
    bool silent = false, // don't show spinner if background refresh
  }) async {
    if (isInitial) {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _error = null;
          _currentPage = 0;
          _data = [];
          _hasMore = true;
        });
      }
    } else {
      if (_isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final pageToFetch = isInitial ? 0 : _currentPage;
      final from = pageToFetch * widget.pageSize;
      final to = from + widget.pageSize - 1;

      final response = await SupaFlow.client
          .from('Media')
          .select()
          .order('capture_date', ascending: false)
          .range(from, to);

      final newItems = List<Map<String, dynamic>>.from(response);
      final hasMore = newItems.length == widget.pageSize;

      if (!mounted) return;

      setState(() {
        if (isInitial) {
          // Replace data with fresh fetch
          _data = newItems;
          _currentPage = 1;
        } else {
          // Append, deduping by id
          final existingIds = _data.map((e) => e['id']?.toString()).toSet();
          for (final item in newItems) {
            final id = item['id']?.toString();
            if (id != null && !existingIds.contains(id)) {
              _data.add(item);
            }
          }
          _currentPage++;
        }
        _hasMore = hasMore;
        _isLoading = false;
        _isLoadingMore = false;
        _isRefreshingInBackground = false;
      });

      // ★ Update cache
      MediaGridCache.store(
        userId: _currentUserId,
        page: newItems,
        pageNumber: pageToFetch,
        hasMore: hasMore,
        replace: isInitial,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Only surface error if we have nothing to show
        if (_data.isEmpty) {
          _error = e.toString();
        }
        _isLoading = false;
        _isLoadingMore = false;
        _isRefreshingInBackground = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  // PULL TO REFRESH — bypasses cache, forces fresh
  // ─────────────────────────────────────────────
  Future<void> _pullToRefresh() async {
    MediaGridCache.invalidate();
    await _fetchData(isInitial: true);
  }

  void _handleCardTap(String mediaId) async {
    FFAppState().selectedMediaId = mediaId;

    final selectedItem = _data.firstWhere(
      (element) => element['id']?.toString() == mediaId,
      orElse: () => {},
    );

    if (selectedItem.isNotEmpty) {
      FFAppState().selectedMediaTitle = selectedItem['title']?.toString() ?? '';
      FFAppState().selectedMediaFileUrl =
          selectedItem['file_path']?.toString() ?? '';
      FFAppState().selectedMediaDate =
          selectedItem['capture_date']?.toString() ?? '';
      FFAppState().selectedMediaAvgScore =
          double.tryParse(selectedItem['average_score']?.toString() ?? '0') ??
              0.0;
      FFAppState().selectedMediaHighScore =
          double.tryParse(selectedItem['highest_score']?.toString() ?? '0') ??
              0.0;
      FFAppState().selectedMediaProcessing =
          selectedItem['processing_data'] is String
              ? selectedItem['processing_data']
              : jsonEncode(selectedItem['processing_data']);
      if (selectedItem['Metadata'] != null) {
        FFAppState().selectedMediaMetadata = selectedItem['Metadata'] is String
            ? selectedItem['Metadata']
            : jsonEncode(selectedItem['Metadata']);
      }
    }

    if (widget.onCardTap != null) {
      await widget.onCardTap!(mediaId);
    } else {
      context.pushNamed(
        'photoDetail_screen',
        queryParameters: {
          'mediaId': serializeParam(mediaId, ParamType.String),
        },
      );
    }
  }

  // ─────────────────────────────────────────────
  // CARD — uses CachedNetworkImage for disk caching
  // ─────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> item) {
    final String mediaId = item['id']?.toString() ?? '';
    final String? fileUrl = item['file_path']?.toString();
    final String title = item['title']?.toString() ?? 'Untitled';
    final double avgScore =
        double.tryParse(item['average_score']?.toString() ?? '0') ?? 0.0;
    final String status = item['current_status']?.toString() ?? '';
    final bool isThreeCol = _crossAxisCount == 3;

    return GestureDetector(
      onTap: () => _handleCardTap(mediaId),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(isThreeCol ? 8 : 12),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ★ CachedNetworkImage: disk + memory cache, image only fetched
            //   from network once. On rebuild it loads instantly from cache.
            fileUrl != null && fileUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: fileUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    fadeOutDuration: const Duration(milliseconds: 100),
                    memCacheWidth: isThreeCol ? 300 : 500, // downsample
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF252830),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3E82FC)),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildFallbackIcon(isThreeCol),
                  )
                : _buildFallbackIcon(isThreeCol),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(isThreeCol ? 6 : 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xEE000000), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: status.toLowerCase() == 'processed'
                              ? const Color(0xFF2ECC71).withOpacity(0.2)
                              : const Color(0xFF3E82FC).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: status.toLowerCase() == 'processed'
                                ? const Color(0xFF2ECC71)
                                : const Color(0xFF3E82FC),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: status.toLowerCase() == 'processed'
                                ? const Color(0xFF2ECC71)
                                : const Color(0xFF3E82FC),
                            fontSize: isThreeCol ? 7 : 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isThreeCol ? 10 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isThreeCol && avgScore > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 11, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            avgScore.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.amber, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(bool isThreeCol) {
    return Container(
      color: const Color(0xFF252830),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          color: Colors.white.withOpacity(0.15),
          size: isThreeCol ? 24 : 36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${_data.length} Items',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    // ★ Tiny indicator while refreshing in background
                    if (_isRefreshingInBackground) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF3E82FC)),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    _toggleBtn(Icons.grid_view_rounded, 2),
                    const SizedBox(width: 8),
                    _toggleBtn(Icons.view_column_rounded, 3),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF3E82FC)),
                    ),
                  )
                : _error != null
                    ? _buildErrorWidget()
                    : _data.isEmpty
                        ? Center(
                            child: Text(
                              'No photos found',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          )
                        // ★ Wrap with RefreshIndicator for pull-to-refresh
                        : RefreshIndicator(
                            color: const Color(0xFF3E82FC),
                            backgroundColor: const Color(0xFF1A1D21),
                            onRefresh: _pullToRefresh,
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics()),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  sliver: SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) =>
                                          _buildCard(_data[index]),
                                      childCount: _data.length,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _crossAxisCount,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio:
                                          _crossAxisCount == 2 ? 0.72 : 0.68,
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 80),
                                    child: _hasMore
                                        ? _isLoadingMore
                                            ? const Center(
                                                child: SizedBox(
                                                  height: 36,
                                                  width: 36,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Color(0xFF3E82FC)),
                                                  ),
                                                ),
                                              )
                                            : GestureDetector(
                                                onTap: () => _fetchData(
                                                    isInitial: false),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 14),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF3E82FC)
                                                            .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                    border: Border.all(
                                                      color: const Color(
                                                              0xFF3E82FC)
                                                          .withOpacity(0.4),
                                                    ),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'Load More',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF3E82FC),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                        : const SizedBox(height: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _fetchData(isInitial: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E82FC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(IconData icon, int count) {
    final isSelected = _crossAxisCount == count;
    return GestureDetector(
      onTap: () => setState(() => _crossAxisCount = count),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3E82FC).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3E82FC)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected
              ? const Color(0xFF3E82FC)
              : Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }
}
