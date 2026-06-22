// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/widgets/index.dart';

import 'dart:convert';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════
const Color _kBg = Color(0xFF0E1116);
const Color _kCard = Color(0xFF161B22);
const Color _kBorder = Color(0xFF22272F);
const Color _kAccent = Color(0xFF379DF0);
const Color _kTextPrimary = Color(0xFFE6EDF3);
const Color _kTextSecondary = Color(0xFF8B949E);
const Color _kTextMuted = Color(0xFF6E7681);
const Color _kGold = Color(0xFFFFD700);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.width, this.height});
  final double? width;
  final double? height;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _supabase = Supabase.instance.client;

  bool _loading = false;
  bool _exportingCsv = false;
  bool _exportingPdf = false;
  bool _showAllPreview = false;

  // ── PREMIUM EXPORT TOGGLE (Advanced / Future Premium) ──────────────────
  /// When false, export buttons are locked behind a premium badge.
  /// Flip to true once user upgrades. For now default is OFF.
  bool _exportUnlocked = false;

  // Filter chips
  bool _chipWinners = false;
  int _chipHighScore = 0;
  int _chipSeasonYear = 0;

  // Dropdowns
  String _status = 'All Status';
  String _category = 'All Category';
  DateTimeRange? _dateRange;

  // Data
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic> _stats = {
    'total_submissions': 0,
    'avg_score': 0.0,
    'max_score': 0,
    'winners': 0,
  };

  List<String> _statusOptions = const ['All Status'];
  List<String> _categoryOptions = const ['All Category'];

  @override
  void initState() {
    super.initState();
    _processExport(previewOnly: true);
  }

  // ── Badge helpers ──
  Map<String, dynamic> _badgeStyle(String badge) {
    switch (badge) {
      case 'IE':
        return {'label': 'IE', 'color': const Color(0xFFFFD700)};
      case 'MERIT':
        return {'label': 'MERIT', 'color': const Color(0xFF7C3AED)};
      case 'HIGH_SCORE':
        return {'label': '80+', 'color': const Color(0xFF52BE80)};
      case 'IN_REVIEW':
        return {'label': 'IN REVIEW', 'color': const Color(0xFF5DADE2)};
      case 'JUDGED':
        return {'label': 'JUDGED', 'color': Colors.white.withOpacity(0.4)};
      default:
        return {'label': 'SUBMITTED', 'color': Colors.white.withOpacity(0.2)};
    }
  }

  Map<String, dynamic> _buildFilters() {
    final filters = <String, dynamic>{};
    if (_chipWinners) filters['winners_only'] = true;
    if (_chipHighScore > 0) filters['min_avg_score'] = _chipHighScore;
    if (_chipSeasonYear > 0) filters['season_year'] = _chipSeasonYear;
    if (_status != 'All Status') filters['status'] = _status;
    if (_category != 'All Category') filters['category'] = _category;
    if (_dateRange != null) {
      filters['date_field'] = 'judging_date';
      filters['date_from'] = _dateRange!.start.toUtc().toIso8601String();
      filters['date_to'] = _dateRange!.end.toUtc().toIso8601String();
    }
    return filters;
  }

  Future<void> _processExport({required bool previewOnly}) async {
    setState(() => _loading = true);
    try {
      final filters = _buildFilters();

      final entriesResp = await _supabase.rpc('report_entries', params: {
        'filters': filters,
        'preview_limit': previewOnly ? 10 : null,
      });

      final statsResp = await _supabase.rpc('report_stats', params: {
        'filters': filters,
      });

      final rows = (entriesResp as List)
          .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
          .toList();

      final statsRow = (statsResp as List).isNotEmpty
          ? (statsResp as List).first as Map
          : <String, dynamic>{};

      final statusSet = <String>{'All Status'};
      final categorySet = <String>{'All Category'};
      for (final r in rows) {
        final s = (r['status'] ?? '').toString().trim();
        final c = (r['category'] ?? '').toString().trim();
        if (s.isNotEmpty) statusSet.add(s);
        if (c.isNotEmpty) categorySet.add(c);
      }

      if (mounted) {
        setState(() {
          _rows = rows;
          _stats = statsRow.map((k, v) => MapEntry(k.toString(), v));
          _statusOptions = statusSet.toList();
          _categoryOptions = categorySet.toList();
          _showAllPreview = false;
        });
      }
    } catch (e) {
      debugPrint('ReportsScreen RPC error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── CSV ──
  String _buildCsv(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';
    const cols = [
      'title',
      'contest_name',
      'organization_name',
      'judging_date',
      'status',
      'category',
      'avg_score',
      'max_score',
      'min_score',
      'judge_count',
      'result_badge',
    ];
    String esc(String s) {
      final needsQuotes =
          s.contains(',') || s.contains('\n') || s.contains('"');
      return needsQuotes ? '"${s.replaceAll('"', '""')}"' : s;
    }

    final lines = [cols.join(',')];
    for (final r in rows) {
      lines.add(cols.map((c) => esc((r[c] ?? '').toString())).join(','));
    }
    return lines.join('\n');
  }

  Future<void> _exportCsv() async {
    // Guard: export is a premium feature
    if (!_exportUnlocked) {
      _showPremiumDialog('CSV Export');
      return;
    }
    setState(() => _exportingCsv = true);
    try {
      final resp = await _supabase.rpc('report_entries', params: {
        'filters': _buildFilters(),
        'preview_limit': null,
      });
      final rows = (resp as List)
          .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
          .toList();
      final csv = _buildCsv(rows);
      if (csv.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No data to export.')));
        }
        return;
      }
      final filename = 'report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csv, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv', name: filename)],
        text: 'Photo Tracker CSV Export',
      );
    } catch (e) {
      debugPrint('CSV error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('CSV export failed.')));
      }
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
  }

  Future<void> _exportPdf() async {
    // Guard: export is a premium feature
    if (!_exportUnlocked) {
      _showPremiumDialog('PDF Export');
      return;
    }
    setState(() => _exportingPdf = true);
    try {
      final res = await _supabase.functions.invoke(
        'export-pdf',
        body: {'filters': _buildFilters(), 'title': 'Reports & Exports'},
      );
      if (res.status != 200) {
        throw Exception('export-pdf failed: status=${res.status}');
      }
      final data = res.data as Map;
      final filename = (data['filename'] ?? 'report.pdf').toString();
      final b64 = data['pdf_base64']?.toString();
      if (b64 == null || b64.isEmpty) {
        throw Exception('No pdf_base64 in response');
      }
      final bytes = base64Decode(b64);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: filename)],
        text: 'PDF Report',
      );
    } catch (e) {
      debugPrint('PDF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PDF export failed.')));
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  /// Shows a friendly dialog when user tries to use a locked premium feature.
  void _showPremiumDialog(String featureName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: _kGold, size: 20),
            SizedBox(width: 8),
            Text('Premium Feature',
                style: TextStyle(color: _kTextPrimary, fontSize: 16)),
          ],
        ),
        content: Text(
          '$featureName is available for advanced users.\n\nUpgrade to unlock full data exports, PDF reports, and more.',
          style: const TextStyle(color: _kTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Not Now', style: TextStyle(color: _kTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: navigate to upgrade / paywall screen
            },
            child: const Text('Upgrade',
                style: TextStyle(color: _kGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final res = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kAccent,
            onPrimary: Colors.white,
            surface: _kCard,
            onSurface: _kTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (res == null) return;
    setState(() => _dateRange = res);
    await _processExport(previewOnly: true);
  }

  Future<void> _setSeasonYear() async {
    final ctrl = TextEditingController(
      text: _chipSeasonYear == 0
          ? DateTime.now().year.toString()
          : _chipSeasonYear.toString(),
    );
    final year = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        title:
            const Text('Season Year', style: TextStyle(color: _kTextPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _kTextPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. 2026',
            hintStyle: TextStyle(color: _kTextMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: _kTextSecondary))),
          TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, int.tryParse(ctrl.text.trim())),
              child: const Text('Set', style: TextStyle(color: _kAccent))),
        ],
      ),
    );
    if (year == null) return;
    setState(() => _chipSeasonYear = year);
    await _processExport(previewOnly: true);
  }

  // ═══════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final visibleRows = _showAllPreview ? _rows : _rows.take(5).toList();
    final totalSub = _stats['total_submissions'] ?? 0;
    final avgScore = _stats['avg_score'];
    final maxScore = _stats['max_score'] ?? 0;
    final winners = _stats['winners'] ?? 0;

    String avgStr = '—';
    if (avgScore != null) {
      final d = double.tryParse(avgScore.toString());
      avgStr = d != null ? d.toStringAsFixed(1) : avgScore.toString();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            const Text('Reports & Exports',
                style: TextStyle(
                    color: _kTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Generate comprehensive data exports and performance summaries.',
              style: TextStyle(color: _kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // ── Advanced Export Toggle Panel ──────────────────────────────
            _buildExportTogglePanel(),
            const SizedBox(height: 14),

            // ── Query Builder ──
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded,
                          color: _kAccent, size: 16),
                      const SizedBox(width: 6),
                      const Text('Query Builder',
                          style: TextStyle(
                              color: _kTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Active filter chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChip(
                        label: 'WINNERS',
                        selected: _chipWinners,
                        onTap: () async {
                          setState(() => _chipWinners = !_chipWinners);
                          await _processExport(previewOnly: true);
                        },
                      ),
                      _filterChip(
                        label: _chipHighScore > 0
                            ? 'HIGH SCORE (≥$_chipHighScore)'
                            : 'HIGH SCORE',
                        selected: _chipHighScore > 0,
                        onTap: () async {
                          setState(() =>
                              _chipHighScore = _chipHighScore > 0 ? 0 : 80);
                          await _processExport(previewOnly: true);
                        },
                      ),
                      _filterChip(
                        label: _chipSeasonYear > 0
                            ? '$_chipSeasonYear SEASON'
                            : 'SEASON',
                        selected: _chipSeasonYear > 0,
                        onTap: _setSeasonYear,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Status dropdown
                  _dropdownField(
                    label: 'Status',
                    value: _status,
                    items: _statusOptions,
                    onChanged: (v) async {
                      setState(() => _status = v);
                      await _processExport(previewOnly: true);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Category dropdown
                  _dropdownField(
                    label: 'Category',
                    value: _category,
                    items: _categoryOptions,
                    onChanged: (v) async {
                      setState(() => _category = v);
                      await _processExport(previewOnly: true);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Date range
                  GestureDetector(
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Row(
                        children: [
                          const Text('Date Range',
                              style: TextStyle(
                                  color: _kTextSecondary, fontSize: 13)),
                          const Spacer(),
                          Text(
                            _dateRange == null
                                ? 'All Date Range'
                                : '${DateFormat('yyyy-MM-dd').format(_dateRange!.start)} → ${DateFormat('yyyy-MM-dd').format(_dateRange!.end)}',
                            style: TextStyle(
                                color:
                                    _dateRange == null ? _kTextMuted : _kAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: _dateRange == null ? _kTextMuted : _kAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_dateRange != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        setState(() => _dateRange = null);
                        await _processExport(previewOnly: true);
                      },
                      child: const Text('Clear date filter',
                          style: TextStyle(color: _kAccent, fontSize: 11)),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Process export button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () => _processExport(previewOnly: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        disabledBackgroundColor: _kAccent.withOpacity(0.4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('PROCESS EXPORT',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Preview ──
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.grid_view_rounded,
                          color: _kAccent, size: 16),
                      const SizedBox(width: 6),
                      const Text('Preview',
                          style: TextStyle(
                              color: _kTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (_rows.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_rows.length} rows',
                            style: const TextStyle(
                                color: _kAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Center(
                        child: CircularProgressIndicator(
                            color: _kAccent, strokeWidth: 2))
                  else if (_rows.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('No results found.',
                            style: TextStyle(
                                color: _kTextSecondary, fontSize: 13)),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...visibleRows.map((r) => _previewCard(r)),
                        if (_rows.length > 5) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(
                                () => _showAllPreview = !_showAllPreview),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _kBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _kBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _showAllPreview
                                        ? 'Show Less'
                                        : 'Show More (${_rows.length - 5} more)',
                                    style: const TextStyle(
                                        color: _kAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _showAllPreview
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: _kAccent,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: 14),

                  // ── Export Buttons (locked overlay when not unlocked) ──
                  _buildExportButtons(),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Quick Stats ──
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: _kAccent, size: 16),
                      SizedBox(width: 6),
                      Text('Quick Stats',
                          style: TextStyle(
                              color: _kTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statBox('Total\nSubmissions', '$totalSub',
                          Icons.collections_rounded),
                      const SizedBox(width: 10),
                      _statBox('Avg\nScore', avgStr, Icons.star_rounded,
                          accent: true),
                      const SizedBox(width: 10),
                      _statBox('Max\nScore', '$maxScore',
                          Icons.emoji_events_rounded),
                      const SizedBox(width: 10),
                      _statBox(
                          'Winners', '$winners', Icons.military_tech_rounded,
                          accent: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // EXPORT TOGGLE PANEL
  // ═══════════════════════════════════════════════════

  Widget _buildExportTogglePanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _exportUnlocked ? _kGold.withOpacity(0.35) : _kBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: _exportUnlocked ? _kGold : _kTextMuted,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Export Settings',
                style: TextStyle(
                    color: _kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              // Premium badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _kGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _kGold.withOpacity(0.45)),
                ),
                child: const Text(
                  '★ Premium',
                  style: TextStyle(
                      color: _kGold, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Enable to unlock CSV and PDF export for advanced reporting.',
            style: TextStyle(color: _kTextMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF22272F), height: 1),
          const SizedBox(height: 12),

          // ── Toggle row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.ios_share_rounded,
                  size: 15,
                  color:
                      _exportUnlocked ? _kGold : _kTextMuted.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Enable Data Exports',
                          style: TextStyle(
                            color: _exportUnlocked
                                ? _kTextPrimary
                                : _kTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _exportUnlocked
                          ? 'CSV & PDF export are unlocked. Data ready to share.'
                          : 'Upgrade to export full reports as CSV or PDF.',
                      style: TextStyle(
                          color: _exportUnlocked
                              ? _kGold.withOpacity(0.7)
                              : _kTextMuted,
                          fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _exportUnlocked,
                  onChanged: (v) => setState(() => _exportUnlocked = v),
                  activeColor: _kGold,
                  activeTrackColor: _kGold.withOpacity(0.25),
                  inactiveThumbColor: Colors.white24,
                  inactiveTrackColor: Colors.white10,
                ),
              ),
            ],
          ),

          // ── What's included hint ──
          if (!_exportUnlocked) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kGold.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kGold.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: _kGold, size: 13),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unlock includes: Full CSV export · PDF reports · Batch downloads',
                      style: TextStyle(
                          color: _kGold.withOpacity(0.75), fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // EXPORT BUTTONS (with locked state overlay)
  // ═══════════════════════════════════════════════════

  Widget _buildExportButtons() {
    return Stack(
      children: [
        // ── Actual buttons (always rendered, may be dimmed) ──
        Row(
          children: [
            Expanded(
              child: _exportBtn(
                icon: Icons.table_chart_rounded,
                label: 'Export CSV',
                loading: _exportingCsv,
                locked: !_exportUnlocked,
                onTap: _exportCsv,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _exportBtn(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Export PDF',
                loading: _exportingPdf,
                locked: !_exportUnlocked,
                onTap: _exportPdf,
                isPrimary: true,
              ),
            ),
          ],
        ),

        // ── Lock overlay when not unlocked ──
        if (!_exportUnlocked)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _showPremiumDialog('Data Export'),
              child: Container(
                decoration: BoxDecoration(
                  color: _kBg.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, color: _kGold, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Premium — tap to unlock',
                      style: TextStyle(
                          color: _kGold.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // PREVIEW CARD
  // ─────────────────────────────────────────────────
  Widget _previewCard(Map<String, dynamic> r) {
    final title = r['title']?.toString() ?? 'Untitled';
    final contestName = r['contest_name']?.toString() ?? '';
    final orgName = r['organization_name']?.toString() ?? '';
    final avgScore = r['avg_score']?.toString() ?? '—';
    final maxScore = r['max_score']?.toString() ?? '—';
    final judgeCount = r['judge_count'];
    final badge = r['result_badge']?.toString() ?? 'SUBMITTED';
    final fileUrl = r['file_path']?.toString() ?? '';
    final judgingDate = r['judging_date']?.toString() ?? '';

    String dateStr = '';
    if (judgingDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(judgingDate);
        dateStr = DateFormat('yyyy-MM-dd').format(dt);
      } catch (_) {}
    }

    final badgeInfo = _badgeStyle(badge);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
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
              width: 72,
              height: 80,
              child: fileUrl.startsWith('http')
                  ? Image.network(
                      fileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _kTextPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeInfo['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeInfo['label'] as String,
                          style: TextStyle(
                              color: badgeInfo['color'] as Color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (contestName.isNotEmpty)
                    Text(
                      orgName.isNotEmpty
                          ? '$orgName · $contestName'
                          : contestName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: _kTextSecondary, fontSize: 10),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _miniChip('Avg $avgScore', accent: false),
                      const SizedBox(width: 4),
                      _miniChip('High $maxScore', accent: true),
                      if (judgeCount != null &&
                          judgeCount.toString() != '0') ...[
                        const SizedBox(width: 4),
                        _miniChip('${judgeCount} J', accent: false),
                      ],
                      const Spacer(),
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: const TextStyle(
                                color: _kTextMuted, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      color: const Color(0xFF1A1D21),
      child: const Center(
        child: Icon(Icons.image_rounded, color: Colors.white24, size: 24),
      ),
    );
  }

  Widget _miniChip(String label, {required bool accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: accent
            ? _kAccent.withOpacity(0.12)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: accent ? _kAccent.withOpacity(0.3) : _kBorder),
      ),
      child: Text(label,
          style: TextStyle(
              color: accent ? _kAccent : _kTextSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600)),
    );
  }

  // ─────────────────────────────────────────────────
  // STAT BOX
  // ─────────────────────────────────────────────────
  Widget _statBox(String label, String value, IconData icon,
      {bool accent = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accent ? _kAccent.withOpacity(0.08) : _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent ? _kAccent.withOpacity(0.3) : _kBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: accent ? _kAccent : _kTextSecondary),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: accent ? _kAccent : _kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: _kTextMuted, fontSize: 9, height: 1.3)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withOpacity(0.15) : _kBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kAccent : _kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? _kAccent : _kTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Future<void> Function(String v) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: _kTextSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: _kCard,
              iconEnabledColor: _kTextSecondary,
              style: const TextStyle(color: _kTextPrimary, fontSize: 13),
              items: items
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style: const TextStyle(color: _kTextPrimary))))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                await onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _exportBtn({
    required IconData icon,
    required String label,
    required bool loading,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool locked = false,
  }) {
    final effectiveColor = locked
        ? _kTextMuted.withOpacity(0.4)
        : (isPrimary ? _kAccent : _kTextSecondary);

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary && !locked ? _kAccent.withOpacity(0.15) : _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: locked
                  ? _kBorder.withOpacity(0.4)
                  : (isPrimary ? _kAccent : _kBorder)),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kAccent),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(locked ? Icons.lock_rounded : icon,
                      size: 16, color: effectiveColor),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          color: effectiveColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
