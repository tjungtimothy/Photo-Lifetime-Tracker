// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════════════════════════
// THEME — Figma colors
// ═══════════════════════════════════════════════════════════════════════════
const Color kBgDark = Color(0xFF0E1116);
const Color kCardBg = Color(0xFF161B22);
const Color kCardBorder = Color(0xFF22272F);
const Color kAccentBlue = Color(0xFF379DF0);
const Color kRedAccent = Color(0xFFE05A5A);
const Color kTextPrimary = Color(0xFFE6EDF3);
const Color kTextSecondary = Color(0xFF8B949E);
const Color kTextMuted = Color(0xFF6E7681);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _uploadingImage = false;
  // ★ FIX: track if sign-out flow has started so build() can short-circuit
  //   to a safe loading state instead of trying to render with no session.
  bool _signingOut = false;
  Timer? _settingsHighlightTimer;

  // User fields — exact column names from Users table
  String? _userId;
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String? _profileImgUrl;
  String? _currentImgUrl;
  List<String> _profileImageHistory = [];

  // Stats
  int _totalSubmissions = 0;
  double _avgScore = 0.0;

  // Settings selection
  String? _highlightedSetting; // transient highlight on tap

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _settingsHighlightTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD PROFILE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }
      _userId = user.id;

      // 1. Users table
      final userRow = await _selectUserRow(_userId!);

      if (userRow != null) {
        _firstName = userRow['first_name'] ?? '';
        _lastName = userRow['last_name'] ?? '';
        _email = userRow['email'] ?? user.email ?? '';
        _currentImgUrl = (userRow['profile_img_url'])?.toString();
        _profileImgUrl = _currentImgUrl;
        _profileImageHistory =
            _parseProfileImages(userRow['all_profile_images']);
      }

      // 2. Media owned by user (ids + scores)
      final myMedia = await _supabase
          .from('Media')
          .select('id, average_score, highest_score')
          .eq('maker_id', _userId!);

      final myMediaList = (myMedia as List);
      final mediaIds =
          myMediaList.map((m) => m['id']).whereType<String>().toList();

      // Avg score = avg(Media.average_score) for my uploads
      double totalScore = 0;
      int scoreCount = 0;
      for (final m in myMediaList) {
        final val = double.tryParse(
          (m['average_score'] ?? m['highest_score'])?.toString() ?? '',
        );
        if (val != null) {
          totalScore += val;
          scoreCount++;
        }
      }
      _avgScore = scoreCount > 0 ? totalScore / scoreCount : 0.0;

      // 3. Submissions = count(Contest_Entries where media_id in my uploads)
      if (mediaIds.isNotEmpty) {
        final entries = await _supabase
            .from('Contest_Entries')
            .select('id')
            .inFilter('media_id', mediaIds);
        _totalSubmissions = (entries as List).length;
      } else {
        _totalSubmissions = 0;
      }
    } catch (e) {
      debugPrint('ProfileScreen load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER ROW (supports old/new columns)
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _selectUserRow(String userId) async {
    try {
      return await _supabase
          .from('Users')
          .select(
            'first_name, last_name, email, profile_img_url, all_profile_images',
          )
          .eq('id', userId)
          .maybeSingle();
    } catch (_) {
      return await _supabase
          .from('Users')
          .select('first_name, last_name, email, profile_img_url')
          .eq('id', userId)
          .maybeSingle();
    }
  }

  List<String> _parseProfileImages(dynamic raw) {
    if (raw == null) return <String>[];
    if (raw is List) {
      return raw.whereType<String>().where((e) => e.trim().isNotEmpty).toList();
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return <String>[];
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded
              .whereType<String>()
              .where((e) => e.trim().isNotEmpty)
              .toList();
        }
      } catch (_) {}
      return <String>[];
    }
    return <String>[];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SETTINGS HIGHLIGHT (tap only)
  // ─────────────────────────────────────────────────────────────────────────
  void _flashSettingHighlight(String key) {
    _settingsHighlightTimer?.cancel();
    setState(() => _highlightedSetting = key);
    _settingsHighlightTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _highlightedSetting = null);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROFILE IMAGE PICKER SHEET
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _openProfileImageSheet() async {
    if (_userId == null) return;
    try {
      final userRow = await _selectUserRow(_userId!);
      if (userRow != null && mounted) {
        setState(() {
          _currentImgUrl =
              (userRow['current_img_url'] ?? userRow['profile_img_url'])
                  ?.toString();
          _profileImgUrl = _currentImgUrl;
          _profileImageHistory =
              _parseProfileImages(userRow['all_profile_images']);
        });
      }
    } catch (_) {}
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ProfileImageSheet(
        currentUrl: _profileImgUrl,
        history: _profileImageHistory,
        onPickFromGallery: () => _uploadNewProfileImage(ImageSource.gallery),
        onPickFromCamera: () => _uploadNewProfileImage(ImageSource.camera),
        onSelectExisting: (url) => _setProfileImage(url),
      ),
    );
  }

  Future<void> _uploadNewProfileImage(ImageSource source) async {
    if (_userId == null) return;

    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() => _uploadingImage = true);

    final ext = picked.path.split('.').last.toLowerCase();
    final ts = DateTime.now().millisecondsSinceEpoch;

    final storagePath = '$_userId/profile_images/$ts.$ext';

    try {
      // =========================
      // WEB
      // =========================
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();

        await _supabase.storage.from('user_data').uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
              ),
            );
      }

      // =========================
      // MOBILE
      // =========================
      else {
        final file = File(picked.path);

        await _supabase.storage.from('user_data').upload(
              storagePath,
              file,
              fileOptions: const FileOptions(
                upsert: true,
              ),
            );
      }
    } catch (e) {
      debugPrint(
        'Profile image upload error: $e',
      );
      if (mounted) {
        _showSnack(
          'Upload failed. Please try again.',
          kRedAccent,
        );
      }

      if (mounted) {
        setState(() => _uploadingImage = false);
      }

      return;
    }

    final publicUrl =
        _supabase.storage.from('user_data').getPublicUrl(storagePath) +
            '?t=${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _setProfileImage(
        publicUrl,
        alsoAddToHistory: true,
      );

      if (mounted) {
        _showSnack(
          'Profile picture updated!',
          Colors.green,
        );
      }
    } catch (e) {
      debugPrint(
        'Profile image save error: $e',
      );

      if (mounted) {
        _showSnack(
          'Failed to save picture.',
          kRedAccent,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }
  // Future<void> _uploadNewProfileImage(ImageSource source) async {
  //   if (_userId == null) return;
  //   final picker = ImagePicker();
  //   final picked = await picker.pickImage(source: source, imageQuality: 80);
  //   if (picked == null) return;

  //   setState(() => _uploadingImage = true);
  //   final file = File(picked.path);
  //   final ext = picked.path.split('.').last.toLowerCase();
  //   final ts = DateTime.now().millisecondsSinceEpoch;
  //   final storagePath = '$_userId/profile_images/$ts.$ext';

  //   try {
  //     await _supabase.storage.from('user_data').upload(
  //           storagePath,
  //           file,
  //           fileOptions: const FileOptions(upsert: true),
  //         );
  //   } catch (e) {
  //     debugPrint('Profile image upload error: $e');
  //     if (mounted) _showSnack('Upload failed. Please try again.', kRedAccent);
  //     if (mounted) setState(() => _uploadingImage = false);
  //     return;
  //   }

  //   final publicUrl =
  //       _supabase.storage.from('user_data').getPublicUrl(storagePath) +
  //           '?t=${DateTime.now().millisecondsSinceEpoch}';

  //   try {
  //     await _setProfileImage(publicUrl, alsoAddToHistory: true);
  //     if (mounted) _showSnack('Profile picture updated!', Colors.green);
  //   } catch (e) {
  //     debugPrint('Profile image save error: $e');
  //     if (mounted) {
  //       _showSnack(
  //         'Failed to save picture. Check Users table permissions (RLS).',
  //         kRedAccent,
  //       );
  //     }
  //   } finally {
  //     if (mounted) setState(() => _uploadingImage = false);
  //   }
  // }

  Future<void> _setProfileImage(
    String url, {
    bool alsoAddToHistory = false,
  }) async {
    if (_userId == null) return;

    // Existing + new image
    final nextHistory = <String>[
      if (alsoAddToHistory) url,
      ..._profileImageHistory,
    ].where((e) => e.trim().isNotEmpty).toSet().toList();

    try {
      await _supabase.from('Users').update({
        'profile_img_url': url,

        // IMPORTANT
        'all_profile_images': jsonEncode(nextHistory),
      }).eq('id', _userId!);

      if (!mounted) return;

      setState(() {
        _currentImgUrl = url;
        _profileImgUrl = url;

        // LOCAL STATE UPDATE
        _profileImageHistory = nextHistory;
      });

      debugPrint(
        'UPDATED HISTORY => $nextHistory',
      );
    } catch (e) {
      throw Exception(
        'Users update failed: $e',
      );
    }
  }

  // Future<void> _setProfileImage(
  //   String url, {
  //   bool alsoAddToHistory = false,
  // }) async {
  //   if (_userId == null) return;

  //   final nextHistory = <String>[
  //     if (alsoAddToHistory) url,
  //     ..._profileImageHistory,
  //   ].toSet().where((e) => e.trim().isNotEmpty).toList();

  //   final updateNew = <String, dynamic>{
  //     'profile_img_url': url,
  //     'all_profile_images': nextHistory,
  //   };
  //   final updateOld = <String, dynamic>{
  //     'profile_img_url': url,
  //   };

  //   try {
  //     await _supabase.from('Users').update(updateNew).eq('id', _userId!);
  //   } catch (_) {
  //     try {
  //       await _supabase.from('Users').update(updateOld).eq('id', _userId!);
  //     } catch (e) {
  //       throw Exception('Users update failed: $e');
  //     }
  //   }

  //   if (!mounted) return;
  //   setState(() {
  //     _currentImgUrl = url;
  //     _profileImgUrl = url;
  //     if (alsoAddToHistory) _profileImageHistory = nextHistory;
  //   });
  // }

  Widget _buildAvatar() {
    final initial = _firstName.trim().isNotEmpty
        ? _firstName.trim()[0].toUpperCase()
        : (_email.trim().isNotEmpty ? _email.trim()[0].toUpperCase() : 'U');
    final url = _profileImgUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: kBgDark),
      child: ClipOval(
        child: hasUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 26,
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 26,
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EDIT DIALOG
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _showEditDialog() async {
    final fCtrl = TextEditingController(text: _firstName);
    final lCtrl = TextEditingController(text: _lastName);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(fCtrl, 'First Name'),
            const SizedBox(height: 12),
            _dialogField(lCtrl, 'Last Name'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _supabase.from('Users').update({
                  'first_name': fCtrl.text.trim(),
                  'last_name': lCtrl.text.trim(),
                }).eq('id', _userId!);
                if (mounted) {
                  setState(() {
                    _firstName = fCtrl.text.trim();
                    _lastName = lCtrl.text.trim();
                  });
                  _showSnack('Profile updated!', Colors.green);
                }
              } catch (e) {
                debugPrint('Update error: $e');
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label) => TextField(
        controller: ctrl,
        style: const TextStyle(color: kTextPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kTextSecondary),
          filled: true,
          fillColor: kBgDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kCardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kCardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kAccentBlue, width: 1.5),
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN OUT — bulletproof sequence
  // KEY POINTS:
  //   1. Confirm dialog first (uses dialog's own context, not screen context)
  //   2. Set _signingOut flag → build() switches to safe placeholder
  //   3. Navigate to login screen FIRST (widget unmounts, no more queries)
  //   4. THEN call supabase.auth.signOut() in a microtask after navigation
  //   5. NO _showSnack or any UI calls after sign out (widget is gone)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    // Step 1: Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRedAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    // Step 2: Flip flag so build() goes to safe placeholder immediately.
    // No more Supabase queries can be triggered from this widget.
    setState(() => _signingOut = true);

    // Step 3: Navigate to login screen FIRST while session is still valid.
    // This unmounts ProfileScreen cleanly.
    try {
      context.goNamed('login_screen');
    } catch (_) {
      // Fallback if goNamed fails (route mismatch etc.)
      try {
        context.go('/login_screen');
      } catch (_) {}
    }

    // Step 4: After navigation has been scheduled, fire signOut on the next
    // microtask so the navigation transition starts first. We DON'T touch
    // setState or any UI after this — widget is unmounted.
    Future<void>.microtask(() async {
      try {
        await _supabase.auth.signOut();
      } catch (e) {
        debugPrint('signOut error (non-fatal, user already navigated): $e');
      }
    });
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // ★ FIX: while sign-out is in progress show a clean placeholder so the
    //   widget tree never tries to render stale user data with no session.
    if (_signingOut) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: kBgDark,
        child: const Center(
          child: CircularProgressIndicator(color: kAccentBlue, strokeWidth: 2),
        ),
      );
    }

    if (_loading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: kBgDark,
        child: const Center(
          child: CircularProgressIndicator(color: kAccentBlue, strokeWidth: 2),
        ),
      );
    }

    final fullName =
        '${_firstName.isNotEmpty ? _firstName : 'User'} $_lastName'.trim();

    return Container(
      width: widget.width,
      height: widget.height,
      color: kBgDark,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top "Profile" label
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Profile',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // Main profile card (header + achievements combined)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildProfileCard(fullName),
            ),

            const SizedBox(height: 22),

            // Account Settings section
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, color: kAccentBlue, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Account Settings',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Settings list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _settingsCard(
                    icon: Icons.shield_outlined,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your password and security settings',
                    highlighted: _highlightedSetting == 'privacy',
                    onTap: () => _flashSettingHighlight('privacy'),
                  ),
                  const SizedBox(height: 10),
                  _settingsCard(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Configure how you receive alerts',
                    highlighted: _highlightedSetting == 'notifications',
                    onTap: () => _flashSettingHighlight('notifications'),
                  ),
                  const SizedBox(height: 10),
                  _settingsCard(
                    icon: Icons.language_outlined,
                    title: 'Language & Region',
                    subtitle: 'English (US), UTC-7',
                    highlighted: _highlightedSetting == 'language',
                    onTap: () => _flashSettingHighlight('language'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Sign Out
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSignOutButton(),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MAIN PROFILE CARD — header + achievements combined
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProfileCard(String fullName) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCardBorder),
      ),
      child: Column(
        children: [
          // Top section: avatar + name + email + edit button
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with camera badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kAccentBlue, width: 2.5),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: _buildAvatar(),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: GestureDetector(
                        onTap: _uploadingImage ? null : _openProfileImageSheet,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kAccentBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: kCardBg, width: 2.5),
                          ),
                          child: _uploadingImage
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Name + email + edit button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            color: kTextMuted,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _email,
                              style: const TextStyle(
                                color: kTextSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _showEditDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: kAccentBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'EDIT PROFILE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: kCardBorder),

          // Achievements & Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      color: kAccentBlue,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Achievements & Stats',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _statColumn('Submissions', '$_totalSubmissions'),
                    ),
                    Expanded(
                      child: _statColumn(
                        'Avg Score',
                        _avgScore > 0 ? _avgScore.toStringAsFixed(1) : '—',
                      ),
                    ),
                  ],
                ),
                ProfileBannersWidget(
                  userId: _userId!,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SETTINGS CARD — 2-line item
  // ─────────────────────────────────────────────────────────────────────────
  Widget _settingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool highlighted = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlighted ? kAccentBlue : kCardBorder,
              width: highlighted ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: highlighted ? kAccentBlue : kTextSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: kTextMuted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: kTextMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN OUT BUTTON
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSignOutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _signOut,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: kRedAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kRedAccent.withOpacity(0.5), width: 1.2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: kRedAccent, size: 17),
              SizedBox(width: 8),
              Text(
                'SIGN OUT',
                style: TextStyle(
                  color: kRedAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE IMAGE SHEET
// ═══════════════════════════════════════════════════════════════════════════
class _ProfileImageSheet extends StatelessWidget {
  const _ProfileImageSheet({
    required this.currentUrl,
    required this.history,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    required this.onSelectExisting,
  });

  final String? currentUrl;
  final List<String> history;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;
  final ValueChanged<String> onSelectExisting;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeBottom = media.padding.bottom;
    final maxHeight = media.size.height * 0.72;

    final unique = <String>[
      if (currentUrl != null && currentUrl!.trim().isNotEmpty) currentUrl!,
      ...history,
    ].toSet().toList();

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined,
                    color: kAccentBlue, size: 18),
                SizedBox(width: 8),
                Text(
                  'Choose Profile Photo',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: unique.isEmpty
                  ? const Center(
                      child: Text(
                        'No previous uploads yet.',
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: unique.length,
                      itemBuilder: (ctx, i) {
                        final url = unique[i];
                        final isSelected = currentUrl == url;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            onSelectExisting(url);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? kAccentBlue : kCardBorder,
                                width: isSelected ? 1.6 : 1,
                              ),
                              color: kBgDark,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: kTextMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + safeBottom),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextPrimary,
                      side: const BorderSide(color: kCardBorder),
                      backgroundColor: kBgDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onPickFromGallery();
                    },
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text(
                      'Upload',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onPickFromCamera();
                    },
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text(
                      'Camera',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
