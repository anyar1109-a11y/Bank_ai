import 'dart:async';
import 'dart:io';

import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:flutter/foundation.dart'; // Wajib untuk kIsWeb

import '../models/user_data.dart';
import '../models/verification_record.dart';
import '../services/location_service.dart';
import '../services/face_service.dart';
import '../services/activity_service.dart';
import '../services/verification_history_service.dart';
import '../utils/datetime_format.dart';
import '../widgets/gps_overlay.dart';

import 'liveness_screen.dart';

class FaceDetectionScreen extends StatefulWidget {
  const FaceDetectionScreen({super.key});

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  CameraController? controller;
  CameraDescription? frontCamera;

  final FaceService faceService = FaceService();
  final LocationService locationService = LocationService();

  bool isCameraReady = false;
  bool isDetecting = false;
  bool faceDetected = false;

  bool gpsActive = false;
  String latitude = "-";
  String longitude = "-";
  String address = "Mencari alamat...";
  DateTime? lastAddressFetch;

  StreamSubscription<Position>? positionSub;
  StreamSubscription<ServiceStatus>? gpsServiceSub;

  Timer? clockTimer;
  String timestamp = "-";

  bool isVerifying = false;

  @override
  void initState() {
    super.initState();

    timestamp = formatTimestamp(DateTime.now());

    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        timestamp = formatTimestamp(DateTime.now());
      });
    });

    _setup();
  }

  Future<void> _setup() async {
    await _requestPermissions();
    await _initCamera();
    await _initGps();
  }

  Future<void> _requestPermissions() async {
    if (!kIsWeb) {
      await Permission.camera.request();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final ImageFormatGroup formatGroup;
      if (kIsWeb) {
        formatGroup = ImageFormatGroup.jpeg; 
      } else if (Platform.isAndroid) {
        formatGroup = ImageFormatGroup.nv21;
      } else {
        formatGroup = ImageFormatGroup.bgra8888;
      }

      controller = CameraController(
        frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: formatGroup,
      );

      await controller!.initialize();

      if (!mounted) return;

      setState(() {
        isCameraReady = true;
      });

      // PERBAIKAN UTAMA: startImageStream hanya dipanggil di MOBILE, karena WEB tidak mendukungnya
      if (kIsWeb) {
        setState(() {
          faceDetected = true; // Set true agar UI Web langsung lolos pengecekan wajah
        });
        
        // Fitur Auto-capture untuk Web dipicu langsung di sini
        if (!isVerifying) {
          isVerifying = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && canVerify) {
              _verify();
            }
          });
        }
      } else {
        // Jika di Android/iOS asli, jalankan stream tracking bawaan
        await controller!.startImageStream(_onCameraImage);
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _onCameraImage(CameraImage image) {
    // Fungsi ini sekarang hanya dieksekusi di platform Mobile (Android/iOS)
    if (isDetecting || controller == null || frontCamera == null || kIsWeb) return;

    isDetecting = true;

    final inputImage = faceService.inputImageFromCameraImage(
      image,
      frontCamera!,
      controller!,
    );

    if (inputImage == null) {
      isDetecting = false;
      return;
    }

    faceService.detectFaces(inputImage).then((faces) {
      if (!mounted) {
        isDetecting = false;
        return;
      }

      setState(() {
        faceDetected = faces.isNotEmpty;
      });

      if (faceDetected && !isVerifying) {
        _verify(); 
      }

      isDetecting = false;
    }).catchError((e) {
      debugPrint("Face detect error: $e");
      isDetecting = false;
    });
  }

  Future<void> _initGps() async {
    gpsActive = await locationService.isGpsActive();

    if (!mounted) return;
    setState(() {});

    if (!kIsWeb) {
      gpsServiceSub = locationService.getGpsServiceStream().listen((status) {
        if (!mounted) return;
        setState(() {
          gpsActive = status == ServiceStatus.enabled;
        });
      });
    } else {
      gpsActive = true; 
    }

    try {
      positionSub = locationService.getPositionStream().listen((pos) {
        if (!mounted) return;

        setState(() {
          latitude = pos.latitude.toStringAsFixed(6);
          longitude = pos.longitude.toStringAsFixed(6);
        });

        _maybeFetchAddress(pos.latitude, pos.longitude);
      });

      final firstPos = await locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        latitude = firstPos.latitude.toStringAsFixed(6);
        longitude = firstPos.longitude.toStringAsFixed(6);
      });

      _maybeFetchAddress(firstPos.latitude, firstPos.longitude);
    } catch (e) {
      debugPrint("GPS Error: $e");
    }
  }

  void _maybeFetchAddress(double lat, double lng) {
    final now = DateTime.now();

    if (lastAddressFetch != null &&
        now.difference(lastAddressFetch!) < const Duration(seconds: 15)) {
      return;
    }

    lastAddressFetch = now;

    locationService.getAddressFromCoordinates(lat, lng).then((value) {
      if (!mounted) return;
      setState(() {
        address = value;
      });
    });
  }

  // Tombol diaktifkan jika GPS aktif dan Kamera siap
  bool get canVerify => gpsActive && isCameraReady;

  Future<void> _verify() async {
    if (!mounted) return;
    
    setState(() {
      isVerifying = true;
    });

    try {
      // stopImageStream hanya dihentikan jika bukan di web (karena web tidak menyalakannya)
      if (!kIsWeb) {
        await controller?.stopImageStream();
      }

      final shot = await controller!.takePicture();

      UserData.latitude = latitude;
      UserData.longitude = longitude;
      UserData.address = address;

      // Menyimpan ke history (Tanpa kata 'await' yang memicu merah)
      VerificationHistoryService.addRecord(
        VerificationRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: "Verifikasi Wajah Awal",
          imagePath: shot.path,
          latitude: latitude,
          longitude: longitude,
          address: address,
          timestamp: DateTime.now(),
          success: true,
        ),
      );

      ActivityService.addActivity("Verifikasi Wajah Awal Berhasil");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LivenessScreen(),
        ),
      );
    } catch (e) {
      debugPrint("Verify error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal verifikasi: $e")),
      );

      setState(() {
        isVerifying = false; 
      });
      
      if (!kIsWeb) {
        try {
          await controller?.startImageStream(_onCameraImage);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    positionSub?.cancel();
    gpsServiceSub?.cancel();
    controller?.dispose();
    faceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verifikasi Wajah"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black12,
                    ),
                    child: isCameraReady && controller != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CameraPreview(controller!),
                          )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: GpsInfoOverlay(
                      latitude: latitude,
                      longitude: longitude,
                      address: address,
                      timestamp: timestamp,
                      gpsActive: gpsActive,
                      faceDetected: faceDetected,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!gpsActive)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  "GPS tidak aktif. Aktifkan lokasi perangkat Anda untuk melanjutkan.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: (canVerify && !isVerifying) ? _verify : null,
              child: isVerifying
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("VERIFIKASI WAJAH"),
            ),
          ],
        ),
      ),
    );
  }
}