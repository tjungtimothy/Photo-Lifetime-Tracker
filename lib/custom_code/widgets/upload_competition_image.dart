// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Imports custom functions

import '/custom_code/widgets/index.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:exif/exif.dart' as exifpkg;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const String kStorageBucket = 'media-vault';
const Color kAccent = Color(0xFF379DF0);

// ─── BETA / FEATURE FLAGS ────────────────────────────────────────────────────
/// Maximum photos a beta user can upload. Set to null to disable the limit.
const int? kBetaUploadLimit = 3;

const List<String> kDefaultCategories = [
  'Nature',
  'Landscape',
  'Portrait',
  'Wildlife',
  'Architecture',
  'Street',
  'Black & White',
  'Macro',
  'Abstract',
  'Photojournalism',
];

const List<String> kDefaultSubCategories = [
  'Color',
  'Black & White',
  'Conceptual',
  'Documentary',
  'Fine Art',
];

enum _UploadMode { community, competition }

class UploadCompetitionImage extends StatefulWidget {
  const UploadCompetitionImage({
    super.key,
    this.width,
    this.height,
    this.userId,
    this.userName,
    this.preselectedContestId,
    this.onSuccess,
  });

  final double? width;
  final double? height;
  final String? userId;
  final String? userName;
  final String? preselectedContestId;
  final Future<dynamic> Function()? onSuccess;

  @override
  State<UploadCompetitionImage> createState() => _UploadCompetitionImageState();
}

class _UploadCompetitionImageState extends State<UploadCompetitionImage> {
  static const _uuid = Uuid();

  _UploadMode _uploadMode = _UploadMode.community;

  // ─── FEATURE TOGGLES (Advanced / Future Premium) ─────────────────────────
  /// Show EXIF metadata panel. OFF by default — Advanced User toggle.
  bool _showExifData = false;

  /// Allow exporting / sharing metadata. OFF by default — Future Premium feature.
  bool _exportEnabled = false;

  // ─── USER UPLOAD COUNT (for beta limit) ──────────────────────────────────
  int _userUploadCount = 0;
  bool _uploadCountLoaded = false;

  // Contests
  final TextEditingController _contestSearchCtrl = TextEditingController();
  Timer? _contestSearchDebounce;
  List<Map<String, dynamic>> _contests = const [];
  Map<String, dynamic>? _selectedContest;
  bool _contestsLoading = false;
  String? _contestsError;

  // Categories
  final List<String> _categories = kDefaultCategories;
  final List<String> _subCategories = kDefaultSubCategories;
  String? _selectedCategory;
  String? _selectedSubCategory;

  // Image
  XFile? _pickedImage;
  Map<String, dynamic> _extractedMetadata = const {};
  Map<String, dynamic> _extractedProcessing = const {};
  DateTime? _extractedCaptureDate;
  bool _extracting = false;
  String? _extractError;

  // Form
  final TextEditingController _imageNameCtrl = TextEditingController();
  late final TextEditingController _makerCtrl =
      TextEditingController(text: widget.userName ?? '');

  // Submit
  bool _submitting = false;
  String? _submitError;
  String? _submitSuccess;

  @override
  void initState() {
    super.initState();
    _contestSearchCtrl.addListener(_onContestSearchChanged);
    _loadUserUploadCount();
  }

  @override
  void dispose() {
    _contestSearchCtrl
      ..removeListener(_onContestSearchChanged)
      ..dispose();
    _contestSearchDebounce?.cancel();
    _imageNameCtrl.dispose();
    _makerCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // BETA UPLOAD LIMIT
  // ═══════════════════════════════════════════════════════

  /// How many images has this user already uploaded?
  Future<void> _loadUserUploadCount() async {
    if (kBetaUploadLimit == null) {
      if (mounted) setState(() => _uploadCountLoaded = true);
      return;
    }
    try {
      final userId = widget.userId ?? SupaFlow.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _uploadCountLoaded = true);
        return;
      }
      final response = await SupaFlow.client
          .from('Media')
          .select('id')
          .eq('maker_id', userId);
      if (!mounted) return;
      setState(() {
        _userUploadCount = (response as List).length;
        _uploadCountLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _uploadCountLoaded = true);
    }
  }

  bool get _betaLimitReached =>
      kBetaUploadLimit != null && _userUploadCount >= kBetaUploadLimit!;

  int get _betaSlotsLeft => kBetaUploadLimit != null
      ? (kBetaUploadLimit! - _userUploadCount).clamp(0, kBetaUploadLimit!)
      : 999;

  // ═══════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════

  String? _exifString(Map<String, exifpkg.IfdTag> tags, String key) {
    final v = tags[key];
    if (v == null) return null;
    final s = v.printable.toString().trim();
    return s.isEmpty ? null : s;
  }

  String _cleanAperture(String raw) {
    final f = double.tryParse(raw.trim());
    if (f != null) {
      return f.toStringAsFixed(f.truncateToDouble() == f ? 0 : 1);
    }
    return raw.trim();
  }

  String _cleanFocalLength(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d./]'), '').trim();
    if (cleaned.contains('/')) {
      final parts = cleaned.split('/');
      if (parts.length == 2) {
        final num = double.tryParse(parts[0].trim());
        final den = double.tryParse(parts[1].trim());
        if (num != null && den != null && den != 0) {
          final v = num / den;
          return v.toStringAsFixed(1);
        }
      }
    }
    final f = double.tryParse(cleaned);
    if (f != null) return f.toStringAsFixed(1);
    return raw.trim();
  }

  String _buildExposure({String? shutter, String? aperture}) {
    final parts = <String>[];
    final sh = (shutter ?? '').trim();
    if (sh.isNotEmpty) parts.add(sh);
    final ap = (aperture ?? '').trim();
    if (ap.isNotEmpty) parts.add('at ${_cleanAperture(ap)}');
    return parts.join(' ');
  }

  DateTime? _parseExifDate(String raw) {
    final s = raw.trim();
    if (s.contains(' ')) {
      final parts = s.split(' ');
      final datePart = parts[0].replaceFirst(':', '-').replaceFirst(':', '-');
      final timePart = parts.length > 1 ? parts[1] : '';
      final normalized = '${datePart}T$timePart';
      return DateTime.tryParse(normalized);
    }
    return DateTime.tryParse(s);
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}…' : s;

  // ═══════════════════════════════════════════════════════
  // CONTESTS
  // ═══════════════════════════════════════════════════════

  void _onContestSearchChanged() {
    _contestSearchDebounce?.cancel();
    _contestSearchDebounce = Timer(const Duration(milliseconds: 250), () async {
      await _loadContests();
    });
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  bool _isContestExpired(Map<String, dynamic> contest) {
    final end = _parseDate(contest['submittal_end_date']);
    if (end == null) return false;
    return end.isBefore(DateTime.now());
  }

  Future<void> _loadContests() async {
    if (!mounted) return;
    setState(() {
      _contestsLoading = true;
      _contestsError = null;
    });
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final q = _contestSearchCtrl.text.trim();

      var query = SupaFlow.client
          .from('Contests')
          .select('id, name, organization_id, submittal_start_date, '
              'submittal_end_date, judging_date, rules, entry_fee, created_at, '
              'Organizations(name, full_name)')
          .or('submittal_end_date.is.null,submittal_end_date.gte.$today');

      if (q.isNotEmpty) {
        query = query.ilike('name', '%$q%');
      }

      final response =
          await query.order('created_at', ascending: false).limit(50);

      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(response as List);

      Map<String, dynamic>? toSelect;
      if (widget.preselectedContestId != null) {
        try {
          toSelect =
              list.firstWhere((c) => c['id'] == widget.preselectedContestId);
        } catch (_) {}
      }
      if (toSelect == null && _selectedContest != null) {
        final currentId = _selectedContest!['id']?.toString();
        try {
          toSelect = list.firstWhere((c) => c['id']?.toString() == currentId);
        } catch (_) {}
      }

      setState(() {
        _contests = list;
        _selectedContest = toSelect;
        _contestsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contestsError = e.toString();
        _contestsLoading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════
  // IMAGE PICKING
  // ═══════════════════════════════════════════════════════

  Future<void> _pickImageWithFullMetadata() async {
    if (_betaLimitReached) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'heic'],
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.single.path == null) return;

      final pickedPath = result.files.single.path!;

      final tempDir = await getTemporaryDirectory();
      final fileName = p.basename(pickedPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/${timestamp}_$fileName';

      await File(pickedPath).copy(tempPath);

      final xfile = XFile(tempPath);

      if (!mounted) return;

      final originalName = p.basenameWithoutExtension(fileName);
      final looksLikeUuid = RegExp(
        r'^[A-F0-9_\-]{20,}$',
        caseSensitive: false,
      ).hasMatch(originalName);

      setState(() {
        _pickedImage = xfile;
        _extracting = true;
        _extractError = null;
        _extractedMetadata = const {};
        _extractedProcessing = const {};
        _extractedCaptureDate = null;

        if (_imageNameCtrl.text.trim().isEmpty && !looksLikeUuid) {
          _imageNameCtrl.text = originalName;
        }
      });

      await _extractExifData(xfile);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _extracting = false;
        _extractError = 'Failed to pick: $e';
      });
      debugPrint('Image pick error: $e');
    }
  }

  // ── Camera picker — safe version for real devices ──────────────────────
  // Key fixes vs gallery picker:
  //   1. requestFullMetadata: FALSE  → avoids iOS photo-library permission crash
  //   2. imageQuality: 92            → avoids OOM on low-RAM devices
  //   3. Copies result to temp dir   → guarantees stable path before processing
  //   4. Wraps everything in try/catch with user-visible error instead of crash
  Future<void> _pickFromCamera() async {
    if (_betaLimitReached) return;

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        requestFullMetadata:
            false, // ← must be false for camera; true crashes on iOS
      );
    } catch (e) {
      // Camera unavailable, permission denied, or hardware error
      if (!mounted) return;
      setState(() {
        _extracting = false;
        _submitError = 'Camera unavailable: ${e.toString().split('\n').first}';
      });
      return;
    }

    if (picked == null) return; // user cancelled
    if (!mounted) return;

    // Verify the path actually exists before touching it
    final srcFile = File(picked.path);
    if (!srcFile.existsSync()) {
      if (!mounted) return;
      setState(() => _submitError = 'Camera returned an invalid file path.');
      return;
    }

    try {
      // Copy to our own temp location so the OS temp-camera file isn't deleted under us
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(picked.path).toLowerCase().isEmpty
          ? '.jpg'
          : p.extension(picked.path).toLowerCase();
      final tempPath = '${tempDir.path}/${timestamp}_camera$ext';
      await srcFile.copy(tempPath);

      final safeFile = XFile(tempPath);
      const autoName = 'Camera Photo';

      if (!mounted) return;
      setState(() {
        _pickedImage = safeFile;
        _extracting = true;
        _extractError = null;
        _submitError = null;
        _extractedMetadata = const {};
        _extractedProcessing = const {};
        _extractedCaptureDate = null;
        if (_imageNameCtrl.text.trim().isEmpty) {
          _imageNameCtrl.text = autoName;
        }
      });

      await _extractExifData(safeFile);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _extracting = false;
        _extractError = 'Could not process camera image: $e';
      });
      debugPrint('Camera processing error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // EXIF + XMP EXTRACTION
  // ═══════════════════════════════════════════════════════

  Future<void> _extractExifData(XFile file) async {
    try {
      final bytes = await File(file.path).readAsBytes();
      final tags = await exifpkg.readExifFromBytes(bytes);

      String historyWhen = '';
      String historyAgent = '';

      final xmpData = await _extractXmpFromJpeg(bytes);
      if (xmpData != null) {
        historyWhen = xmpData['when'] ?? '';
        historyAgent = xmpData['agent'] ?? '';
      }

      if (historyAgent.isEmpty) {
        historyAgent = _exifString(tags, 'Image Software') ?? '';
      }

      final camMake = (_exifString(tags, 'Image Make') ?? '').trim();
      final camModel = (_exifString(tags, 'Image Model') ?? '').trim();
      final camera =
          [camMake, camModel].where((s) => s.isNotEmpty).join(' ').trim();

      final rawIso = (_exifString(tags, 'EXIF ISOSpeedRatings') ??
              _exifString(tags, 'EXIF PhotographicSensitivity') ??
              '')
          .replaceAll(RegExp(r'[\[\]]'), '')
          .trim();

      final exposure = _buildExposure(
        shutter: _exifString(tags, 'EXIF ExposureTime'),
        aperture: _exifString(tags, 'EXIF FNumber'),
      );

      final focalLength = (_exifString(tags, 'EXIF FocalLength') ?? '').trim();
      final software = (_exifString(tags, 'Image Software') ?? '').trim();

      DateTime? captureDate;
      final dateStr = (_exifString(tags, 'EXIF DateTimeOriginal') ??
              _exifString(tags, 'Image DateTime') ??
              '')
          .trim();
      if (dateStr.isNotEmpty) {
        captureDate = _parseExifDate(dateStr);
      }

      final metadata = <String, dynamic>{
        'iso': rawIso,
        'camera': camera,
        'exposure': exposure,
        'focal_length':
            focalLength.isEmpty ? '' : '${_cleanFocalLength(focalLength)} mm',
      };

      final processing = <String, dynamic>{
        'software': software,
        'history_when': historyWhen,
        'history_agent': historyAgent,
      };

      if (!mounted) return;

      setState(() {
        _extractedMetadata = metadata;
        _extractedProcessing = processing;
        _extractedCaptureDate = captureDate;
        _extracting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _extracting = false;
        _extractError = 'EXIF extraction failed: $e';
      });
    }
  }

  Future<Map<String, String>?> _extractXmpFromJpeg(Uint8List bytes) async {
    try {
      if (bytes.length < 2 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
        return null;
      }

      int offset = 2;

      while (offset < bytes.length - 1) {
        if (bytes[offset] != 0xFF) {
          offset++;
          continue;
        }

        final marker = bytes[offset + 1];
        offset += 2;

        if (marker == 0xD8 ||
            marker == 0xD9 ||
            marker == 0x01 ||
            (marker >= 0xD0 && marker <= 0xD7)) {
          continue;
        }

        if (offset + 2 > bytes.length) break;
        final length = (bytes[offset] << 8) | bytes[offset + 1];
        offset += 2;

        if (marker == 0xE1) {
          if (offset + length - 2 > bytes.length) break;

          final segmentData = bytes.sublist(offset, offset + length - 2);
          final xmpId = 'http://ns.adobe.com/xap/1.0/\x00';
          final xmpIdBytes = xmpId.codeUnits;

          if (segmentData.length > xmpIdBytes.length) {
            bool isXmp = true;
            for (int i = 0; i < xmpIdBytes.length; i++) {
              if (segmentData[i] != xmpIdBytes[i]) {
                isXmp = false;
                break;
              }
            }

            if (isXmp) {
              final xmpBytes = segmentData.sublist(xmpIdBytes.length);
              final xmpString = String.fromCharCodes(xmpBytes);
              return _parseXmpString(xmpString);
            }
          }
        }

        offset += length - 2;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Map<String, String> _parseXmpString(String xmp) {
    try {
      final whenMatches = RegExp(r'stEvt:when="([^"]+)"').allMatches(xmp);
      final whenValues = whenMatches
          .map((m) => m.group(1) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      final agentMatches =
          RegExp(r'stEvt:softwareAgent="([^"]+)"').allMatches(xmp);
      final agentValues = agentMatches
          .map((m) => m.group(1) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      return {
        'when': whenValues.isNotEmpty ? whenValues.join(', ') : '',
        'agent': agentValues.isNotEmpty ? agentValues.join(', ') : '',
      };
    } catch (e) {
      return {'when': '', 'agent': ''};
    }
  }

  // ═══════════════════════════════════════════════════════
  // SUBMIT
  // ═══════════════════════════════════════════════════════

  void _setSubmitError(String msg) {
    setState(() {
      _submitError = msg;
      _submitSuccess = null;
    });
  }

  String _timetzNowUtc() {
    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now().toUtc();
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}+00';
  }

  Future<void> _submit() async {
    if (_pickedImage == null) {
      return _setSubmitError('Please pick an image first');
    }

    // ── Beta upload limit check ──────────────────────────
    if (_betaLimitReached) {
      return _setSubmitError(
          'Beta limit reached: you can upload up to $kBetaUploadLimit images during the test period.');
    }

    if (_uploadMode == _UploadMode.competition) {
      if (_selectedContest == null) {
        return _setSubmitError('Please select a contest');
      }
      if (_isContestExpired(_selectedContest!)) {
        return _setSubmitError(
            'This contest has expired. Please choose an active contest.');
      }
    }

    if (_imageNameCtrl.text.trim().isEmpty) {
      return _setSubmitError('Image name is required');
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      return _setSubmitError('Category is required');
    }

    final userId = widget.userId ?? SupaFlow.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return _setSubmitError('User not found (not logged in).');
    }

    setState(() {
      _submitting = true;
      _submitError = null;
      _submitSuccess = null;
    });

    try {
      final file = File(_pickedImage!.path);
      final bytes = await file.readAsBytes();
      final ext = p.extension(_pickedImage!.path).toLowerCase();
      final baseName = p
          .basenameWithoutExtension(_pickedImage!.name)
          .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rand = math.Random().nextInt(999999);

      final storagePath =
          'private/$userId/image/${timestamp}_${rand}_$baseName$ext';

      final contentType =
          lookupMimeType(_pickedImage!.name, headerBytes: bytes) ??
              'image/jpeg';

      await SupaFlow.client.storage.from(kStorageBucket).upload(
            storagePath,
            file,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      final publicUrl = SupaFlow.client.storage
          .from(kStorageBucket)
          .getPublicUrl(storagePath);

      final mediaId = _uuid.v4();
      final cleanTitle = _imageNameCtrl.text.trim();

      // Only save EXIF/processing data if user has toggled it ON
      await SupaFlow.client.from('Media').insert({
        'id': mediaId,
        'title': cleanTitle,
        'original_filename': p.basename(_pickedImage!.name),
        'type': 'photo',
        'category': _selectedCategory,
        'sub_category': _selectedSubCategory,
        'file_path': publicUrl,
        'photo_address': storagePath,
        'capture_date':
            _showExifData ? _extractedCaptureDate?.toIso8601String() : null,
        'import_date': DateTime.now().toIso8601String(),
        'Metadata': _showExifData ? _extractedMetadata : null,
        'processing_data': _showExifData ? _extractedProcessing : null,
        'current_status': 'processed',
        'average_score': 0,
        'highest_score': 0,
        'maker_id': userId,
      });

      if (_uploadMode == _UploadMode.competition) {
        await SupaFlow.client.from('Contest_Entries').insert({
          'media_id': mediaId,
          'contest_id': _selectedContest!['id'],
          'entry_date': _timetzNowUtc(),
          'status': 'submitted',
        });
      }

      if (!mounted) return;
      final modeLabel = _uploadMode == _UploadMode.community
          ? 'shared in community'
          : 'entered in "${_selectedContest!['name']}"';

      // Increment local count after successful upload
      setState(() {
        _submitting = false;
        _submitSuccess = '✅ "$cleanTitle" $modeLabel!';
        _userUploadCount++;
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        context.goNamed('HomePage');
      }

      if (!mounted) return;
      setState(() {
        _pickedImage = null;
        _imageNameCtrl.clear();
        _selectedCategory = null;
        _selectedSubCategory = null;
        _selectedContest = null;
        _extractedMetadata = const {};
        _extractedProcessing = const {};
        _extractedCaptureDate = null;
        _extracting = false;
        _extractError = null;
        _submitError = null;
        _submitSuccess = null;
      });
    } catch (e) {
      if (!mounted) return;
      final details = e is PostgrestException
          ? '(${e.code ?? ''}) ${e.message} ${e.details ?? ''}'
          : e.toString();
      setState(() {
        _submitting = false;
        _submitError = 'Upload failed: $details';
        _submitSuccess = null;
      });
    }
  }

  // ══════════════════════════════════════════════════════
  // BUILD UI
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFF0A0C0F),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final maxContentWidth = isWide ? 720.0 : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Beta Upload Limit Banner ─────────────────────
                    if (kBetaUploadLimit != null && _uploadCountLoaded)
                      _buildBetaLimitBanner(),

                    _buildModeToggle(),
                    const SizedBox(height: 16),

                    // ── Advanced Feature Toggles Panel ───────────────
                    _buildFeatureTogglesPanel(),
                    const SizedBox(height: 16),

                    if (_uploadMode == _UploadMode.competition) ...[
                      _buildContestSection(),
                      const SizedBox(height: 16),
                    ],

                    // ── Image Picker (disabled when limit reached) ───
                    if (_betaLimitReached)
                      _buildLimitReachedBlock()
                    else
                      _buildImagePickerSection(),

                    const SizedBox(height: 16),
                    if (_pickedImage != null) ...[
                      // Only show EXIF section if toggle is ON
                      if (_showExifData) ...[
                        _buildExtractedDataSection(),
                        const SizedBox(height: 16),
                      ],
                      _buildFormFields(),
                      const SizedBox(height: 16),
                      _buildSubmitButton(),
                    ],
                    if (_submitError != null)
                      _buildBanner(_submitError!, isError: true),
                    if (_submitSuccess != null)
                      _buildBanner(_submitSuccess!, isError: false),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Beta limit banner at top ────────────────────────────────────────────
  Widget _buildBetaLimitBanner() {
    final reached = _betaLimitReached;
    final color = reached ? Colors.orange : kAccent;
    final icon = reached ? Icons.lock_rounded : Icons.info_outline_rounded;
    final msg = reached
        ? 'Beta limit reached: $kBetaUploadLimit/$kBetaUploadLimit images uploaded.'
        : 'Beta: $_betaSlotsLeft of $kBetaUploadLimit upload slot${_betaSlotsLeft == 1 ? '' : 's'} remaining.';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ─── Block shown in place of picker when limit reached ───────────────────
  Widget _buildLimitReachedBlock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_rounded, color: Colors.orangeAccent, size: 36),
          const SizedBox(height: 10),
          const Text(
            'Upload Limit Reached',
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'You have used all $kBetaUploadLimit beta upload slots.\nContact us to upgrade or get more slots.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── Advanced Feature Toggles Panel ─────────────────────────────────────
  Widget _buildFeatureTogglesPanel() {
    return Container(
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
              const Icon(Icons.tune_rounded, color: kAccent, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Advanced Settings',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: const Text(
                  'Optional',
                  style: TextStyle(color: Colors.amber, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── EXIF Data Toggle ────────────────────────────────────────
          _buildToggleRow(
            icon: Icons.camera_rounded,
            title: 'Show EXIF / Camera Data',
            subtitle:
                'Display ISO, exposure, focal length & edit history. Great for pro photographers.',
            value: _showExifData,
            onChanged: (v) => setState(() => _showExifData = v),
            badge: null,
          ),

          const Divider(color: Colors.white10, height: 20),

          // ── Export Toggle ───────────────────────────────────────────
          _buildToggleRow(
            icon: Icons.ios_share_rounded,
            title: 'Enable Metadata Export',
            subtitle: 'Export image metadata as CSV / JSON. Coming soon.',
            value: _exportEnabled,
            onChanged: (v) => setState(() => _exportEnabled = v),
            badge: 'Premium',
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String? badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon,
              size: 15, color: Colors.white.withOpacity(value ? 0.85 : 0.35)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(value ? 1.0 : 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.5)),
                      ),
                      child: const Text(
                        '★ Premium',
                        style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kAccent,
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // All existing UI widgets below — unchanged
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildModeToggle() {
    final isCommunity = _uploadMode == _UploadMode.community;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _modeBtn(
            icon: Icons.people_alt_rounded,
            label: 'Share in Community',
            selected: isCommunity,
            onTap: () {
              setState(() {
                _uploadMode = _UploadMode.community;
                _submitError = null;
              });
            },
          ),
          _modeBtn(
            icon: Icons.emoji_events_rounded,
            label: 'Enter Competition',
            selected: !isCommunity,
            onTap: () {
              setState(() {
                _uploadMode = _UploadMode.competition;
                _submitError = null;
              });
              if (_contests.isEmpty) {
                _loadContests();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _modeBtn({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color:
                      selected ? Colors.white : Colors.white.withOpacity(0.4)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        selected ? Colors.white : Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContestSection() {
    final expired =
        _selectedContest != null && _isContestExpired(_selectedContest!);
    return Container(
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
              const Icon(Icons.emoji_events_rounded, color: kAccent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Select Competition',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_contestsLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: kAccent),
                ),
              if (expired) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Contest Closed',
                    style: TextStyle(color: Colors.redAccent, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Search and select an active competition to enter.',
            style:
                TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contestSearchCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search contests...',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: kAccent),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                borderSide: const BorderSide(color: kAccent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_contestsError != null)
            Text(
              'Error: $_contestsError',
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            )
          else if (_contests.isEmpty && !_contestsLoading)
            Text(
              'No active contests available',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            )
          else if (_contests.isNotEmpty)
            _buildContestDropdown(),
          if (_selectedContest != null && expired) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This contest has already closed. Please choose an active one to proceed.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedContest != null && !expired) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),
            _buildContestDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildContestDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kAccent.withOpacity(0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedContest?['id']?.toString(),
          hint: Text(
            'Choose a contest',
            style:
                TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
          ),
          dropdownColor: const Color(0xFF161B22),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: kAccent, size: 22),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: _contests.map((c) {
            final orgName = (c['Organizations']?['name'] ?? '').toString();
            final isExpired = _isContestExpired(c);
            return DropdownMenuItem<String>(
              value: c['id'].toString(),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      orgName.isNotEmpty
                          ? '${c['name']} · $orgName'
                          : (c['name'] ?? 'Untitled').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isExpired
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white,
                          fontSize: 13),
                    ),
                  ),
                  if (isExpired) ...[
                    const SizedBox(width: 8),
                    const Text('Closed',
                        style:
                            TextStyle(color: Colors.redAccent, fontSize: 11)),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id == null) return;
            setState(() {
              _selectedContest =
                  _contests.firstWhere((c) => c['id'].toString() == id);
              _submitError = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildContestDetails() {
    final c = _selectedContest!;
    final startDate = c['submittal_start_date']?.toString();
    final endDate = c['submittal_end_date']?.toString();
    final judgeDate = c['judging_date']?.toString();
    final rules = c['rules']?.toString() ?? '';
    final entryFee = c['entry_fee'];

    String scoringFormat = 'Standard';
    final lc = ('${c['name'] ?? ''} $rules').toLowerCase();
    if (lc.contains('mir') || lc.contains('merit image review')) {
      scoringFormat = 'MIR (PPA) — Merit/IE/Potential';
    } else if (lc.contains('asp')) {
      scoringFormat = 'Numeric (1-100)';
    }

    String? dateOnly(String? iso) =>
        (iso != null && iso.length >= 10) ? iso.substring(0, 10) : null;

    return Column(
      children: [
        _detailRow('Start Date', dateOnly(startDate) ?? 'Not set'),
        _detailRow('Deadline', dateOnly(endDate) ?? 'Not set',
            highlight: endDate != null),
        _detailRow('Judging Date', dateOnly(judgeDate) ?? 'TBD'),
        _detailRow('Scoring Format', scoringFormat),
        if (entryFee != null)
          _detailRow('Entry Fee', '\$${entryFee.toString()}'),
      ],
    );
  }

  Widget _detailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlight ? kAccent : Colors.white,
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _pickedImage != null
              ? kAccent.withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: _pickedImage == null ? _buildPickerEmpty() : _buildPickerPreview(),
    );
  }

  Widget _buildPickerEmpty() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.add_photo_alternate_rounded,
              size: 40, color: Colors.white.withOpacity(0.4)),
          const SizedBox(height: 8),
          const Text(
            'Pick an image to upload',
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Your personal mobile showcase\nSimple, fast & beautiful',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pickBtn(Icons.upload_rounded, 'Upload Image',
                  _pickImageWithFullMetadata),
              const SizedBox(width: 10),
              _pickBtn(Icons.camera_alt_rounded, 'Camera', _pickFromCamera),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pickBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kAccent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kAccent, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  color: kAccent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerPreview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Stack(
            children: [
              Image.file(
                File(_pickedImage!.path),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 220,
                    color: const Color(0xFF1E2430),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded,
                            size: 40, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 8),
                        Text(
                          'Preview unavailable',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _pickedImage = null;
                    _extractedMetadata = const {};
                    _extractedProcessing = const {};
                    _extractedCaptureDate = null;
                    _extractError = null;
                    _extracting = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.greenAccent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _pickedImage!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: _pickImageWithFullMetadata,
                child: const Text('Change',
                    style: TextStyle(color: kAccent, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtractedDataSection() {
    if (_extracting) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: kAccent),
            ),
            SizedBox(width: 10),
            Text('Extracting EXIF metadata…',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: kAccent, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Auto-extracted EXIF',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_extractError != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Partial',
                      style:
                          TextStyle(color: Colors.orangeAccent, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _exifChip(
                  'Camera',
                  _truncate(
                      (_extractedMetadata['camera'] ?? '—').toString(), 14)),
              _exifChip('ISO', (_extractedMetadata['iso'] ?? '—').toString()),
              _exifChip('Exposure',
                  (_extractedMetadata['exposure'] ?? '—').toString()),
              _exifChip('Focal',
                  (_extractedMetadata['focal_length'] ?? '—').toString()),
            ],
          ),
          if (_extractedCaptureDate != null) ...[
            const SizedBox(height: 10),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12, color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 6),
                Text(
                  'Captured: ${_extractedCaptureDate!.toIso8601String().substring(0, 10)}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ),
          ],
          if ((_extractedProcessing['software'] ?? '')
              .toString()
              .isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.build_rounded,
                    size: 12, color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Software: ${_truncate((_extractedProcessing['software'] ?? '').toString(), 40)}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
          if ((_extractedProcessing['history_when'] ?? '')
              .toString()
              .isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 12, color: Colors.greenAccent.withOpacity(0.7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'History: ${_truncate((_extractedProcessing['history_when'] ?? '').toString(), 40)}',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
          if (_extractError != null) ...[
            const SizedBox(height: 6),
            Text(
              _extractError!,
              style: TextStyle(
                  color: Colors.orangeAccent.withOpacity(0.7), fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _exifChip(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Image Details',
            style: TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _textField(
              label: 'Image Name *',
              controller: _imageNameCtrl,
              hint: 'e.g. Tendrils of Time'),
          const SizedBox(height: 10),
          _textField(
              label: 'Maker / Photographer',
              controller: _makerCtrl,
              hint: 'Photographer name'),
          const SizedBox(height: 10),
          _dropdownField(
            label: 'Category *',
            value: _selectedCategory,
            items: _categories,
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 10),
          _dropdownField(
            label: 'Sub-category',
            value: _selectedSubCategory,
            items: _subCategories,
            onChanged: (v) => setState(() => _selectedSubCategory = v),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              borderSide: const BorderSide(color: kAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text('Select...',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.25), fontSize: 13)),
              dropdownColor: const Color(0xFF161B22),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: kAccent, size: 20),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: kAccent.withOpacity(0.4),
        ),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                _uploadMode == _UploadMode.community
                    ? 'Share in Community'
                    : 'Submit to Competition',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildBanner(String msg, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? Colors.red : Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: (isError ? Colors.red : Colors.green).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: isError ? Colors.redAccent : Colors.greenAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: isError ? Colors.redAccent : Colors.greenAccent,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
