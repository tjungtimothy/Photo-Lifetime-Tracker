// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────
class CritiqueItem {
  final String id;
  final String url;
  final String type; // 'audio' | 'video'
  final String? judgeNote;
  final String? judgeId;
  final String? mediaId;
  final DateTime? createdAt;

  CritiqueItem({
    required this.id,
    required this.url,
    required this.type,
    this.judgeNote,
    this.judgeId,
    this.mediaId,
    this.createdAt,
  });

  bool get isVideo => type == 'video';

  factory CritiqueItem.fromMap(Map<String, dynamic> map) {
    final url = (map['file_url'] ?? '').toString();
    final lowerUrl = url.toLowerCase();
    String dbType = (map['file_type'] ?? '').toString().trim().toLowerCase();
    String finalType;
    if (dbType == 'video' || dbType == 'audio') {
      finalType = dbType;
    } else {
      finalType = (lowerUrl.endsWith('.mp4') ||
              lowerUrl.endsWith('.mov') ||
              lowerUrl.endsWith('.avi') ||
              lowerUrl.endsWith('.webm'))
          ? 'video'
          : 'audio';
    }
    return CritiqueItem(
      id: map['id'] as String,
      url: url,
      type: finalType,
      judgeNote: map['judge_note'] as String?,
      judgeId: map['judge_id'] as String?,
      mediaId: map['media_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }
}

// ─────────────────────────────────────────────
// ACCENT COLOR
// ─────────────────────────────────────────────
const Color _kAccent = Color(0xFF379DF0);

class CritiqueTab extends StatefulWidget {
  const CritiqueTab({
    super.key,
    this.width,
    this.height,
    required this.mediaId,
  });

  final double? width;
  final double? height;
  final String mediaId;

  static String routeName = 'critique_tab';
  static String routePath = '/critique_tab';

  @override
  State<CritiqueTab> createState() => _CritiqueTabState();
}

class _CritiqueTabState extends State<CritiqueTab>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _showAll = false;
  static const int _previewCount = 3;

  // Currently expanded critique id
  String? _expandedId;
  // Track loading state for the active item
  bool _isLoadingMedia = false;

  // Lock to prevent multiple simultaneous _togglePlay calls
  bool _isTransitioning = false;

  // Audio player (single shared instance)
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _audioPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  double _volume = 1.0;
  bool _showVolume = false;
  String? _loadedAudioUrl;

  // Video
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  String? _loadedVideoUrl;

  // ★ PERF FIX: Throttled video state tracking — only rebuild on real changes
  bool _videoIsPlaying = false;
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  Timer? _videoTickTimer;

  // Waveform cache
  final Map<String, List<double>> _waveCache = {};

  // Subscriptions
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  // Data
  List<CritiqueItem> _items = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ★ Lifecycle listener
    _configureAudioPlayer();
    _fetchCritiques();

    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _audioPlaying = state.playing);
    });
    _positionSub = _audioPlayer.positionStream.listen((pos) {
      // ★ PERF FIX: only rebuild if changed by >= 100ms (audio smooth enough)
      if (mounted && (pos - _audioPosition).inMilliseconds.abs() >= 100) {
        setState(() => _audioPosition = pos);
      }
    });
    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (mounted) setState(() => _audioDuration = dur ?? Duration.zero);
    });
  }

  // ★ PERF FIX: Configure audio player for fast loading
  void _configureAudioPlayer() {
    // Buffer ahead aggressively for smooth network playback
    try {
      _audioPlayer.setLoopMode(LoopMode.off);
      _audioPlayer.setShuffleModeEnabled(false);
    } catch (_) {}
  }

  @override
  void dispose() {
    // ★ CRITICAL FIX: Stop everything BEFORE disposing
    // Otherwise native players keep running in background and audio continues.

    // 0. Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // 1. Cancel timers/subscriptions first so no more callbacks fire
    _videoTickTimer?.cancel();
    _videoTickTimer = null;
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();

    // 2. Stop and dispose VIDEO controller properly
    final vc = _videoController;
    if (vc != null) {
      vc.removeListener(_videoListener);
      // Pause synchronously (don't await — dispose() is sync method)
      vc.pause(); // returns Future but we don't wait
      vc.setVolume(0); // ★ Mute immediately so no sound leaks while disposing
      vc.dispose();
      _videoController = null;
    }

    // 3. Stop and dispose AUDIO player properly
    // Pause first so native side stops immediately, then dispose
    _audioPlayer.pause(); // fire-and-forget, but native pauses fast
    _audioPlayer.setVolume(0); // ★ Mute as safety net
    _audioPlayer.stop(); // hard stop
    _audioPlayer.dispose();

    super.dispose();
  }

  // ★ App lifecycle: pause media when app goes to background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // App is not visible — pause everything
      _videoController?.pause();
      _audioPlayer.pause();
      _videoTickTimer?.cancel();
    }
  }

  // ★ Pause media when widget becomes invisible (e.g. tab switch)
  @override
  void deactivate() {
    _videoController?.pause();
    _audioPlayer.pause();
    _videoTickTimer?.cancel();
    super.deactivate();
  }

  Future<void> _fetchCritiques() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final response = await SupaFlow.client
          .from('Critiques')
          .select()
          .eq('media_id', widget.mediaId)
          .order('created_at', ascending: false);
      final items = (response as List)
          .map((item) => CritiqueItem.fromMap(item as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<double> _waveform(String id, int bars) {
    if (_waveCache.containsKey(id) && _waveCache[id]!.length == bars) {
      return _waveCache[id]!;
    }
    final seed = id.hashCode;
    final rng = math.Random(seed);
    final list = List<double>.generate(bars, (i) {
      final t = i / (bars - 1);
      final envelope = 0.4 + 0.6 * math.sin(t * math.pi);
      final noise = 0.4 + rng.nextDouble() * 0.6;
      return (envelope * noise).clamp(0.15, 1.0);
    });
    _waveCache[id] = list;
    return list;
  }

  Future<void> _stopAllMedia() async {
    // Stop video tick timer first
    _videoTickTimer?.cancel();
    _videoTickTimer = null;

    // Stop audio
    await _audioPlayer.stop();
    _loadedAudioUrl = null;

    // Stop & dispose video
    final vc = _videoController;
    if (vc != null) {
      vc.removeListener(_videoListener);
      try {
        await vc.pause();
      } catch (_) {}
      try {
        await vc.dispose();
      } catch (_) {}
      _videoController = null;
      _loadedVideoUrl = null;
    }

    if (mounted) {
      setState(() {
        _videoInitialized = false;
        _audioPosition = Duration.zero;
        _audioDuration = Duration.zero;
        _videoIsPlaying = false;
        _videoPosition = Duration.zero;
        _videoDuration = Duration.zero;
      });
    }
  }

  Future<void> _togglePlay(CritiqueItem item) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      final isSameItem = _expandedId == item.id;
      final isCurrentlyPlaying = _isItemPlaying(item);

      // Case 1: Same item playing → PAUSE
      if (isSameItem && isCurrentlyPlaying) {
        if (item.isVideo) {
          await _videoController?.pause();
          _videoTickTimer?.cancel();
        } else {
          await _audioPlayer.pause();
        }
        return;
      }

      // Case 2: Same item paused → RESUME (don't reload)
      if (isSameItem && !isCurrentlyPlaying) {
        if (item.isVideo) {
          final vc = _videoController;
          if (vc != null && _loadedVideoUrl == item.url && _videoInitialized) {
            await vc.play();
            _startVideoTickTimer();
            return;
          }
          final savedPos = vc?.value.position ?? Duration.zero;
          await _stopAllMedia();
          setState(() => _expandedId = item.id);
          await _initVideo(item, seekTo: savedPos);
          return;
        } else {
          if (_loadedAudioUrl == item.url) {
            await _audioPlayer.setVolume(_volume);
            await _audioPlayer.play();
            return;
          }
          final savedPos = _audioPosition;
          await _stopAllMedia();
          setState(() => _expandedId = item.id);
          await _initAudio(item, seekTo: savedPos);
          return;
        }
      }

      // Case 3: Different item → stop, start new
      await _stopAllMedia();

      if (mounted) {
        setState(() {
          _expandedId = item.id;
          _isLoadingMedia = true;
        });
      }

      if (item.isVideo) {
        await _initVideo(item);
      } else {
        await _initAudio(item);
      }
    } finally {
      _isTransitioning = false;
      if (mounted) {
        setState(() => _isLoadingMedia = false);
      }
    }
  }

  // ★ PERF FIX: Audio initialization with parallel ops + preload hint
  Future<void> _initAudio(CritiqueItem item, {Duration? seekTo}) async {
    try {
      // setUrl with preload — buffers ahead immediately
      final loadFuture = _audioPlayer.setUrl(
        item.url,
        preload: true,
      );
      // Set volume in parallel (doesn't need URL loaded)
      _audioPlayer.setVolume(_volume);

      await loadFuture;
      _loadedAudioUrl = item.url;

      if (seekTo != null && seekTo > Duration.zero) {
        await _audioPlayer.seek(seekTo);
      }
      // Don't await play — let it start while we return
      _audioPlayer.play();
    } catch (e) {
      _loadedAudioUrl = null;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not play audio: $e')));
      }
    }
  }

  // ★ PERF FIX: Video initialization optimized
  Future<void> _initVideo(CritiqueItem item, {Duration? seekTo}) async {
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(item.url),
      // ★ Hints for faster startup
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );
    _videoController = ctrl;
    _loadedVideoUrl = item.url;

    try {
      // Initialize (loads metadata, first frames)
      await ctrl.initialize();
      if (!mounted) return;

      // ★ Add lightweight listener (no setState in it)
      ctrl.addListener(_videoListener);

      // Set initial state values
      setState(() {
        _videoInitialized = true;
        _videoDuration = ctrl.value.duration;
      });

      // Apply current volume to video
      ctrl.setVolume(_volume);

      // Seek if needed (parallel to play call)
      if (seekTo != null && seekTo > Duration.zero) {
        ctrl.seekTo(seekTo);
      }

      // Don't await play — start it and let listener track state
      ctrl.play();

      // Start polling timer for smooth progress updates (4x/sec, not 60x)
      _startVideoTickTimer();
    } catch (e) {
      _loadedVideoUrl = null;
      _videoController = null;
      if (mounted) {
        setState(() => _videoInitialized = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not play video: $e')));
      }
    }
  }

  // ★ PERF FIX: Lightweight listener — only updates the play/pause state
  //   (not every frame). Position is updated by the timer instead.
  void _videoListener() {
    final vc = _videoController;
    if (vc == null || !mounted) return;
    final playing = vc.value.isPlaying;
    if (playing != _videoIsPlaying) {
      setState(() => _videoIsPlaying = playing);
    }
  }

  // ★ PERF FIX: Tick timer — polls video position 4 times per second
  //   instead of rebuilding 60 times/sec from the listener
  void _startVideoTickTimer() {
    _videoTickTimer?.cancel();
    _videoTickTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final vc = _videoController;
      if (vc == null || !mounted) return;
      final pos = vc.value.position;
      // Only rebuild on real change
      if ((pos - _videoPosition).inMilliseconds.abs() >= 200) {
        setState(() => _videoPosition = pos);
      }
    });
  }

  Future<void> _stopActive() async {
    await _stopAllMedia();
    if (mounted) {
      setState(() {
        _expandedId = null;
      });
    }
  }

  Future<void> _onRowTap(CritiqueItem item) async {
    if (_expandedId == item.id) {
      await _stopActive();
    } else {
      if (_expandedId != null) {
        await _stopAllMedia();
      }
      if (mounted) {
        setState(() {
          _expandedId = item.id;
          _isLoadingMedia = true;
        });
      }
      // ★ AUTO-PLAY on expand — user expects this
      // Fire and forget, _togglePlay handles state
      _togglePlay(item);
    }
  }

  void _seekRelative(CritiqueItem item, int seconds) {
    if (item.isVideo) {
      final ctrl = _videoController;
      if (ctrl == null) return;
      final dur = ctrl.value.duration;
      var pos = ctrl.value.position + Duration(seconds: seconds);
      if (pos < Duration.zero) pos = Duration.zero;
      if (pos > dur) pos = dur;
      ctrl.seekTo(pos);
      setState(() => _videoPosition = pos);
    } else {
      var pos = _audioPosition + Duration(seconds: seconds);
      if (pos < Duration.zero) pos = Duration.zero;
      if (pos > _audioDuration) pos = _audioDuration;
      _audioPlayer.seek(pos);
    }
  }

  void _seekToFraction(CritiqueItem item, double fraction) {
    fraction = fraction.clamp(0.0, 1.0);
    if (item.isVideo) {
      final ctrl = _videoController;
      if (ctrl == null) return;
      final dur = ctrl.value.duration;
      final target =
          Duration(milliseconds: (dur.inMilliseconds * fraction).toInt());
      ctrl.seekTo(target);
      setState(() => _videoPosition = target);
    } else {
      final dur = _audioDuration;
      _audioPlayer.seek(
          Duration(milliseconds: (dur.inMilliseconds * fraction).toInt()));
    }
  }

  bool _isItemPlaying(CritiqueItem item) {
    if (_expandedId != item.id) return false;
    if (item.isVideo) return _videoIsPlaying;
    return _audioPlaying;
  }

  Duration _itemPosition(CritiqueItem item) {
    if (_expandedId != item.id) return Duration.zero;
    if (item.isVideo) return _videoPosition;
    return _audioPosition;
  }

  Duration _itemDuration(CritiqueItem item) {
    if (_expandedId != item.id) return Duration.zero;
    if (item.isVideo) return _videoDuration;
    return _audioDuration;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final visible = _showAll ? _items : _items.take(_previewCount).toList();
    final hasMore = _items.length > _previewCount;

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
        ),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
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
              const Text('Could not load critiques',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              const SizedBox(height: 6),
              Text(_loadError!,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 11)),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: _fetchCritiques, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic_rounded, size: 15, color: _kAccent),
                const SizedBox(width: 6),
                const Text('Critiques',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_items.length} files',
                      style: const TextStyle(
                          color: _kAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              _buildEmptyState()
            else ...[
              ...visible
                  .asMap()
                  .entries
                  .map((e) => _buildCritiqueRow(context, e.value, e.key)),
              if (hasMore) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _showAll = !_showAll),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAll
                              ? 'See Less'
                              : 'See More (${_items.length - _previewCount} more)',
                          style: const TextStyle(
                              color: _kAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showAll
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Icon(Icons.mic_off_rounded,
              size: 36, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 10),
          Text('No critiques yet',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCritiqueRow(BuildContext context, CritiqueItem item, int index) {
    final isExpanded = _expandedId == item.id;
    final isVideo = item.isVideo;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isExpanded ? _kAccent.withOpacity(0.06) : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? _kAccent.withOpacity(0.4)
              : Colors.white.withOpacity(0.07),
          width: isExpanded ? 1.2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _onRowTap(item),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isVideo
                                    ? _kAccent.withOpacity(0.18)
                                    : _kAccent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isVideo ? 'VIDEO' : 'AUDIO',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isVideo
                                      ? _kAccent
                                      : _kAccent.withOpacity(0.75),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Critique #${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            // ★ Show inline loading dot when fetching this item
                            if (isExpanded && _isLoadingMedia) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: _kAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.judgeNote != null &&
                            item.judgeNote!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.judgeNote!,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 10,
                                fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color:
                        isExpanded ? _kAccent : Colors.white.withOpacity(0.3),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildExpandedControls(item),
        ],
      ),
    );
  }

  Widget _buildExpandedControls(CritiqueItem item) {
    final pos = _itemPosition(item);
    final total = _itemDuration(item);
    final progress = total.inMilliseconds > 0
        ? pos.inMilliseconds / total.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          // Video preview
          if (item.isVideo && _videoInitialized && _videoController != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio == 0
                      ? 16 / 9
                      : _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else if (item.isVideo && !_videoInitialized)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kAccent),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Loading video…',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Waveform (audio only)
          if (!item.isVideo) _buildWaveformBar(item, progress),

          // Slider (video only)
          if (item.isVideo)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: _kAccent,
                  inactiveTrackColor: Colors.white.withOpacity(0.15),
                  thumbColor: _kAccent,
                  overlayColor: _kAccent.withOpacity(0.2),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (v) => _seekToFraction(item, v),
                ),
              ),
            ),

          // Time row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(pos),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w500)),
                Text(_formatDuration(total),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Control row
          Row(
            children: [
              _iconBtn(
                icon: Icons.replay_10_rounded,
                onTap: () => _seekRelative(item, -10),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _togglePlay(item),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _kAccent, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                          color: _kAccent.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: _isLoadingMedia && _expandedId == item.id
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kAccent),
                        )
                      : Icon(
                          _isItemPlaying(item)
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: _kAccent,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.forward_10_rounded,
                onTap: () => _seekRelative(item, 10),
              ),
              const Spacer(),
              _buildVolumeControl(),
              _iconBtn(
                icon: Icons.close_rounded,
                onTap: _stopActive,
                color: Colors.redAccent.withOpacity(0.8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformBar(CritiqueItem item, double progress) {
    return LayoutBuilder(builder: (context, constraints) {
      const barWidth = 3.0;
      const barSpacing = 2.0;
      final totalWidth = constraints.maxWidth;
      final barCount =
          ((totalWidth + barSpacing) / (barWidth + barSpacing)).floor();
      final wave = _waveform(item.id, barCount.clamp(20, 80));

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          final fraction = details.localPosition.dx / totalWidth;
          _seekToFraction(item, fraction);
        },
        onHorizontalDragUpdate: (details) {
          final fraction = details.localPosition.dx / totalWidth;
          _seekToFraction(item, fraction);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(wave.length, (i) {
                final isPast = i / wave.length < progress;
                final height = (wave[i] * 32).clamp(4.0, 32.0);
                return Container(
                  width: barWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: isPast ? _kAccent : Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              }),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildVolumeControl() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: _showVolume
          ? Row(
              children: [
                Icon(
                  _volume == 0
                      ? Icons.volume_off_rounded
                      : _volume < 0.5
                          ? Icons.volume_down_rounded
                          : Icons.volume_up_rounded,
                  color: Colors.white.withOpacity(0.6),
                  size: 18,
                ),
                SizedBox(
                  width: 80,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: Colors.white.withOpacity(0.7),
                      inactiveTrackColor: Colors.white.withOpacity(0.15),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: _volume,
                      onChanged: (v) {
                        setState(() => _volume = v);
                        _audioPlayer.setVolume(v);
                        _videoController?.setVolume(v);
                      },
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showVolume = false),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white.withOpacity(0.4), size: 14),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            )
          : _iconBtn(
              icon: _volume == 0
                  ? Icons.volume_off_rounded
                  : _volume < 0.5
                      ? Icons.volume_down_rounded
                      : Icons.volume_up_rounded,
              onTap: () => setState(() => _showVolume = true),
            ),
    );
  }

  Widget _iconBtn(
      {required IconData icon, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child:
            Icon(icon, color: color ?? Colors.white.withOpacity(0.7), size: 22),
      ),
    );
  }
}
