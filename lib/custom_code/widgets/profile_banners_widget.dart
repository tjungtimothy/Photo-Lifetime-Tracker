// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileBannersWidget extends StatefulWidget {
  const ProfileBannersWidget({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<ProfileBannersWidget> createState() => _ProfileBannersWidgetState();
}

// ============================================================
// COLORS
// Replace with your app theme colors if needed
// ============================================================

const kCardBg = Color(0xFF111827);
const kBgDark = Color(0xFF0B1220);
const kCardBorder = Color(0xFF1F2937);

const kTextPrimary = Colors.white;
const kTextSecondary = Color(0xFFCBD5E1);
const kTextMuted = Color(0xFF94A3B8);

const kAccentBlue = Color(0xFF3B82F6);

// ============================================================
// DATA MODELS
// ============================================================

class BannerSummary {
  final String type;
  final int rank;
  final int count;
  final String label;
  final Color bgColor;
  final Color textColor;

  BannerSummary({
    required this.type,
    required this.rank,
    required this.count,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });
}

class BannerDetail {
  final String type;
  final String label;
  final String imageTitle;
  final String orgName;
  final String contestName;
  final double? score;
  final String date;
  final Color color;

  BannerDetail({
    required this.type,
    required this.label,
    required this.imageTitle,
    required this.orgName,
    required this.contestName,
    this.score,
    required this.date,
    required this.color,
  });
}

// ============================================================
// MAIN WIDGET
// ============================================================

class _ProfileBannersWidgetState extends State<ProfileBannersWidget> {
  final _supabase = Supabase.instance.client;

  List<BannerSummary> _bannerSummary = [];
  List<BannerDetail> _allBannerDetails = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  // ==========================================================
  // STYLES
  // ==========================================================

  Map<String, dynamic> _bannerStyle(String type) {
    switch (type) {
      case 'image_excellence':
        return {
          'label': 'Image Excellence',
          'bg': const Color(0xFFFFD700),
          'text': const Color(0xFF7A5800),
        };

      case 'superior':
        return {
          'label': 'Superior',
          'bg': const Color(0xFF8B5CF6),
          'text': Colors.white,
        };

      case 'excellent':
        return {
          'label': 'Excellent',
          'bg': const Color(0xFF0D9488),
          'text': Colors.white,
        };

      case 'deserving_merit':
        return {
          'label': 'Deserving Merit',
          'bg': const Color(0xFF7C3AED),
          'text': Colors.white,
        };

      case 'above_average':
        return {
          'label': 'Above Average',
          'bg': const Color(0xFF6B7280),
          'text': Colors.white,
        };

      default:
        return {
          'label': type,
          'bg': const Color(0xFF374151),
          'text': Colors.white,
        };
    }
  }

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> _loadBanners() async {
    setState(() => _loading = true);

    try {
      // STEP 1
      final myMedia = await _supabase
          .from('Media')
          .select('id')
          .eq('maker_id', widget.userId);

      final mediaIds =
          (myMedia as List).map((m) => m['id'].toString()).toList();

      if (mediaIds.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // STEP 2
      final banners = await _supabase
          .from('media_banners')
          .select('''
            banner_type,
            hierarchy_rank,
            score_at_award,
            awarded_date,
            media:Media(title),
            org:Organizations(name),
            entry:Contest_Entries(
              contest:Contests(name)
            )
          ''')
          .inFilter('media_id', mediaIds)
          .order('hierarchy_rank', ascending: true);

      final bannerList = banners as List;

      // STEP 3 SUMMARY
      final Map<String, int> countMap = {};
      final Map<String, int> rankMap = {};

      for (final b in bannerList) {
        final type = b['banner_type'] as String;

        countMap[type] = (countMap[type] ?? 0) + 1;
        rankMap[type] = b['hierarchy_rank'] as int;
      }

      final summary = countMap.entries.map((e) {
        final style = _bannerStyle(e.key);

        return BannerSummary(
          type: e.key,
          rank: rankMap[e.key] ?? 9,
          count: e.value,
          label: style['label'],
          bgColor: style['bg'],
          textColor: style['text'],
        );
      }).toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));

      // STEP 4 DETAILS
      final details = bannerList.map((b) {
        final style = _bannerStyle(b['banner_type']);

        final score = double.tryParse(
          b['score_at_award']?.toString() ?? '',
        );

        final date = b['awarded_date']?.toString() ?? '';

        final shortDate = date.length >= 10 ? date.substring(0, 10) : date;

        return BannerDetail(
          type: b['banner_type'],
          label: style['label'],
          imageTitle: b['media']?['title'] ?? 'Unknown',
          orgName: b['org']?['name'] ?? 'Unknown',
          contestName: b['entry']?['contest']?['name'] ?? 'Unknown',
          score: score,
          date: shortDate,
          color: style['bg'],
        );
      }).toList();

      setState(() {
        _bannerSummary = summary;
        _allBannerDetails = details;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Banner Load Error: $e');

      setState(() => _loading = false);
    }
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.military_tech_rounded,
                    color: kAccentBlue,
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'My Banners',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // SEE MORE
              if (_bannerSummary.isNotEmpty)
                GestureDetector(
                  onTap: _openAllBannersSheet,
                  child: const Text(
                    'See More',
                    style: TextStyle(
                      color: kAccentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // CONTENT
          _loading
              ? const Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      color: kAccentBlue,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : _bannerSummary.isEmpty
                  ? const Text(
                      'No banners earned yet.',
                      style: TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bannerSummary
                          .take(3)
                          .map((b) => _buildBannerChip(b))
                          .toList(),
                    ),
        ],
      ),
    );
  }

  // ==========================================================
  // CHIP
  // ==========================================================

  Widget _buildBannerChip(BannerSummary b) {
    return GestureDetector(
      onTap: () => _openBannerTypeDetail(b.type),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: b.bgColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: b.bgColor.withOpacity(0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.military_tech_rounded,
              color: b.bgColor,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              '${b.label} ×${b.count}',
              style: TextStyle(
                color: b.bgColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ALL BANNERS
  // ==========================================================

  void _openAllBannersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AllBannersSheet(
        summary: _bannerSummary,
        onBannerTypeTap: (type) {
          Navigator.pop(ctx);
          _openBannerTypeDetail(type);
        },
      ),
    );
  }

  // ==========================================================
  // DETAILS
  // ==========================================================

  void _openBannerTypeDetail(String type) {
    final filtered = _allBannerDetails.where((d) => d.type == type).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BannerDetailSheet(banners: filtered),
    );
  }
}

// ============================================================
// ALL BANNERS SHEET
// ============================================================

class _AllBannersSheet extends StatelessWidget {
  const _AllBannersSheet({
    required this.summary,
    required this.onBannerTypeTap,
  });

  final List<BannerSummary> summary;
  final ValueChanged<String> onBannerTypeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: kCardBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(
                  Icons.military_tech_rounded,
                  color: kAccentBlue,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'All My Banners',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: summary.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final b = summary[i];

                return GestureDetector(
                  onTap: () => onBannerTypeTap(b.type),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: b.bgColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: b.bgColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: b.bgColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.military_tech_rounded,
                            color: b.bgColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.label,
                                style: TextStyle(
                                  color: b.bgColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${b.count} time${b.count > 1 ? 's' : ''} earned',
                                style: const TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: b.bgColor.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ============================================================
// DETAIL SHEET
// ============================================================

class _BannerDetailSheet extends StatelessWidget {
  const _BannerDetailSheet({
    required this.banners,
  });

  final List<BannerDetail> banners;

  @override
  Widget build(BuildContext context) {
    final b = banners.first;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: kCardBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          const SizedBox(height: 16),

          // HEADER
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: b.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: b.color.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.military_tech_rounded,
                  color: b.color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.label,
                      style: TextStyle(
                        color: b.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${banners.length} time${banners.length > 1 ? 's' : ''} earned',
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: banners.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final d = banners[i];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kBgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kCardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IMAGE TITLE
                      Row(
                        children: [
                          const Icon(
                            Icons.image_rounded,
                            color: kAccentBlue,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              d.imageTitle,
                              style: const TextStyle(
                                color: kTextPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (d.score != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: d.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d.score!.toStringAsFixed(1),
                                style: TextStyle(
                                  color: d.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      _detailRow(
                        Icons.business_rounded,
                        d.orgName,
                        kTextSecondary,
                      ),

                      const SizedBox(height: 4),

                      _detailRow(
                        Icons.emoji_events_outlined,
                        d.contestName,
                        kTextSecondary,
                      ),

                      const SizedBox(height: 4),

                      if (d.date.isNotEmpty)
                        _detailRow(
                          Icons.calendar_today_rounded,
                          d.date,
                          kTextMuted,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
