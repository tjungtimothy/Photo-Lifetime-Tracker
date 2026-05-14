// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';

class MediaGridView extends StatefulWidget {
  const MediaGridView({
    super.key,
    this.width,
    this.height,
    this.pageSize = 10,
    required this.onCardTap,
  });

  final double? width;
  final double? height;
  final int pageSize;
  final Future Function(String mediaId) onCardTap;

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

  @override
  void initState() {
    super.initState();
    _fetchData(isInitial: true);
  }

  Future<void> _fetchData({bool isInitial = false}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
        _data = [];
        _hasMore = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;

      setState(() => _isLoadingMore = true);
    }

    try {
      final from = _currentPage * widget.pageSize;
      final to = from + widget.pageSize - 1;

      final response = await SupaFlow.client
          .from('Media')
          .select(
              'id, title, file_path, average_score, highest_score, current_status, photo_address, capture_date, "Metadata", processing_data')
          .order('highest_score', ascending: false)
          .range(from, to);

      final newItems = List<Map<String, dynamic>>.from(response);

      setState(() {
        _data.addAll(newItems);

        _currentPage++;

        _hasMore = newItems.length == widget.pageSize;

        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();

        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _fetchData(isInitial: true);
  }

  void _handleCardTap(Map<String, dynamic> item) {
    final String mediaId = item['id']?.toString() ?? '';

    FFAppState().selectedMediaId = mediaId;
    FFAppState().selectedMediaTitle = item['title']?.toString() ?? '';
    FFAppState().selectedMediaFileUrl = item['file_path']?.toString() ?? '';

    FFAppState().selectedMediaAvgScore =
        double.tryParse(item['average_score']?.toString() ?? '0') ?? 0.0;

    FFAppState().selectedMediaHighScore =
        double.tryParse(item['highest_score']?.toString() ?? '0') ?? 0.0;

    FFAppState().selectedMediaMetadata = jsonEncode(item['Metadata'] ?? {});

    FFAppState().selectedMediaProcessing =
        jsonEncode(item['processing_data'] ?? {});

    FFAppState().selectedMediaEntry = item['photo_address']?.toString() ?? '';

    FFAppState().selectedMediaDate = item['capture_date']?.toString() ?? '';

    widget.onCardTap(mediaId);
  }

  @override
  Widget build(BuildContext context) {
    const double navBarPadding = 84.0;

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
                Text(
                  '${_data.length} Items',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
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
                    child: CircularProgressIndicator(),
                  )
                : _error != null
                    ? _buildErrorUI()
                    : RefreshIndicator(
                        color: FlutterFlowTheme.of(context).primary,
                        backgroundColor: const Color(0xFF1A1D21),
                        onRefresh: _refreshData,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                                      _buildCard(_data[index], index),
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
                                  16,
                                  20,
                                  16,
                                  navBarPadding,
                                ),
                                child: _hasMore
                                    ? _buildLoadMoreButton()
                                    : Center(
                                        child: Text(
                                          'End of Gallery',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
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

  Widget _buildLoadMoreButton() {
    return _isLoadingMore
        ? const Center(
            child: SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          )
        : GestureDetector(
            onTap: () => _fetchData(isInitial: false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0x663E82FC),
                    Color(0x1A181C1E),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0x803E82FC),
                ),
              ),
              child: Center(
                child: Text(
                  'LOAD MORE',
                  style: TextStyle(
                    color: Color(0x663E82FC),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final bool isThreeCol = _crossAxisCount == 3;

    final String? fileUrl = item['file_path']?.toString();

    final double highestScore =
        double.tryParse(item['highest_score']?.toString() ?? '0') ?? 0.0;

    String badgeText = '';

    if (index == 0) {
      badgeText = 'WINNER';
    } else if (index <= 2) {
      badgeText = 'SHORTLISTED';
    } else {
      badgeText = item['current_status']?.toString() ?? '';
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () => _handleCardTap(item),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  /// IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: fileUrl != null && fileUrl.isNotEmpty
                        ? Image.network(
                            fileUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,

                            /// IMAGE LOADER
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;

                              return Container(
                                color: const Color(0xFF252830),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            },

                            errorBuilder: (_, __, ___) =>
                                _errorPlaceholder(isThreeCol),
                          )
                        : _errorPlaceholder(isThreeCol),
                  ),

                  /// DARK GRADIENT OVERLAY
                  Align(
                    alignment: AlignmentDirectional.center,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0x00555464),
                            Color(0xD7000000),
                          ],
                          stops: [0, 1],
                          begin: AlignmentDirectional(0, -1),
                          end: AlignmentDirectional(0, 1),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),

                      /// TEXTS
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          10,
                          0,
                          10,
                          10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// BADGE
                            if (badgeText.isNotEmpty && !isThreeCol)
                              Opacity(
                                opacity: 0.9,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Material(
                                    color: Colors.transparent,
                                    elevation: 2,
                                    borderRadius: BorderRadius.circular(5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: badgeText == 'WINNER'
                                            ? const Color(0xFF22B162)
                                            : badgeText == 'SHORTLISTED'
                                                ? Colors.orange
                                                : Colors.blue,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: badgeText == 'WINNER'
                                              ? const Color(0xFF3FD384)
                                              : Colors.white24,
                                          width: 1,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            blurRadius: 4,
                                            color: Color(0x33000000),
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            /// TITLE
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                item['title']?.toString() ?? 'Untitled',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isThreeCol ? 11 : 15,
                                  fontWeight: FontWeight.w500,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(2, 2),
                                      blurRadius: 5,
                                    )
                                  ],
                                ),
                              ),
                            ),

                            /// SUBTITLE
                            Text(
                              'Sed ut perspiciatis',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF9E9D9D),
                                fontSize: isThreeCol ? 9 : 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        /// SCORE BOX
        Align(
          alignment: const AlignmentDirectional(0.85, 1.13),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              width: 34,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7E7E7E),
                    Color(0xFF252525),
                  ],
                  begin: AlignmentDirectional(0, -1),
                  end: AlignmentDirectional(0, 1),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  highestScore.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardOverlay(
    Map<String, dynamic> item,
    bool isThreeCol,
    double highestScore,
    String badgeText,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(isThreeCol ? 6 : 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xEE000000),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeText.isNotEmpty && !isThreeCol) _statusBadge(badgeText),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['title']?.toString() ?? 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isThreeCol ? 10 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    highestScore.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bgColor = Colors.blue;

    if (status.toLowerCase() == 'winner') {
      bgColor = const Color(0xFF3E82FC);
    } else if (status.toLowerCase() == 'shortlisted') {
      bgColor = const Color(0xFF4FC3A1);
    } else if (status.toLowerCase() == 'rejected') {
      bgColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _errorPlaceholder(bool isThreeCol) {
    return Container(
      color: const Color(0xFF252830),
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white.withOpacity(0.1),
          size: isThreeCol ? 20 : 30,
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => _fetchData(isInitial: true),
            child: const Text('RETRY'),
          ),
        ],
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
              ? FlutterFlowTheme.of(context).primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }
}
