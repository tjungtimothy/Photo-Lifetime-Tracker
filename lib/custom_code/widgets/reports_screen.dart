// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/widgets/index.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _status = 'All Status';
  String _category = 'All Category';
  String _judge = 'All Judge';
  String _dateRange = 'All Data Range';

  final List<String> _activeFilters = [
    'WINNERS',
    'HIGH SCORE (>8.0)',
    '2024 SEASON'
  ];

  final Map<String, String> _quickStats = {
    'Total Submissions': '1,294',
    'Avg. Score': '7.82',
    'Total Sales': '\$42,800',
  };

  Widget _buildFilterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: FlutterFlowTheme.of(context).primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          Icon(Icons.close_rounded,
              size: 12, color: FlutterFlowTheme.of(context).primary),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      String value, List<String> options, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF161B22),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withOpacity(0.4)),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (val) => onChanged(val ?? value),
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary.withOpacity(0.15)
                : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? FlutterFlowTheme.of(context).primary.withOpacity(0.5)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 22,
                  color: isSelected
                      ? FlutterFlowTheme.of(context).primary
                      : Colors.white.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text(title,
                  style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 10)),
              const SizedBox(height: 8),
              Text('>',
                  style: TextStyle(
                      color: isSelected
                          ? FlutterFlowTheme.of(context).primary
                          : Colors.white.withOpacity(0.3),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reports & Exports',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                'Generate comprehensive data exports and performance summaries.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 12)),
            const SizedBox(height: 20),

            // Query Builder
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list_rounded,
                          size: 16,
                          color: FlutterFlowTheme.of(context).primary),
                      const SizedBox(width: 6),
                      const Text('Query Builder',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Active filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ..._activeFilters.map(_buildFilterChip),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.5)),
                                const SizedBox(width: 4),
                                Text('ADD FILTER',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dropdowns
                  _buildLabel('Status'),
                  _buildDropdown(
                      _status,
                      ['All Status', 'Winner', 'Finalist', 'Submitted'],
                      (v) => setState(() => _status = v)),
                  const SizedBox(height: 10),
                  _buildLabel('Category'),
                  _buildDropdown(
                      _category,
                      ['All Category', 'Urban', 'Nature', 'Portrait'],
                      (v) => setState(() => _category = v)),
                  const SizedBox(height: 10),
                  _buildLabel('Judge'),
                  _buildDropdown(
                      _judge,
                      ['All Judge', 'Sarah Jenkins', 'John Smith'],
                      (v) => setState(() => _judge = v)),
                  const SizedBox(height: 10),
                  _buildLabel('Date Range'),
                  _buildDropdown(
                      _dateRange,
                      ['All Data Range', 'This Year', 'Last Year', 'Custom'],
                      (v) => setState(() => _dateRange = v)),
                  const SizedBox(height: 16),

                  // Process Export button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_file_rounded,
                          size: 16, color: Colors.white),
                      label: const Text('PROCESS EXPORT',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(context).primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Export Options
            const Text('Export Options',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildExportCard(
                  icon: Icons.picture_as_pdf_rounded,
                  title: 'Export PDF Report',
                  subtitle: 'High-res print ready document',
                  isSelected: true,
                ),
                const SizedBox(width: 10),
                _buildExportCard(
                  icon: Icons.table_chart_rounded,
                  title: 'Export CSV Data',
                  subtitle: 'Raw data for spreadsheet analysis',
                  isSelected: false,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Stats
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Stats',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ..._quickStats.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 13)),
                            Text(e.value,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
    );
  }
}
