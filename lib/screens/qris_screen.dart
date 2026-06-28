import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import '../services/activity_service.dart';

// ── Halaman kamera QRIS (tampilan kamera asli, auto-close 3 detik) ──────────
class QrisCameraScreen extends StatefulWidget {
  const QrisCameraScreen({super.key});
  @override
  State<QrisCameraScreen> createState() => _QrisCameraScreenState();
}

class _QrisCameraScreenState extends State<QrisCameraScreen> {
  CameraController? _controller;
  bool _initialized = false;
  bool _closing = false;
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) Navigator.pop(context, null);
        return;
      }
      // Pilih kamera belakang
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(back, ResolutionPreset.high,
          enableAudio: false);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _initialized = true);
      _startCountdown();
    } catch (e) {
      if (mounted) Navigator.pop(context, null);
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _closeCamera();
      }
    });
  }

  Future<void> _closeCamera() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    await _controller?.dispose();
    if (mounted) Navigator.pop(context, 'scanned');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pratinjau kamera
          if (_initialized && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Overlay sudut scanner
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  // garis sudut kiri atas
                  Positioned(top: 0, left: 0, child: _corner(true, true)),
                  // kanan atas
                  Positioned(top: 0, right: 0, child: _corner(false, true)),
                  // kiri bawah
                  Positioned(bottom: 0, left: 0, child: _corner(true, false)),
                  // kanan bawah
                  Positioned(bottom: 0, right: 0, child: _corner(false, false)),
                ],
              ),
            ),
          ),

          // Label atas
          const Positioned(
            top: 60,
            left: 0, right: 0,
            child: Text(
              'Scan Kode QRIS',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),

          // Petunjuk bawah
          const Positioned(
            top: 90,
            left: 0, right: 0,
            child: Text(
              'Arahkan kamera ke kode QR merchant',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),

          // Countdown
          if (_initialized)
            Positioned(
              bottom: 120,
              left: 0, right: 0,
              child: Column(
                children: [
                  Text(
                    'Kamera akan menutup dalam',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Tombol tutup manual
          Positioned(
            bottom: 48,
            left: 0, right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: _closeCamera,
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text('Tutup Kamera',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner(bool isLeft, bool isTop) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          left: isLeft
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          top: isTop
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}

// ── Halaman QRIS utama ───────────────────────────────────────────────────────
class QrisScreen extends StatefulWidget {
  const QrisScreen({super.key});
  @override
  State<QrisScreen> createState() => _QrisScreenState();
}

class _QrisScreenState extends State<QrisScreen> {
  String? _activeMenu;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _menus = [
    {
      'icon': Icons.qr_code_scanner,
      'title': 'Bayar dengan QRIS',
      'desc': 'Scan kode QR untuk membayar',
      'color': AppColors.primary,
    },
    {
      'icon': Icons.qr_code_2,
      'title': 'Buat Kode QRIS',
      'desc': 'Tampilkan QRIS untuk menerima pembayaran',
      'color': Color(0xFF0F6E56),
    },
    {
      'icon': Icons.history,
      'title': 'Riwayat QRIS',
      'desc': 'Lihat semua transaksi QRIS',
      'color': Color(0xFF533AB7),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_activeMenu ?? 'QRIS'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: _activeMenu != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _activeMenu = null),
              )
            : null,
      ),
      body: _activeMenu == null
          ? _buildMenuList()
          : _activeMenu == 'Bayar dengan QRIS'
              ? _buildScanPage()
              : _activeMenu == 'Buat Kode QRIS'
                  ? _buildMyQris()
                  : _buildRiwayat(),
    );
  }

  Widget _buildMenuList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Pilih layanan QRIS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        ..._menus.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (m['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(m['icon'] as IconData, color: m['color'] as Color),
                ),
                title: Text(m['title'],
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(m['desc'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  ActivityService.addActivity('${m['title']} Dibuka');
                  setState(() => _activeMenu = m['title']);
                },
              ),
            )),
      ],
    );
  }

  // ── Bayar dengan QRIS ──────────────────────────────────────────────────────
  Widget _buildScanPage() {
    final merchantCtrl = TextEditingController();
    final nominalCtrl = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Preview area (dekoratif)
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.qr_code_scanner,
                    size: 80, color: AppColors.primary),
                ...[
                  [0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [1.0, 1.0]
                ].map((pos) => Positioned(
                      left: pos[0] == 0 ? 12 : null,
                      right: pos[0] == 1 ? 12 : null,
                      top: pos[1] == 0 ? 12 : null,
                      bottom: pos[1] == 1 ? 12 : null,
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            left: pos[0] == 0
                                ? const BorderSide(color: AppColors.primary, width: 3)
                                : BorderSide.none,
                            right: pos[0] == 1
                                ? const BorderSide(color: AppColors.primary, width: 3)
                                : BorderSide.none,
                            top: pos[1] == 0
                                ? const BorderSide(color: AppColors.primary, width: 3)
                                : BorderSide.none,
                            bottom: pos[1] == 1
                                ? const BorderSide(color: AppColors.primary, width: 3)
                                : BorderSide.none,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Arahkan kamera ke kode QR merchant',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 20),

          // Tombol Buka Kamera — pakai camera plugin (tampilan kamera asli)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('Buka Kamera Scan',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              onPressed: () async {
                ActivityService.addActivity('Buka Kamera QRIS');
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const QrisCameraScreen()),
                );
                if (result == 'scanned' && mounted) {
                  _showQrisPaymentDialog(context, 'Merchant QR', '');
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Upload dari Galeri
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.image, color: AppColors.primary),
              label: const Text('Upload dari Galeri',
                  style: TextStyle(color: AppColors.primary, fontSize: 15)),
              onPressed: () async {
                ActivityService.addActivity('Upload QRIS dari Galeri');
                try {
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null && mounted) {
                    _showQrisPaymentDialog(context, 'Merchant QR', '');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal membuka galeri: $e')),
                    );
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Atau masukkan detail manual',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: merchantCtrl,
            decoration: InputDecoration(
              hintText: 'Nama merchant',
              prefixIcon: const Icon(Icons.store),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nominalCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              prefixText: 'Rp ',
              prefixIcon: const Icon(Icons.attach_money),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6E56),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (nominalCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Masukkan nominal')),
                  );
                  return;
                }
                _showQrisPaymentDialog(
                    context,
                    merchantCtrl.text.isNotEmpty
                        ? merchantCtrl.text
                        : 'Merchant',
                    nominalCtrl.text);
              },
              child: const Text('Bayar Sekarang',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showQrisPaymentDialog(
      BuildContext context, String merchant, String nominal) {
    final nominalCtrl2 = TextEditingController(text: nominal);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.qr_code_2, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Konfirmasi Pembayaran'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.store, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(merchant,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nominalCtrl2,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final raw = nominalCtrl2.text.replaceAll('.', '');
              final fmt = _formatNominal(raw);
              ActivityService.addTransaction(TransactionRecord(
                type: 'qris',
                title: 'Bayar QRIS',
                nominal: fmt,
                target: merchant,
                time: DateTime.now(),
              ));
              _showQrisSuccess(context, merchant, fmt);
            },
            child: const Text('Bayar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQrisSuccess(
      BuildContext context, String merchant, String nominal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 56),
            ),
            const SizedBox(height: 16),
            const Text('Pembayaran Berhasil!',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Rp $nominal',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('ke $merchant',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _activeMenu = 'Riwayat QRIS');
              },
              child: const Text('Lihat Riwayat',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _activeMenu = null);
            },
            child: const Text('Kembali ke Menu'),
          ),
        ],
      ),
    );
  }

  // ── Buat Kode QRIS ─────────────────────────────────────────────────────────
  Widget _buildMyQris() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 16),
        const Text('Kode QRIS Anda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Tunjukkan kepada pembayar untuk menerima dana',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: [
            const SizedBox(
              width: 200, height: 200,
              child: Icon(Icons.qr_code_2, size: 180, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            const Text('SmartBank · Nasabah SmartBank',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('Rek. 1234-5678-9012',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 24),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Nominal (kosongkan jika bebas)',
            prefixText: 'Rp ',
            prefixIcon: const Icon(Icons.attach_money),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.share, color: AppColors.primary),
              label: const Text('Bagikan',
                  style: TextStyle(color: AppColors.primary)),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text('Simpan',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {},
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Riwayat QRIS ───────────────────────────────────────────────────────────
  Widget _buildRiwayat() {
    final riwayat = ActivityService.getByType('qris');
    if (riwayat.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text('Belum ada riwayat QRIS',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: riwayat.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = riwayat[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF533AB7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.qr_code_2, color: Color(0xFF533AB7)),
            ),
            title: Text(t.target ?? t.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(_formatTime(t.time),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t.nominal != null ? 'Rp ${t.nominal}' : '-',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Berhasil',
                      style: TextStyle(
                          color: Colors.green.shade700, fontSize: 11)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatNominal(String raw) {
    final number = int.tryParse(raw) ?? 0;
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
