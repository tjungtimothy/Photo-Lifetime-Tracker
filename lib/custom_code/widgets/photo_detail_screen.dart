// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'dart:ui';

// ════════════════════════════════════════════════════════════════════════════
// PHOTO DETAIL SCREEN — unified sliver widget
// ════════════════════════════════════════════════════════════════════════════
// Architecture:
//   CustomScrollView
//   ├─ SliverAppBar (collapsing image header + back button)
//   ├─ SliverPersistentHeader (title + maker name)
//   ├─ SliverPersistentHeader (metadata strip)
//   ├─ SliverPersistentHeader (PINNED tab bar)
//   └─ SliverList (tab content)
//
// As you scroll:
//   - Image fades out smoothly
//   - Back button stays at top (system area)
//   - Tab bar pins at top when reached
//   - Content scrolls freely underneath
// ════════════════════════════════════════════════════════════════════════════

class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({
    super.key,
    this.width,
    this.height,
    required this.mediaId,
    required this.imageUrl,
    this.title,
    this.makerName,
    this.makerTagline,
    this.averageScore,
    this.highestScore,
    this.metadataJson,
    this.processingDataJson,
    this.entryNumber,
    this.captureDate,
    this.entriesJson,
    this.onBack,
  });

  final double? width;
  final double? height;
  final String mediaId;
  final String imageUrl;
  final String? title;
  final String? makerName;
  final String? makerTagline;
  final double? averageScore;
  final double? highestScore;
  final String? metadataJson;
  final String? processingDataJson;
  final String? entryNumber;
  final String? captureDate;
  final String? entriesJson;
  final Future<dynamic> Function()? onBack;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  int _selectedTab = 0;
  bool _showFullHistory = false;

  // Entries
  List<Map<String, dynamic>>? _entries;
  bool _entriesLoading = false;
  String? _entriesError;

  // Scroll controller for fade effects
  final ScrollController _scrollCtrl = ScrollController();
  double _scrollOffset = 0;

  static const double _headerMaxHeight = 380;
  static const double _headerMinHeight = 0;
  static const double _tabBarHeight = 52;
  static const double _titleHeight = 64;
  static const double _metaHeight = 72;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'SCORE', 'icon': Icons.star_rounded},
    {'label': 'HISTORY', 'icon': Icons.history_rounded},
    {'label': 'ENTRIES', 'icon': Icons.emoji_events_rounded},
    {'label': 'NOTES', 'icon': Icons.note_alt_rounded},
    {'label': 'SALES', 'icon': Icons.attach_money_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries();
    });
    _scrollCtrl.addListener(() {
      if (mounted) {
        setState(() => _scrollOffset = _scrollCtrl.offset);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Future<void> _loadEntries() async {
  //   setState(() {
  //     _entriesLoading = true;
  //     _entriesError = null;
  //   });

  //   try {
  //     // Hardcoded ID se test karo
  //     const testId = 'e5e633ae-daec-40c6-9251-506d766538b8';

  //     final response = await SupaFlow.client
  //         .from('v_media_competition_entries')
  //         .select()
  //         .eq('media_id', testId);

  //     if (!mounted) return;
  //     setState(() {
  //       _entries = List<Map<String, dynamic>>.from(response as List);
  //       _entriesLoading = false;
  //       _entriesError = null;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _entriesError = e.toString();
  //       _entriesLoading = false;
  //     });
  //   }
  // }
  Future<void> _loadEntries() async {
    if (widget.entriesJson != null && widget.entriesJson!.isNotEmpty) {
      try {
        final parsed = jsonDecode(widget.entriesJson!);
        if (parsed is List) {
          setState(() {
            _entries =
                parsed.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          });
          return;
        }
      } catch (_) {}
    }

    setState(() => _entriesLoading = true);
    try {
      final response = await SupaFlow.client
          .from('v_media_competition_entries')
          .select()
          .eq('media_id', widget.mediaId)
          .order('submittal_deadline', ascending: false, nullsFirst: false);

      if (!mounted) return;
      setState(() {
        _entries = List<Map<String, dynamic>>.from(response as List);
        _entriesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entriesError = e.toString();
        _entriesLoading = false;
      });
    }
  }

  Map<String, dynamic> _parseJson(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  String _truncate(String val, int max) =>
      val.length > max ? '${val.substring(0, max)}…' : val;

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: Container(
        color: const Color(0xFF0A0C0F),
        child: Stack(
          children: [
            // Main scroll view with slivers
            CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildSliverImageHeader(),
                _buildSliverTitleSection(),
                _buildSliverMetadataSection(),
                _buildSliverTabBar(context),
                _buildSliverTabContent(context),
              ],
            ),
            // Floating back button (always visible at top)
            _buildBackButton(context),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BACK BUTTON (floats above everything)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBackButton(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final hideOpacity =
        1.0 - (_scrollOffset / _headerMaxHeight).clamp(0.0, 1.0);

    return Positioned(
      top: safeTop + 8,
      left: 12,
      right: 12,
      child: IgnorePointer(
        ignoring: hideOpacity < 0.1, // small threshold for clickability
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: hideOpacity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Action buttons (eye + close)
              _circleBtn(Icons.visibility_outlined, () {
                context.pushNamed('FullScreenImageViewer');
              }),
              const SizedBox(width: 8),
              _circleBtn(Icons.close_rounded, () async {
                if (widget.onBack != null) {
                  await widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
              100), // Perfect circular shape for gradient container
          gradient: const LinearGradient(
            colors: [
              Color(0xE5A4A4A4), // Alpha/Opacity (E5) first, then hex (A4A4A4)
              Color(0x99252525), // Alpha/Opacity (99) first, then hex (252525)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLIVER 1: IMAGE HEADER (fades on scroll)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSliverImageHeader() {
    return SliverAppBar(
      pinned: false,
      floating: false,
      stretch: true,
      expandedHeight: _headerMaxHeight,
      collapsedHeight: _headerMinHeight + 0.1, // near-zero (just enough)
      toolbarHeight: 0,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF0A0C0F),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        collapseMode: CollapseMode.parallax,
        background: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    // Fade based on scroll
    final fadeStart = 100.0;
    final fadeEnd = 320.0;
    final opacity = 1 -
        ((_scrollOffset - fadeStart) / (fadeEnd - fadeStart)).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Container(
        color: const Color(0xFF1A1D21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (widget.imageUrl.isNotEmpty &&
                widget.imageUrl.startsWith('http'))
              Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFF1A1D21),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  );
                },
              )
            else
              _imagePlaceholder(),
            // Bottom gradient for smooth transition into title section
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0A0C0F).withOpacity(0.8),
                      const Color(0xFF0A0C0F),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFF1A1D21),
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white.withOpacity(0.2),
          size: 48,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLIVER 2: TITLE + MAKER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSliverTitleSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((widget.title ?? '').isNotEmpty)
              Text(
                widget.title!,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2),
              ),
            if ((widget.makerName ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.makerName!,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        if ((widget.makerTagline ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.makerTagline!,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Tier badge (optional — pull from highest_score later)
                  if ((widget.highestScore ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.greenAccent.withOpacity(0.4)),
                      ),
                      child: Text(
                        widget.highestScore! >= 90
                            ? 'WINNER'
                            : widget.highestScore! >= 80
                                ? 'MERIT'
                                : 'JUDGED',
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLIVER 3: METADATA STRIP
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSliverMetadataSection() {
    return SliverToBoxAdapter(
      child: _buildMetadataHeader(),
    );
  }

  Widget _buildMetadataHeader() {
    final meta = _parseJson(widget.metadataJson);
    final camera = meta['camera']?.toString() ?? '—';
    final exposure = meta['exposure']?.toString() ?? '—';
    final iso = meta['iso']?.toString() ?? '—';
    final focalLength = meta['focal_length']?.toString() ?? '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Metadata',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.entryNumber != null && widget.entryNumber!.isNotEmpty
                      ? '#${widget.entryNumber!.replaceFirst('private/', '').substring(0, widget.entryNumber!.replaceFirst('private/', '').length.clamp(0, 6))}…'
                      : '—',
                  //'Entry #${widget.entryNumber ?? '—'}',
                  style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10),
                ),
              ),
              if (widget.captureDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDate(widget.captureDate),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metaItem('Camera', _truncate(camera, 14)),
              _metaItem('Exposure', exposure),
              _metaItem('ISO', iso),
              _metaItem('Focal Length', focalLength),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLIVER 4: PINNED TAB BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSliverTabBar(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedTabBarDelegate(
        height: _tabBarHeight,
        child: _buildTabBar(context),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0C0F),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = _selectedTab == index;
                  final showBadge = _tabs[index]['label'] == 'ENTRIES' &&
                      _entries != null &&
                      _entries!.isNotEmpty;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? FlutterFlowTheme.of(context).primary
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? FlutterFlowTheme.of(context).primary
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_tabs[index]['icon'] as IconData,
                              size: 12,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4)),
                          const SizedBox(width: 5),
                          Text(
                            _tabs[index]['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (showBadge) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.25)
                                    : FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_entries!.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.08),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLIVER 5: TAB CONTENT (scrolls with rest)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSliverTabContent(BuildContext context) {
    Widget content;
    switch (_selectedTab) {
      case 0:
        content = _buildScoreTab(context);
        break;
      case 1:
        content = _buildHistoryTab(context);
        break;
      case 2:
        content = _buildEntriesTab(context);
        break;
      case 3:
        content = _buildNotesTab(context);
        break;
      case 4:
        content = _buildSalesTab();
        break;
      default:
        content = const SizedBox();
    }

    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFF0A0C0F),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: content,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCORE TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScoreTab(BuildContext context) {
    final avg = widget.averageScore ?? 0;
    final high = widget.highestScore ?? 0;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Judge Critique',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                      child: const Text('J',
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Judge',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text('Certified Judge',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Critique details will appear here once judging is complete.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _scoreBox('Average Score', avg, context),
              const SizedBox(width: 12),
              _scoreBox('Highest Score', high, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(String label, double score, BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 11)),
            const SizedBox(height: 6),
            Text(
              score > 0 ? score.toStringAsFixed(1) : '—',
              style: TextStyle(
                color: score > 0 ? Colors.white : Colors.white.withOpacity(0.3),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HISTORY TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHistoryTab(BuildContext context) {
    final proc = _parseJson(widget.processingDataJson);
    final software = proc['software']?.toString() ?? '';
    final historyWhen = proc['history_when']?.toString() ?? '';
    final historyAgent = proc['history_agent']?.toString() ?? '';

    final agents = historyAgent.isNotEmpty
        ? historyAgent.split(',').map((e) => e.trim()).toList()
        : <String>[];
    final dates = historyWhen.isNotEmpty
        ? historyWhen.split(',').map((e) => e.trim()).toList()
        : <String>[];

    final maxItems = _showFullHistory ? agents.length : 3;
    final displayAgents = agents.take(maxItems).toList();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Processing History',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (software.isNotEmpty)
            Text(
              'Software: $software',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
            ),
          const SizedBox(height: 12),
          if (displayAgents.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('No processing history available',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12)),
            )
          else
            ...List.generate(displayAgents.length, (i) {
              final agent = displayAgents[i];
              final date = i < dates.length ? _formatDate(dates[i]) : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(agent,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          if (date.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(date,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 10)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (agents.length > 3)
            GestureDetector(
              onTap: () => setState(() => _showFullHistory = !_showFullHistory),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showFullHistory
                          ? 'See Less'
                          : 'See More (${agents.length - 3} more)',
                      style: TextStyle(
                          color: FlutterFlowTheme.of(context).primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showFullHistory
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENTRIES TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEntriesTab(BuildContext context) {
    if (_entriesLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child:
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
        ),
      );
    }

    if (_entriesError != null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text('Could not load entries',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              Text(_entriesError!,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 11)),
              const SizedBox(height: 10),
              TextButton(onPressed: _loadEntries, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_entries == null || _entries!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Competition Entries',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined,
                      color: Colors.white.withOpacity(0.3), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No competition entries yet',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('Submit this image to a contest to get started',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Group entries by year
    final byYear = <String, List<Map<String, dynamic>>>{};
    for (final e in _entries!) {
      final raw = e['judging_date']?.toString() ?? e['entry_date']?.toString();
      String year = 'Undated';
      if (raw != null && raw.length >= 4) {
        try {
          year = raw.substring(0, 4);
        } catch (_) {}
      }
      byYear.putIfAbsent(year, () => []).add(e);
    }
    final years = byYear.keys.toList()
      ..sort((a, b) {
        if (a == 'Undated') return 1;
        if (b == 'Undated') return -1;
        return b.compareTo(a);
      });

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Competition Entries',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_entries!.length} total',
                    style: TextStyle(
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...years.map((year) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(year,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8)),
                  ),
                  ...byYear[year]!
                      .map((e) => _buildEntryCard(e, context))
                      .toList(),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry, BuildContext context) {
    // ✅ contest_name directly use karo
    final contestName = entry['contest_name']?.toString() ?? 'Unknown Contest';

    // ✅ organization_name UUID ho to skip karo
    final orgRaw = entry['organization_name']?.toString() ?? '';
    final orgName = (orgRaw.length == 36 && orgRaw.contains('-')) ? '' : orgRaw;

    // ✅ submittal_deadline use karo — judging_date 00:00 wala hai
    String displayDate = '';
    final sd = entry['submittal_deadline']?.toString() ?? '';
    final jd = entry['judging_date']?.toString() ?? '';
    if (sd.isNotEmpty && !sd.startsWith('00:')) {
      displayDate = _formatDate(sd);
    } else if (jd.isNotEmpty && !jd.startsWith('00:')) {
      displayDate = _formatDate(jd);
    }

    final avgScore = entry['avg_score'];
    final maxScore = entry['max_score'];
    final judgeCount = entry['judge_count'];
    final resultBadge = entry['result_badge']?.toString() ?? 'SUBMITTED';
    final awardName = entry['award_name']?.toString();
    final awardColorHex = entry['award_color_hex']?.toString();
    final scoreAwardText = entry['score_award_text']?.toString();
    final badgeStyle = _badgeStyle(resultBadge, awardColorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contestName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3)),
                    if (orgName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(orgName,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _resultBadge(badgeStyle, awardName ?? scoreAwardText),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (avgScore != null) ...[
                _scoreChip(
                    'Avg',
                    avgScore is num
                        ? avgScore.toStringAsFixed(1)
                        : avgScore.toString(),
                    accent: false,
                    context: context),
                const SizedBox(width: 6),
              ],
              if (maxScore != null) ...[
                _scoreChip(
                    'High',
                    maxScore is num
                        ? maxScore.toStringAsFixed(0)
                        : maxScore.toString(),
                    accent: true,
                    context: context),
                const SizedBox(width: 6),
              ],
              if (judgeCount != null && (judgeCount as num) > 0)
                _scoreChip('$judgeCount Judges', '',
                    accent: false, context: context),
              const Spacer(),
              if (displayDate.isNotEmpty)
                Text(displayDate,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _badgeStyle(String code, String? customHex) {
    Color bg;
    String label;
    switch (code) {
      case 'IE':
        bg = const Color(0xFFFFA500);
        label = 'IE';
        break;
      case 'MERIT':
        bg = const Color(0xFFA569BD);
        label = 'MERIT';
        break;
      case 'POTENTIAL':
        bg = const Color(0xFFF4D03F);
        label = 'POTENTIAL';
        break;
      case 'HIGH_SCORE':
        bg = const Color(0xFF52BE80);
        label = '80+';
        break;
      case 'IN_REVIEW':
        bg = const Color(0xFF5DADE2);
        label = 'IN REVIEW';
        break;
      case 'JUDGED':
        bg = Colors.white.withOpacity(0.15);
        label = 'JUDGED';
        break;
      default:
        bg = Colors.white.withOpacity(0.10);
        label = 'SUBMITTED';
    }
    if (customHex != null && customHex.isNotEmpty) {
      try {
        bg = Color(int.parse('FF${customHex.replaceAll('#', '')}', radix: 16));
      } catch (_) {}
    }
    return {'bg': bg, 'label': label};
  }

  Widget _resultBadge(Map<String, dynamic> style, String? awardText) {
    final bg = style['bg'] as Color;
    final label = (awardText != null && awardText.isNotEmpty)
        ? awardText.toUpperCase()
        : style['label'] as String;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }

  Widget _scoreChip(String label, String value,
      {required bool accent, required BuildContext context}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent
            ? FlutterFlowTheme.of(context).primary.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: accent
                ? FlutterFlowTheme.of(context).primary.withOpacity(0.4)
                : Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    color: accent
                        ? FlutterFlowTheme.of(context).primary
                        : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTES TAB → embeds CritiqueTab from custom_widgets
  // ══════════════════════════════════════════════════════════════════════════
  // Widget _buildNotesTab(BuildContext context) {
  //   // ✅ No fixed height — uses MediaQuery so it adapts to device
  //   return SizedBox(
  //     height: MediaQuery.of(context).size.height * 0.75,
  //     child: CritiqueTab(
  //       mediaId: widget.mediaId,
  //       width: widget.width,
  //     ),
  //   );
  // }
  Widget _buildNotesTab(BuildContext context) {
    // mediaId empty ho to AppState se lo
    final id = widget.mediaId.isNotEmpty
        ? widget.mediaId
        : FFAppState().selectedMediaId;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: CritiqueTab(
        mediaId: id, // ← yeh fix hai
        width: widget.width,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SALES TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSalesTab() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sales & Licensing',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _salesBox('Total Revenue', '\$0.00')),
              const SizedBox(width: 10),
              Expanded(child: _salesBox('Licenses', '0')),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Recent Transactions',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('No transactions yet',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _salesBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 10)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PINNED TAB BAR DELEGATE
// ════════════════════════════════════════════════════════════════════════════
class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _PinnedTabBarDelegate({required this.height, required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.transparent,
      elevation: overlapsContent ? 4 : 0,
      shadowColor: Colors.black54,
      child: child,
    );
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(_PinnedTabBarDelegate old) =>
      child != old.child || height != old.height;
}
