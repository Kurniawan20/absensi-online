import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

// ── Enum status posisi wajah ─────────────────────────────────────────────────
enum _FaceStatus { noFace, tooFar, tooClose, notCentered, notStraight, ready }

extension _FaceStatusInfo on _FaceStatus {
  String get message {
    switch (this) {
      case _FaceStatus.noFace:
        return 'Arahkan wajah Anda ke kamera';
      case _FaceStatus.tooFar:
        return 'Terlalu jauh — Mendekati kamera';
      case _FaceStatus.tooClose:
        return 'Terlalu dekat — Mundurkan sedikit';
      case _FaceStatus.notCentered:
        return 'Posisikan wajah di tengah oval';
      case _FaceStatus.notStraight:
        return 'Hadap lurus ke depan';
      case _FaceStatus.ready:
        return 'Tetap diam...';
    }
  }

  Color get ovalColor {
    switch (this) {
      case _FaceStatus.ready:
        return Colors.greenAccent;
      case _FaceStatus.noFace:
        return Colors.white70;
      default:
        return Colors.orangeAccent;
    }
  }
}

// ── Main Widget ───────────────────────────────────────────────────────────────
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({Key? key}) : super(key: key);

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  // — Kamera
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 1;

  // — ML Kit
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );
  bool _isDetecting = false;

  // — Status live
  _FaceStatus _faceStatus = _FaceStatus.noFace;

  // — Auto-capture
  double _captureProgress = 0.0;
  Timer? _captureTimer;
  bool _isCapturing = false;

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showSnackbar('Tidak ada kamera ditemukan.');
        return;
      }
      _selectedCameraIndex = _cameras!.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;
      await _setupCamera(_cameras![_selectedCameraIndex]);
    } catch (e) {
      _showSnackbar('Gagal inisialisasi kamera: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    if (_controller != null) {
      await _controller!.stopImageStream().catchError((_) {});
      await _controller!.dispose();
      _controller = null;
    }

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
      await _controller!.startImageStream(_onCameraFrame);
    } catch (e) {
      _showSnackbar('Gagal akses kamera: $e');
    }
  }

  // ── Frame detection ───────────────────────────────────────────────────────
  void _onCameraFrame(CameraImage image) {
    if (_isDetecting || _isCapturing || !mounted) return;
    _isDetecting = true;
    _runFaceDetection(image);
  }

  Future<void> _runFaceDetection(CameraImage image) async {
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      final newStatus = _evaluateStatus(faces, image.width, image.height);
      _applyStatus(newStatus);
    } catch (_) {
      // Abaikan error per-frame untuk menghindari spam log
    } finally {
      _isDetecting = false;
    }
  }

  // Bangun InputImage dengan konversi NV21 yang benar (mempertimbangkan stride)
  InputImage? _buildInputImage(CameraImage image) {
    final camera = _cameras![_selectedCameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation rotation;
    if (Platform.isAndroid) {
      final rotDeg = camera.lensDirection == CameraLensDirection.front
          ? (360 - sensorOrientation) % 360
          : sensorOrientation;
      rotation = InputImageRotationValue.fromRawValue(rotDeg) ??
          InputImageRotation.rotation0deg;
    } else {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;
    }

    Uint8List bytes;
    InputImageFormat format;

    if (Platform.isAndroid) {
      // Konversi YUV_420_888 → NV21 dengan memperhatikan pixel stride & row stride
      bytes = _yuv420ToNv21(image);
      format = InputImageFormat.nv21;
    } else {
      bytes = image.planes.first.bytes;
      format = InputImageFormat.bgra8888;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Konversi YUV_420_888 (3 plane) → NV21 (Y + VU interleaved)
  /// Kompatibel dengan camera 0.12.x yang tidak menyediakan pixelStride.
  /// Menggunakan bytesPerRow untuk menangani padding pada setiap baris.
  Uint8List _yuv420ToNv21(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final width = image.width;
    final height = image.height;
    final nv21 = Uint8List(width * height * 3 ~/ 2);
    int idx = 0;

    // 1. Salin Y plane baris per baris, lewati padding di akhir baris
    for (int row = 0; row < height; row++) {
      final start = row * yPlane.bytesPerRow;
      for (int col = 0; col < width; col++) {
        nv21[idx++] = yPlane.bytes[start + col];
      }
    }

    // 2. Susun VU interleaved tanpa pixel stride
    //    Versi camera 0.12.x tidak mendukung pixelStride — baca langsung per byte
    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    for (int row = 0; row < uvHeight; row++) {
      final vRowStart = row * vPlane.bytesPerRow;
      final uRowStart = row * uPlane.bytesPerRow;
      for (int col = 0; col < uvWidth; col++) {
        nv21[idx++] = vPlane.bytes[vRowStart + col];
        nv21[idx++] = uPlane.bytes[uRowStart + col];
      }
    }

    return nv21;
  }

  // ── Evaluasi posisi wajah ─────────────────────────────────────────────────
  _FaceStatus _evaluateStatus(List<Face> faces, int imgWidth, int imgHeight) {
    if (faces.isEmpty) return _FaceStatus.noFace;
    if (faces.length > 1) return _FaceStatus.notCentered;

    final face = faces.first;
    final box = face.boundingBox;

    final faceWidthRatio = box.width / imgWidth;
    if (faceWidthRatio < 0.18) return _FaceStatus.tooFar;
    if (faceWidthRatio > 0.78) return _FaceStatus.tooClose;

    final offsetRatio = ((box.left + box.right) / 2 - imgWidth / 2).abs() / imgWidth;
    if (offsetRatio > 0.18) return _FaceStatus.notCentered;

    final headY = face.headEulerAngleY ?? 0;
    final headZ = face.headEulerAngleZ ?? 0;
    if (headY.abs() > 15 || headZ.abs() > 15) return _FaceStatus.notStraight;

    return _FaceStatus.ready;
  }

  void _applyStatus(_FaceStatus newStatus) {
    if (!mounted) return;
    setState(() => _faceStatus = newStatus);

    if (newStatus == _FaceStatus.ready) {
      _startCaptureProgress();
    } else {
      _stopCaptureProgress();
    }
  }

  // ── Progress otomatis ─────────────────────────────────────────────────────
  void _startCaptureProgress() {
    if (_captureTimer?.isActive == true) return;
    _captureTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _captureProgress = min(1.0, _captureProgress + 1 / 30));
      if (_captureProgress >= 1.0) {
        t.cancel();
        _autoCapture();
      }
    });
  }

  void _stopCaptureProgress() {
    _captureTimer?.cancel();
    _captureTimer = null;
    if (_captureProgress != 0 && mounted) {
      setState(() => _captureProgress = 0.0);
    }
  }

  // ── Ambil foto otomatis ───────────────────────────────────────────────────
  Future<void> _autoCapture() async {
    if (_isCapturing || !mounted) return;
    setState(() => _isCapturing = true);

    try {
      HapticFeedback.mediumImpact();
      await _controller!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 150));

      final XFile imageFile = await _controller!.takePicture();
      HapticFeedback.lightImpact();

      final bytes = await File(imageFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      try { await File(imageFile.path).delete(); } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context, base64Image);
    } catch (e) {
      _showSnackbar('Gagal mengambil foto: $e');
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _captureProgress = 0.0;
      });
      await _controller!.startImageStream(_onCameraFrame);
    }
  }

  // ── Ganti kamera ─────────────────────────────────────────────────────────
  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2 || _isCapturing) return;
    setState(() {
      _isCameraInitialized = false;
      _captureProgress = 0.0;
      _faceStatus = _FaceStatus.noFace;
    });
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _setupCamera(_cameras![_selectedCameraIndex]);
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _controller?.stopImageStream().catchError((_) {});
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // TIDAK gunakan SafeArea di sini — diurus di dalam overlay
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Lapisan 1: Preview kamera (Texture widget)
          _buildCameraPreview(),

          // Lapisan 2: Semua overlay dibungkus Material agar selalu muncul
          // di atas Texture walau menggunakan Impeller/Vulkan backend
          Material(
            type: MaterialType.transparency,
            child: SafeArea(child: _buildOverlay()),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Mempersiapkan kamera...',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return CameraPreview(_controller!);
  }

  Widget _buildOverlay() {
    final status = _faceStatus;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        return Stack(
          children: [
            // ── Oval + progress ring ──
            if (_isCameraInitialized)
              Positioned.fill(
                child: CustomPaint(
                  painter: _FaceOvalPainter(
                    progress: _captureProgress,
                    ovalColor: status.ovalColor,
                  ),
                ),
              ),

            // ── Tombol tutup & ganti kamera ──
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconButton(
                    Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  if (_cameras != null && _cameras!.length > 1)
                    _iconButton(
                      FluentIcons.camera_switch_24_regular,
                      onTap: _isCapturing ? null : _switchCamera,
                    ),
                ],
              ),
            ),

            // ── Instruksi live ──
            Positioned(
              top: size.height * 0.10,
              left: 24,
              right: 24,
              child: _buildInstructionBadge(status),
            ),

            // ── Indikator bawah ──
            if (!_isCapturing)
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: _buildBottomIndicator(status),
              ),

            // ── Loading saat capturing ──
            if (_isCapturing)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.greenAccent,
                    strokeWidth: 3,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionBadge(_FaceStatus status) {
    final isReady = status == _FaceStatus.ready;
    final text = _isCapturing ? 'Mengambil foto...' : status.message;
    final borderColor = isReady || _isCapturing
        ? Colors.greenAccent.withOpacity(0.7)
        : Colors.white24;
    final textColor = isReady || _isCapturing ? Colors.greenAccent : Colors.white;

    // Gunakan AnimatedContainer + AnimatedDefaultTextStyle,
    // bukan AnimatedSwitcher, untuk menghindari duplicate key error
    // saat setState dipanggil lebih cepat dari durasi transisi.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: TextStyle(
          color: textColor,
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildBottomIndicator(_FaceStatus status) {
    final isReady = status == _FaceStatus.ready;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isReady)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Otomatis memotret dalam sebentar...',
              style: TextStyle(
                color: Colors.greenAccent.withOpacity(0.9),
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
          ),
        Icon(
          isReady ? Icons.face_retouching_natural : Icons.face,
          color: isReady ? Colors.greenAccent : Colors.white38,
          size: 28,
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, {VoidCallback? onTap}) {
    return CircleAvatar(
      backgroundColor: Colors.black54,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}

// ── Custom Painter: Overlay + Oval + Progress Ring ───────────────────────────
class _FaceOvalPainter extends CustomPainter {
  final double progress;
  final Color ovalColor;

  const _FaceOvalPainter({required this.progress, required this.ovalColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final ovalWidth = size.width * 0.68;
    final ovalHeight = ovalWidth * 1.35;
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // 1. Overlay gelap dengan lubang oval (cutout effect)
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addOval(ovalRect);
    final maskPath = Path.combine(PathOperation.difference, bgPath, holePath);
    canvas.drawPath(
      maskPath,
      Paint()
        ..color = Colors.black.withOpacity(0.62)
        ..style = PaintingStyle.fill,
    );

    // 2. Border oval berubah warna sesuai status
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = ovalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 3. Progress arc hijau
    if (progress > 0) {
      canvas.drawArc(
        ovalRect.inflate(3),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = Colors.greenAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FaceOvalPainter old) =>
      old.progress != progress || old.ovalColor != ovalColor;
}
