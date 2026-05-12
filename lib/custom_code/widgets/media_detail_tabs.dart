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

class MediaDetailTabs extends StatefulWidget {
  const MediaDetailTabs({
    super.key,
    this.width,
    this.height,
    required this.mediaId,
    this.averageScore,
    this.highestScore,
    this.metadataJson,
    this.processingDataJson,
    this.entryNumber,
    this.captureDate,
    this.selectedMediaFileUrl,
  });

  final double? width;
  final double? height;
  final String mediaId;
  final String? selectedMediaFileUrl;
  final double? averageScore;
  final double? highestScore;
  final String? metadataJson;
  final String? processingDataJson;
  final String? entryNumber;
  final String? captureDate;

  @override
  State<MediaDetailTabs> createState() => _MediaDetailTabsState();
}

class _MediaDetailTabsState extends State<MediaDetailTabs> {
  int _selectedTab = 0;
  bool _showFullProcessing = false;
  bool _showFullHistory = false;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'SCORE', 'icon': Icons.star_rounded},
    {'label': 'HISTORY', 'icon': Icons.history_rounded},
    {'label': 'ENTRIES', 'icon': Icons.emoji_events_rounded},
    {'label': 'NOTES', 'icon': Icons.note_alt_rounded},
    {'label': 'SALES', 'icon': Icons.attach_money_rounded},
  ];

  // JSON parse helpers
  Map<String, dynamic> _parseJson(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  // Date format karo
  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  // Metadata header
  Widget _buildMetadataHeader() {
    final meta = _parseJson(widget.metadataJson);
    final camera = meta['camera']?.toString() ?? '—';
    final exposure = meta['exposure']?.toString() ?? '—';
    final iso = meta['iso']?.toString() ?? '—';
    final focalLength = meta['focal_length']?.toString() ?? '—';

    return Container(
      padding: const EdgeInsets.all(14),
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
                  'Entry #${widget.entryNumber ?? '—'}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 10),
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

  String _truncate(String val, int max) =>
      val.length > max ? '${val.substring(0, max)}…' : val;

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

  // Tab bar
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // SCORE TAB
  Widget _buildScoreTab() {
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
              _scoreBox('Average Score', avg),
              const SizedBox(width: 12),
              _scoreBox('Highest Score', high),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(String label, double score) {
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

  // HISTORY TAB — processing_data se
  Widget _buildHistoryTab() {
    final proc = _parseJson(widget.processingDataJson);
    final software = proc['software']?.toString() ?? '';
    final historyWhen = proc['history_when']?.toString() ?? '';
    final historyAgent = proc['history_agent']?.toString() ?? '';

    // Agents aur dates list mein split karo
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

          // See More / See Less
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

  // ENTRIES TAB
  Widget _buildEntriesTab() {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined,
                    color: Colors.white.withOpacity(0.3), size: 24),
                const SizedBox(width: 12),
                Text(
                  'No competition entries yet',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NOTES TAB
  Widget _buildNotesTab() {
    final noteController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notes & Critiques',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Text('Add Private Note',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Write your thoughts...',
              hintStyle:
                  TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: FlutterFlowTheme.of(context).primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('ADD NOTE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  // SALES TAB
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
              Expanded(
                child: _salesBox('Total Revenue', '\$0.00'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _salesBox('Licenses', '0'),
              ),
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

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildScoreTab(),
      _buildHistoryTab(),
      _buildEntriesTab(),
      _buildNotesTab(),
      _buildSalesTab(),
    ];

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF13161A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMetadataHeader(),
            const Divider(color: Colors.white12, height: 1),
            _buildTabBar(),
            const Divider(color: Colors.white12, height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: tabs[_selectedTab],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
