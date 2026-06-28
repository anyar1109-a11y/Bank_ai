import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/user_data.dart';
import '../models/verification_record.dart';
import '../services/face_service.dart';
import '../services/activity_service.dart';
import '../services/verification_history_service.dart';
import '../services/location_service.dart';

import 'dashboard_screen.dart';

class _VerifStep {
  final String label;
  final String instruction;
  final IconData icon;
  final Color color;
  const _VerifStep({
    required this.label,
    required this.instruction,
    required this.icon,
    required this.color,
  });
}

enum _StepStatus { waiting, detecting, success }

class LivenessScreen extends StatefulWidget {
  const LivenessScreen({super.key});

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen>
    with TickerProviderStateMixin {
  // ── Kamera & Face ──────────────────────────────────────────────────────────
  CameraController? controller;
  CameraDescription? frontCamera;
  final FaceService faceService = FaceService();

  bool isCameraReady = false;
  bool isDetecting = false;
  bool isProcessingStep = false;
  bool faceDetected = false;

  // ── Langkah verifikasi ─────────────────────────────────────────────────────
  static const List<_VerifStep> _steps = [
    _VerifStep(
      label: 'Berkedip',
      instruction: 'Kedipkan kedua mata Anda secara perlahan',
      icon: Icons.remove_red_eye_outlined,
      color: Color(0xFF6366F1),
    ),
    _VerifStep(
      label: 'Senyum',
      instruction: 'Tersenyumlah lebar ke arah kamera',
      icon: Icons.sentiment_very_satisfied_outlined,
      color: Color(0xFFF59E0B),
    ),
    _VerifStep(
      label: 'Toleh Kanan',
      instruction: 'Tolehkan wajah Anda ke sebelah kanan',
      icon: Icons.arrow_forward_rounded,
      color: Color(0xFF10B981),
    ),
    _VerifStep(
      label: 'Toleh Kiri',
      instruction: 'Tolehkan wajah Anda ke sebelah kiri',
      icon: Icons.arrow_back_rounded,
      color: AppColors.primary,
    ),
  ];

  int currentStep = 0;
  _StepStatus stepStatus = _StepStatus.waiting;

  int _blinkFrames = 0;
  static const int _blinkFramesRequired = 2;
  int _smileFrames = 0;
  static const int _smileFramesRequired = 4;
  int _turnFrames = 0;
  static const int _turnFramesRequired = 5;

  String statusText = 'Arahkan wajah ke kamera';

  // ── Animasi ────────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _pulseAnim;
  late Animation<double> _successScaleAnim;
  late Animation<double> _successOpacityAnim;

  // ── GPS (background, untuk riwayat) ───────────────────────────────────────
  final _locationService = LocationService();
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<ServiceStatus>? _serviceSub;
  String _liveLatitude = '';
  String _liveLongitude = '';
  String _liveAddress = '';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeIn),
    );

    _initCamera();
    _startLiveGps();
  }

  Future<void> _startLiveGps() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _applyPosition(pos);
      _positionSub = _locationService
          .getPositionStream()
          .listen((p) => _applyPosition(p), onError: (_) {});
      _serviceSub = _locationService.getGpsServiceStream().listen((_) {});
    } catch (_) {}
  }

  Future<void> _applyPosition(Position pos) async {
    if (!mounted) return;
    _liveLatitude = pos.latitude.toStringAsFixed(6);
    _liveLongitude = pos.longitude.toStringAsFixed(6);
    UserData.latitude = _liveLatitude;
    UserData.longitude = _liveLongitude;
    try {
      final addr = await _locationService.getAddressFromCoordinates(
          pos.latitude, pos.longitude);
      if (!mounted) return;
      _liveAddress = addr;
      UserData.address = addr;
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: kIsWeb
            ? ImageFormatGroup.jpeg
            : (Platform.isAndroid
                ? ImageFormatGroup.nv21
                : ImageFormatGroup.bgra8888),
      );
      await controller!.initialize();
      if (!mounted) return;
      setState(() => isCameraReady = true);

      if (kIsWeb) {
        setState(() => faceDetected = true);
        _triggerWebAutoProgress();
      } else {
        await controller!.startImageStream(_onCameraImage);
      }
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  void _triggerWebAutoProgress() {
    if (!mounted) return;
    setState(() {
      stepStatus = _StepStatus.detecting;
      statusText = 'Mendeteksi ${_steps[currentStep].label}...';
    });
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted && !isProcessingStep) _completeStep();
    });
  }

  void _onCameraImage(CameraImage image) {
    if (isDetecting || isProcessingStep || controller == null ||
        frontCamera == null || kIsWeb) return;
    isDetecting = true;

    final inputImage = faceService.inputImageFromCameraImage(
        image, frontCamera!, controller!);
    if (inputImage == null) {
      isDetecting = false;
      return;
    }

    faceService.detectFaces(inputImage).then((faces) {
      if (!mounted) { isDetecting = false; return; }
      if (faces.isEmpty) {
        setState(() {
          faceDetected = false;
          stepStatus = _StepStatus.waiting;
          statusText = 'Wajah tidak terdeteksi, arahkan wajah ke kamera';
          _resetFrameCounters();
        });
        isDetecting = false;
        return;
      }
      setState(() {
        faceDetected = true;
        stepStatus = _StepStatus.detecting;
      });
      _evaluateStep(faces.first);
      isDetecting = false;
    }).catchError((e) {
      debugPrint('Face detect error: $e');
      isDetecting = false;
    });
  }

  void _resetFrameCounters() {
    _blinkFrames = 0;
    _smileFrames = 0;
    _turnFrames = 0;
  }

  void _evaluateStep(Face face) {
    if (isProcessingStep) return;
    switch (currentStep) {
      case 0:
        final left = face.leftEyeOpenProbability ?? 1.0;
        final right = face.rightEyeOpenProbability ?? 1.0;
        if (left < 0.35 && right < 0.35) {
          _blinkFrames++;
          setState(() => statusText =
              'Kedipan terdeteksi... ($_blinkFrames/$_blinkFramesRequired)');
          if (_blinkFrames >= _blinkFramesRequired) _completeStep();
        } else {
          if (_blinkFrames > 0 && _blinkFrames < _blinkFramesRequired) _blinkFrames = 0;
          setState(() => statusText = 'Kedipkan kedua mata secara perlahan');
        }
        break;
      case 1:
        final smile = face.smilingProbability ?? 0.0;
        final pct = (smile * 100).toInt();
        if (smile > 0.72) {
          _smileFrames++;
          setState(() => statusText =
              'Senyum terdeteksi $pct%! Tahan... ($_smileFrames/$_smileFramesRequired)');
          if (_smileFrames >= _smileFramesRequired) _completeStep();
        } else if (smile > 0.4) {
          _smileFrames = 0;
          setState(() => statusText = 'Hampir! Tersenyum lebih lebar ($pct%)');
        } else {
          _smileFrames = 0;
          setState(() => statusText = 'Tersenyumlah lebih lebar ($pct%)');
        }
        break;
      case 2:
        final angleY = face.headEulerAngleY ?? 0.0;
        if (angleY > 18) {
          _turnFrames++;
          setState(() => statusText =
              'Bagus! Tahan posisi kanan... ($_turnFrames/$_turnFramesRequired)');
          if (_turnFrames >= _turnFramesRequired) _completeStep();
        } else if (angleY > 8) {
          _turnFrames = 0;
          setState(() => statusText = 'Toleh lebih jauh ke kanan (${angleY.toInt()}°)');
        } else {
          _turnFrames = 0;
          setState(() => statusText = 'Tolehkan wajah ke sebelah KANAN');
        }
        break;
      case 3:
        final angleY = face.headEulerAngleY ?? 0.0;
        if (angleY < -18) {
          _turnFrames++;
          setState(() => statusText =
              'Bagus! Tahan posisi kiri... ($_turnFrames/$_turnFramesRequired)');
          if (_turnFrames >= _turnFramesRequired) _completeStep();
        } else if (angleY < -8) {
          _turnFrames = 0;
          setState(() => statusText = 'Toleh lebih jauh ke kiri (${angleY.toInt()}°)');
        } else {
          _turnFrames = 0;
          setState(() => statusText = 'Tolehkan wajah ke sebelah KIRI');
        }
        break;
    }
  }

  Future<void> _completeStep() async {
    if (isProcessingStep) return;
    setState(() {
      isProcessingStep = true;
      stepStatus = _StepStatus.success;
      statusText = '${_steps[currentStep].label} berhasil! ✓';
    });
    _successController.forward(from: 0);

    try {
      if (!kIsWeb) await controller?.stopImageStream();
      final shot = await controller!.takePicture();

      VerificationHistoryService.addRecord(
        VerificationRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'Liveness - ${_steps[currentStep].label}',
          imagePath: shot.path,
          latitude: _liveLatitude.isNotEmpty ? _liveLatitude : UserData.latitude,
          longitude: _liveLongitude.isNotEmpty ? _liveLongitude : UserData.longitude,
          address: _liveAddress.isNotEmpty ? _liveAddress : UserData.address,
          timestamp: DateTime.now(),
          success: true,
        ),
      );
      ActivityService.addActivity('Liveness ${_steps[currentStep].label} Berhasil');

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      if (currentStep < _steps.length - 1) {
        setState(() {
          currentStep++;
          isProcessingStep = false;
          stepStatus = _StepStatus.waiting;
          statusText = 'Arahkan wajah ke kamera';
          _resetFrameCounters();
        });
        if (kIsWeb) {
          _triggerWebAutoProgress();
        } else {
          await controller?.startImageStream(_onCameraImage);
        }
      } else {
        ActivityService.addActivity('Liveness Detection Selesai');
        if (!mounted) return;
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (!mounted) return;
      setState(() {
        isProcessingStep = false;
        stepStatus = _StepStatus.detecting;
        statusText = 'Gagal merekam, coba lagi...';
        _resetFrameCounters();
      });
      if (kIsWeb) {
        _triggerWebAutoProgress();
      } else {
        await controller?.startImageStream(_onCameraImage);
      }
    }
  }

  void _showSuccessDialog() {
    final nama = UserData.nama.isNotEmpty ? UserData.nama : 'Nasabah SmartBank';
    // Ambil nama depan saja
    final namaDepan = nama.trim().split(' ').first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon centang
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verifikasi Berhasil!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Selamat datang + nama
              Text(
                'Selamat Datang,',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                namaDepan,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 28),

              // Tombol masuk
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Masuk ke Aplikasi',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _serviceSub?.cancel();
    _pulseController.dispose();
    _successController.dispose();
    controller?.dispose();
    faceService.dispose();
    super.dispose();
  }

  // ── Helpers warna ──────────────────────────────────────────────────────────
  Color get _currentStepColor => _steps[currentStep].color;

  Color get _borderColor {
    switch (stepStatus) {
      case _StepStatus.waiting: return AppColors.divider;
      case _StepStatus.detecting: return _currentStepColor;
      case _StepStatus.success: return AppColors.success;
    }
  }

  Color get _statusChipBg {
    switch (stepStatus) {
      case _StepStatus.waiting: return AppColors.surfaceVariant;
      case _StepStatus.detecting: return _currentStepColor.withValues(alpha: 0.1);
      case _StepStatus.success: return AppColors.successBg;
    }
  }

  Color get _statusChipText {
    switch (stepStatus) {
      case _StepStatus.waiting: return AppColors.textSecondary;
      case _StepStatus.detecting: return _currentStepColor;
      case _StepStatus.success: return AppColors.success;
    }
  }

  String get _statusBadge {
    switch (stepStatus) {
      case _StepStatus.waiting: return 'SIAPKAN';
      case _StepStatus.detecting: return 'MENDETEKSI';
      case _StepStatus.success: return 'BERHASIL ✓';
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    _buildCameraCard(),
                    const SizedBox(height: 16),
                    _buildInstructionCard(),
                    const SizedBox(height: 16),
                    _buildStepProgress(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: sama persis register_screen TANPA teks "Buat Akun" & label step
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hanya back button, tanpa teks judul
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 16),
          // Progress bar 3 langkah (register: data diri → KTP → wajah)
          // Langkah ke-3 (index 2) = aktif/selesai
          Row(
            children: List.generate(3, (i) {
              // Langkah 0 & 1 sudah selesai (dari register), langkah 2 sedang berjalan
              final done = i < 2;
              final active = i == 2;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: done || active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 6),
                  ],
                ),
              );
            }),
          ),
          // Tidak ada teks label di bawah bar (sesuai permintaan)
        ],
      ),
    );
  }

  // ── Kartu kamera ───────────────────────────────────────────────────────────
  Widget _buildCameraCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 320,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.surfaceVariant),
                  if (isCameraReady && controller != null)
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Transform.scale(
                        scale: stepStatus == _StepStatus.detecting
                            ? _pulseAnim.value
                            : 1.0,
                        child: child,
                      ),
                      child: CameraPreview(controller!),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 12),
                          const Text('Membuka kamera...',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  // Oval panduan
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                          painter: _FaceOvalPainter(color: _borderColor)),
                    ),
                  ),
                  // Checkmark sukses
                  if (stepStatus == _StepStatus.success)
                    Center(
                      child: FadeTransition(
                        opacity: _successOpacityAnim,
                        child: ScaleTransition(
                          scale: _successScaleAnim,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Status chip
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusChipBg,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(
                top: BorderSide(
                    color: _borderColor.withValues(alpha: 0.25), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusChipText.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusBadge,
                    style: TextStyle(
                      color: _statusChipText,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: _statusChipText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  // ── Kartu instruksi langkah aktif ─────────────────────────────────────────
  Widget _buildInstructionCard() {
    final step = _steps[currentStep];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.2), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(step.label),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: step.color.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: step.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, color: step.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Langkah ${currentStep + 1} dari ${_steps.length}',
                    style: TextStyle(
                      color: step.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.instruction,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Progress list langkah ──────────────────────────────────────────────────
  Widget _buildStepProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Verifikasi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_steps.length, (i) {
            final done = i < currentStep;
            final active = i == currentStep;
            final step = _steps[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.successBg
                      : active
                          ? step.color.withValues(alpha: 0.07)
                          : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: done
                        ? AppColors.success.withValues(alpha: 0.3)
                        : active
                            ? step.color.withValues(alpha: 0.35)
                            : AppColors.divider,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.success
                            : active
                                ? step.color
                                : AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : active
                                ? Icon(step.icon, color: Colors.white, size: 16)
                                : Text('${i + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.label,
                            style: TextStyle(
                              color: done
                                  ? AppColors.success
                                  : active
                                      ? step.color
                                      : AppColors.textHint,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            done
                                ? 'Selesai'
                                : active
                                    ? step.instruction
                                    : 'Menunggu...',
                            style: TextStyle(
                              color: done
                                  ? AppColors.success
                                  : active
                                      ? AppColors.textSecondary
                                      : AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (done)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Lulus',
                            style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      )
                    else if (active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: step.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Aktif',
                            style: TextStyle(
                                color: step.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── CustomPainter: oval panduan wajah ────────────────────────────────────
class _FaceOvalPainter extends CustomPainter {
  final Color color;
  const _FaceOvalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    final rx = size.width * 0.34;
    final ry = size.height * 0.38;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const dashLen = 14.0;
    const gapLen = 7.0;
    final perimeter = 2 * pi * sqrt((rx * rx + ry * ry) / 2);
    final totalDashes = (perimeter / (dashLen + gapLen)).round();
    final angleStep = 2 * pi / totalDashes;

    for (int i = 0; i < totalDashes; i++) {
      final startAngle = i * angleStep;
      final endAngle =
          startAngle + angleStep * (dashLen / (dashLen + gapLen));
      final path = Path();
      bool first = true;
      for (double a = startAngle; a <= endAngle; a += 0.03) {
        final x = cx + rx * cos(a);
        final y = cy + ry * sin(a);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FaceOvalPainter old) => old.color != color;
}
