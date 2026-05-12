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

class UploadScreen extends StatefulWidget {
  const UploadScreen({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _showForm = false;
  bool _csvUploaded = false;
  String _csvFileName = 'Competition_data_v2.csv';

  // Form controllers
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  String _selectedCategory = 'Urban';

  final List<String> _categories = [
    'Urban',
    'Nature',
    'Portrait',
    'Street',
    'Landscape',
    'Wildlife',
    'Abstract'
  ];

  // Mock imported items
  final List<Map<String, dynamic>> _importedItems = [
    {
      'title': 'Urban Decay',
      'author': 'Marcus Thorne',
      'category': 'Street',
      'status': 'success',
      'mapping': 'Title',
    },
    {
      'title': 'Mountain Echo',
      'author': 'Julian Frost',
      'category': 'Nature',
      'status': 'error',
      'error': 'Missing Category ID',
      'mapping': 'Title',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Widget _buildDashedBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.02),
        ),
        child: Column(
          children: [
            Icon(icon, color: FlutterFlowTheme.of(context).primary, size: 28),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildManualForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Photo Entry',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Photo Title
          _buildLabel('Photo Title'),
          _buildTextField(_titleController, 'e.g. Noon Silence'),
          const SizedBox(height: 12),

          // Author Name
          _buildLabel('Author Name'),
          _buildTextField(_authorController, 'e.g. Elena Vance'),
          const SizedBox(height: 12),

          // Category dropdown
          _buildLabel('Category'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: const Color(0xFF161B22),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withOpacity(0.5)),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedCategory = val ?? 'Urban'),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Image selector
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withOpacity(0.02),
              ),
              child: Column(
                children: [
                  Icon(Icons.upload_rounded,
                      color: FlutterFlowTheme.of(context).primary, size: 28),
                  const SizedBox(height: 8),
                  Text('Select Image File',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('SAVE ENTRY',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 10),

          // Cancel
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => setState(() => _showForm = false),
              child: Text('CANCEL',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      letterSpacing: 1)),
            ),
          ),
        ],
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

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0D1117),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildImportedItem(Map<String, dynamic> item) {
    final isError = item['status'] == 'error';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? Colors.redAccent.withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mapping row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mapping',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 11)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Text(item['mapping'],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 14, color: Colors.white.withOpacity(0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title row
          Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                size: 14,
                color: isError ? Colors.redAccent : Colors.greenAccent,
              ),
              const SizedBox(width: 6),
              if (isError)
                Text('Error  ',
                    style: TextStyle(
                        color: Colors.redAccent.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              Text(item['title'],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Author  ${item['author']}  |  Category  ${item['category']}',
            style:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
          ),

          // Error message
          if (isError) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(item['error'],
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 11)),
            ),
          ],
        ],
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
            // Header
            const Text('Data Entry',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Upload individual photos or bulk import via CSV.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 12)),
            const SizedBox(height: 20),

            // Manual Entry toggle button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _showForm = !_showForm),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: FlutterFlowTheme.of(context).primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _showForm ? 'CLOSE FORM' : 'MANUAL ENTRY',
                  style: TextStyle(
                      color: FlutterFlowTheme.of(context).primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Manual form
            if (_showForm) ...[
              _buildManualForm(),
              const SizedBox(height: 16),
            ],

            if (!_showForm) ...[
              // Upload Photo box
              _buildDashedBox(
                icon: Icons.upload_rounded,
                title: 'Upload Photo',
                subtitle: 'Drag & drop images or click to browse.',
                onTap: () {},
              ),
              const SizedBox(height: 12),

              // Import CSV box
              _buildDashedBox(
                icon: Icons.insert_drive_file_outlined,
                title: 'Import CSV',
                subtitle: 'Drag & drop images or click to browse.',
                onTap: () => setState(() => _csvUploaded = true),
              ),
              const SizedBox(height: 16),

              // CSV file + process button
              if (_csvUploaded) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file_outlined,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 18),
                      const SizedBox(width: 10),
                      Text(_csvFileName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('PROCESS IMPORT',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 16),

                // Imported items
                ..._importedItems.map(_buildImportedItem),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
