// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class SearchScreen extends StatefulWidget {
  const SearchScreen(
      {super.key, this.width, this.height, required this.onCardTap});

  final double? width;
  final double? height;
  final Future Function(String mediaId) onCardTap;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    // Auto focus keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    query = query.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() => _isLoading = true);

    try {
      final response = await SupaFlow.client
          .from('Media')
          .select(
              'id, title, file_path, average_score, highest_score, current_status, photo_address, capture_date, "Metadata", processing_data')
          .ilike('title', '%$query%')
          .limit(20);

      setState(() {
        _results = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  void _navigateToDetail(Map<String, dynamic> item) {
    final String mediaId = item['id']?.toString() ?? '';

    // Update AppState
    FFAppState().selectedMediaId = mediaId;
    FFAppState().selectedMediaId = item['id']?.toString() ?? '';
    FFAppState().selectedMediaTitle = item['title']?.toString() ?? '';
    FFAppState().selectedMediaFileUrl = item['file_path']?.toString() ?? '';
    FFAppState().selectedMediaAvgScore =
        double.tryParse(item['average_score']?.toString() ?? '0') ?? 0.0;
    FFAppState().selectedMediaHighScore =
        double.tryParse(item['highest_score']?.toString() ?? '0') ?? 0.0;
    FFAppState().selectedMediaMetadata = item['Metadata']?.toString() ?? '';
    FFAppState().selectedMediaProcessing =
        item['processing_data']?.toString() ?? '';
    FFAppState().selectedMediaEntry = item['photo_address']?.toString() ?? '';
    FFAppState().selectedMediaDate = item['capture_date']?.toString() ?? '';

    // ✅ Exactly yahi naam hai tumhara — screenshot mein dikh raha hai
    // context.pushNamed('profile_screen');
    widget.onCardTap(mediaId);
  }

  Widget _buildResultCard(Map<String, dynamic> item) {
    final String? fileUrl = item['file_path']?.toString();
    final double avgScore =
        double.tryParse(item['average_score']?.toString() ?? '0') ?? 0;
    final String status = item['current_status']?.toString() ?? '';
    final String date = item['capture_date']?.toString() ?? '';
    String formattedDate = '';
    try {
      if (date.isNotEmpty) {
        final dt = DateTime.parse(date);
        formattedDate =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0x181C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: fileUrl != null && fileUrl.startsWith('http')
                    ? Image.network(
                        fileUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF252830),
                          child: Icon(Icons.image_rounded,
                              color: Colors.white.withOpacity(0.15), size: 24),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF252830),
                        child: Icon(Icons.image_rounded,
                            color: Colors.white.withOpacity(0.15), size: 24),
                      ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item['title']?.toString() ?? 'Untitled',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Status + Score row
                    Row(
                      children: [
                        if (status.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == 'processed'
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status.toLowerCase() == 'processed'
                                    ? Colors.greenAccent
                                    : Colors.blueAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (avgScore > 0) ...[
                          const Icon(Icons.star_rounded,
                              size: 12, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            avgScore.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.amber, fontSize: 11),
                          ),
                        ],
                      ],
                    ),

                    // Date
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.25),
                size: 20,
              ),
            ),
          ],
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
          // ── Search Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: const Color(0x181C1E),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),

                // Search field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (val) {
                        // Debounce — 400ms baad search karo
                        Future.delayed(const Duration(milliseconds: 400), () {
                          if (_searchController.text == val) {
                            _search(val);
                          }
                        });
                        setState(() {});
                      },
                      onSubmitted: _search,
                      decoration: InputDecoration(
                        hintText: 'Search photos...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(0.4),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _results = [];
                                    _hasSearched = false;
                                    _lastQuery = '';
                                  });
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withOpacity(0.35),
                                  size: 18,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // ── Results ──
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: FlutterFlowTheme.of(context).primary,
                      strokeWidth: 2,
                    ),
                  )
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_rounded,
                                size: 48,
                                color: Colors.white.withOpacity(0.15)),
                            const SizedBox(height: 12),
                            Text(
                              'Search your photos',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Type a title to find photos',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.25),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_not_supported_rounded,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.15)),
                                const SizedBox(height: 12),
                                Text(
                                  'No photos found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) =>
                                _buildResultCard(_results[index]),
                          ),
          ),
        ],
      ),
    );
  }
}
