// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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
          .order('capture_date', ascending: false)
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

  void _handleCardTap(Map<String, dynamic> item) {
    final String mediaId = item['id']?.toString() ?? '';

    // Update AppState
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

    // Trigger Callback
    widget.onCardTap(mediaId);
  }

  @override
  Widget build(BuildContext context) {
    // NavBar ki wajah se niche padding (80-90 pixels safe zone)
    const double navBarPadding = 84.0;

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: Column(
        children: [
          // Header: Count and Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_data.length} Items',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13)),
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
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorUI()
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildCard(_data[index]),
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

                          // Pagination Button & Bottom Padding
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 20, 16, navBarPadding),
                              child: _hasMore
                                  ? _buildLoadMoreButton()
                                  : Center(
                                      child: Text('End of Gallery',
                                          style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              fontSize: 12))),
                            ),
                          ),
                        ],
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
                child: CircularProgressIndicator(strokeWidth: 2)))
        : GestureDetector(
            onTap: () => _fetchData(isInitial: false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        FlutterFlowTheme.of(context).primary.withOpacity(0.3)),
              ),
              child: Center(
                child: Text('LOAD MORE',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    )),
              ),
            ),
          );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final bool isThreeCol = _crossAxisCount == 3;
    final String? fileUrl = item['file_path']?.toString();

    return GestureDetector(
      onTap: () => _handleCardTap(item),
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
            fileUrl != null && fileUrl.startsWith('http')
                ? Image.network(fileUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _errorPlaceholder(isThreeCol))
                : _errorPlaceholder(isThreeCol),
            _buildCardOverlay(item, isThreeCol),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOverlay(Map<String, dynamic> item, bool isThreeCol) {
    final String status = item['current_status']?.toString() ?? '';
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
            colors: [Color(0xEE000000), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.isNotEmpty && !isThreeCol) _statusBadge(status),
            Text(
              item['title']?.toString() ?? 'Untitled',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: isThreeCol ? 10 : 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    bool isProcessed = status.toLowerCase() == 'processed';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isProcessed
            ? Colors.green.withOpacity(0.8)
            : Colors.blue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status.toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _errorPlaceholder(bool isThreeCol) {
    return Container(
        color: const Color(0xFF252830),
        child: Center(
            child: Icon(Icons.image_rounded,
                color: Colors.white.withOpacity(0.1),
                size: isThreeCol ? 20 : 30)));
  }

  Widget _buildErrorUI() {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
      const SizedBox(height: 10),
      Text(_error!,
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center),
      TextButton(
          onPressed: () => _fetchData(isInitial: true),
          child: const Text('RETRY')),
    ]));
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
                  : Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon,
            size: 18,
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : Colors.white.withOpacity(0.4)),
      ),
    );
  }
}
