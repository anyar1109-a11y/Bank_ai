import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../models/user_data.dart';
import '../services/verification_history_service.dart';
import '../services/activity_service.dart';
import '../services/location_service.dart';
import '../utils/datetime_format.dart';
import 'face_history_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _locationService = LocationService();

  // Live GPS state
  String _liveLatitude = '';
  String _liveLongitude = '';
  String _liveAddress = '';
  bool _gpsActive = false;
  bool _isLoadingLocation = false;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<ServiceStatus>? _serviceSub;

  @override
  void initState() {
    super.initState();
    _startLiveLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _serviceSub?.cancel();
    super.dispose();
  }

  Future<void> _startLiveLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsActive = false;
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() {
          _gpsActive = false;
          _isLoadingLocation = false;
        });
        return;
      }

      // Ambil posisi awal
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _updatePosition(pos);

      // Subscribe stream live
      _positionSub = _locationService.getPositionStream().listen(
        (p) => _updatePosition(p),
        onError: (_) {},
      );

      // Monitor status GPS service
      _serviceSub = _locationService.getGpsServiceStream().listen((status) {
        if (!mounted) return;
        setState(() => _gpsActive = status == ServiceStatus.enabled);
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _updatePosition(Position pos) async {
    if (!mounted) return;
    final lat = pos.latitude.toStringAsFixed(6);
    final lng = pos.longitude.toStringAsFixed(6);

    setState(() {
      _liveLatitude = lat;
      _liveLongitude = lng;
      _gpsActive = true;
      _isLoadingLocation = false;
    });

    // Simpan ke UserData agar tersinkron
    UserData.latitude = lat;
    UserData.longitude = lng;

    // Reverse geocoding
    try {
      final addr = await _locationService.getAddressFromCoordinates(
          pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _liveAddress = addr);
      UserData.address = addr;
    } catch (_) {}
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _liveAddress = '';
    });
    await _startLiveLocation();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final lastRecord = VerificationHistoryService.lastRecord;
    final nama = UserData.nama.isNotEmpty ? UserData.nama : 'Nasabah SmartBank';
    final initials = _initials(nama);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        children: [
          // ── Profile header ─────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        UserData.email.isNotEmpty ? UserData.email : '-',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Terverifikasi',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Account stats ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _statCard('Rp 25 Jt', 'Total Saldo', Icons.account_balance_wallet_rounded, AppColors.transfer)),
                const SizedBox(width: 12),
                Expanded(child: _statCard(
                  ActivityService.transactions.length.toString(),
                  'Transaksi',
                  Icons.receipt_long_rounded,
                  AppColors.topup,
                )),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Aktif', 'Status', Icons.verified_user_rounded, AppColors.success)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Data Pribadi ───────────────────────────────────────────────────
          _sectionTitle('Data Pribadi'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  _infoTile(Icons.email_outlined, 'Email', UserData.email.isNotEmpty ? UserData.email : '-', isFirst: true),
                  _infoTile(Icons.phone_outlined, 'Nomor HP', UserData.phone.isNotEmpty ? UserData.phone : '-'),
                  _infoTile(Icons.badge_outlined, 'NIK', UserData.nik.isNotEmpty ? UserData.nik : '-'),

                  // ── Live Koordinat GPS ────────────────────────────────────
                  _liveLocationTile(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Foto KTP ───────────────────────────────────────────────────────
          _sectionTitle('Foto KTP'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.all(16),
              child: UserData.ktpImageFile == null && UserData.ktpImagePath.isEmpty
                  ? Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: AppColors.textHint.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.credit_card_outlined,
                              color: AppColors.textHint, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Foto KTP belum diunggah',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Upload foto KTP saat registrasi',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label & badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.credit_card_rounded,
                                    color: AppColors.primary, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Kartu Tanda Penduduk',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded,
                                      color: AppColors.success, size: 13),
                                  SizedBox(width: 4),
                                  Text('Terverifikasi',
                                      style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Foto KTP preview
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 190,
                            child: kIsWeb
                                ? (UserData.ktpImageFile != null
                                    ? Image.network(
                                        UserData.ktpImageFile!.path,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _ktpPlaceholder(),
                                      )
                                    : _ktpPlaceholder())
                                : (UserData.ktpImagePath.isNotEmpty
                                    ? Image.file(
                                        File(UserData.ktpImagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _ktpPlaceholder(),
                                      )
                                    : _ktpPlaceholder()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Diunggah saat pendaftaran akun',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Verifikasi Wajah ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Verifikasi Wajah',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceHistoryScreen())),
                      child: const Text('Lihat riwayat →',
                          style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: lastRecord == null
                      ? Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AppColors.textHint.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.face_outlined, color: AppColors.textHint, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Belum ada verifikasi', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Lakukan verifikasi wajah untuk keamanan', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          )),
                        ])
                      : Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: lastRecord.success ? AppColors.successBg : AppColors.errorBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              lastRecord.success ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                              color: lastRecord.success ? AppColors.success : AppColors.error,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastRecord.success ? 'Verifikasi Berhasil' : 'Verifikasi Gagal',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(formatTimestamp(lastRecord.timestamp),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: lastRecord.success ? AppColors.successBg : AppColors.errorBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              lastRecord.success ? 'Sukses' : 'Gagal',
                              style: TextStyle(
                                color: lastRecord.success ? AppColors.success : AppColors.error,
                                fontSize: 12, fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Pengaturan ─────────────────────────────────────────────────────
          _sectionTitle('Pengaturan'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  _menuTile(
                    context,
                    Icons.security_rounded,
                    'Keamanan Akun',
                    'PIN, biometrik, verifikasi wajah',
                    color: AppColors.primary,
                    isFirst: true,
                    onTap: () => _showKeamananSheet(context),
                  ),
                  _menuTile(
                    context,
                    Icons.notifications_outlined,
                    'Notifikasi',
                    'Atur preferensi notifikasi',
                    color: AppColors.warning,
                    onTap: () => _showNotifikasiSheet(context),
                  ),
                  _menuTile(
                    context,
                    Icons.help_outline_rounded,
                    'Bantuan',
                    'Hubungi customer service',
                    color: AppColors.topup,
                    onTap: () => _showBantuanSheet(context),
                  ),
                  _menuTile(
                    context,
                    Icons.logout_rounded,
                    'Keluar',
                    'Keluar dari akun',
                    color: AppColors.error,
                    isLast: true,
                    onTap: () => _konfirmasiKeluar(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── KEAMANAN AKUN ──────────────────────────────────────────────────────────
  void _showKeamananSheet(BuildContext context) {
    bool _pinAktif = true;
    bool _biometrikAktif = false;
    bool _verifikasiWajah = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Keamanan Akun', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 20),

              // PIN
              _toggleTile(
                icon: Icons.pin_outlined,
                title: 'PIN Transaksi',
                subtitle: 'Wajib PIN untuk setiap transaksi',
                color: AppColors.primary,
                value: _pinAktif,
                onChanged: (v) => setSheet(() => _pinAktif = v),
              ),
              const Divider(height: 1, indent: 52, color: AppColors.divider),

              // Biometrik
              _toggleTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometrik',
                subtitle: 'Login menggunakan sidik jari / Face ID',
                color: AppColors.topup,
                value: _biometrikAktif,
                onChanged: (v) => setSheet(() => _biometrikAktif = v),
              ),
              const Divider(height: 1, indent: 52, color: AppColors.divider),

              // Verifikasi Wajah
              _toggleTile(
                icon: Icons.face_retouching_natural_rounded,
                title: 'Verifikasi Wajah',
                subtitle: 'Scan wajah saat login & transaksi besar',
                color: AppColors.history,
                value: _verifikasiWajah,
                onChanged: (v) => setSheet(() => _verifikasiWajah = v),
              ),
              const SizedBox(height: 16),

              // Ganti PIN
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showGantiPinDialog(context);
                },
                icon: const Icon(Icons.lock_reset_rounded, size: 18),
                label: const Text('Ganti PIN'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGantiPinDialog(BuildContext context) {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ganti PIN', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: 'PIN Lama', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: 'PIN Baru', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: 'Konfirmasi PIN Baru', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN berhasil diubah'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(16)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ── NOTIFIKASI ─────────────────────────────────────────────────────────────
  void _showNotifikasiSheet(BuildContext context) {
    bool _transaksi = true;
    bool _promo = false;
    bool _keamanan = true;
    bool _update = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.notifications_outlined, color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Notifikasi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 8),
              const Text('Pilih notifikasi yang ingin Anda terima', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),

              _toggleTile(icon: Icons.swap_horiz_rounded, title: 'Transaksi', subtitle: 'Transfer, QRIS, Top Up masuk & keluar', color: AppColors.transfer, value: _transaksi, onChanged: (v) => setSheet(() => _transaksi = v)),
              const Divider(height: 1, indent: 52, color: AppColors.divider),
              _toggleTile(icon: Icons.local_offer_outlined, title: 'Promo & Penawaran', subtitle: 'Cashback, diskon, dan program loyalty', color: AppColors.qris, value: _promo, onChanged: (v) => setSheet(() => _promo = v)),
              const Divider(height: 1, indent: 52, color: AppColors.divider),
              _toggleTile(icon: Icons.shield_outlined, title: 'Keamanan', subtitle: 'Login baru, perubahan akun, dan peringatan', color: AppColors.error, value: _keamanan, onChanged: (v) => setSheet(() => _keamanan = v)),
              const Divider(height: 1, indent: 52, color: AppColors.divider),
              _toggleTile(icon: Icons.system_update_outlined, title: 'Update Aplikasi', subtitle: 'Info versi terbaru dan fitur baru', color: AppColors.topup, value: _update, onChanged: (v) => setSheet(() => _update = v)),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengaturan notifikasi disimpan'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(16)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Simpan Pengaturan', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BANTUAN ────────────────────────────────────────────────────────────────
  void _showBantuanSheet(BuildContext context) {
    final faqList = [
      {'q': 'Bagaimana cara transfer antar bank?', 'a': 'Buka menu Transfer → pilih bank tujuan → masukkan nomor rekening dan nominal → tekan Konfirmasi.'},
      {'q': 'Transaksi saya gagal, apa yang harus dilakukan?', 'a': 'Periksa koneksi internet dan saldo Anda. Jika masalah berlanjut, hubungi CS kami di 1500-XXX.'},
      {'q': 'Bagaimana cara mengaktifkan biometrik?', 'a': 'Buka Profil → Keamanan Akun → aktifkan toggle Biometrik.'},
      {'q': 'Apakah QRIS bisa digunakan di semua merchant?', 'a': 'Ya, QRIS SmartBank dapat digunakan di semua merchant yang mendukung pembayaran QRIS nasional.'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.topup.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.help_outline_rounded, color: AppColors.topup, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Bantuan & FAQ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 16),

              // Kontak CS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Service 24 Jam', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Hubungi kami kapan saja', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    )),
                    Text('1500-XXX', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Pertanyaan Umum', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              ...faqList.map((item) => _faqItem(item['q']!, item['a']!)).toList(),

              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Chat dengan CS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.topup,
                  side: const BorderSide(color: AppColors.topup),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faqItem(String q, String a) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Text(q, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textHint,
        children: [
          Text(a, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  // ── KELUAR ─────────────────────────────────────────────────────────────────
  void _konfirmasiKeluar(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
          SizedBox(width: 10),
          Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        ]),
        content: const Text('Apakah Anda yakin ingin keluar dari akun SmartBank?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              // Reset data sesi
              ActivityService.activities.clear();
              ActivityService.transactions.clear();
              UserData.nama = '';
              UserData.email = '';
              UserData.phone = '';
              UserData.nik = '';
              UserData.latitude = '';
              UserData.longitude = '';
              UserData.address = '';

              // Navigasi ke login dan hapus semua route sebelumnya
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        )),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ]),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      {bool isFirst = false, bool isLast = false}) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          )),
        ]),
      ),
      if (!isLast) const Divider(height: 1, indent: 50, color: AppColors.divider),
    ]);
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    required Color color,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(18) : Radius.zero,
          bottom: isLast ? const Radius.circular(18) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isLast ? AppColors.error : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            )),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ]),
        ),
      ),
      if (!isLast) const Divider(height: 1, indent: 68, color: AppColors.divider),
    ]);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return 'U';
  }


  // ── Live GPS Tile ────────────────────────────────────────────────────────
  Widget _liveLocationTile() {
    final hasCoord = _liveLatitude.isNotEmpty && _liveLongitude.isNotEmpty;

    return Column(
      children: [
        const Divider(height: 1, indent: 50, color: AppColors.divider),
        // Baris Koordinat
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (_gpsActive ? AppColors.success : AppColors.textHint).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _gpsActive ? Icons.gps_fixed : Icons.gps_off,
                  color: _gpsActive ? AppColors.success : AppColors.textHint,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Koordinat',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 6),
                        if (_gpsActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(6)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: Colors.white, size: 6),
                                SizedBox(width: 3),
                                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _isLoadingLocation
                        ? const Row(children: [
                            SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                            ),
                            SizedBox(width: 8),
                            Text('Mengambil lokasi...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ])
                        : Text(
                            hasCoord ? '$_liveLatitude, $_liveLongitude' : 'Lokasi tidak tersedia',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: hasCoord ? AppColors.textPrimary : AppColors.textHint,
                            ),
                          ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _isLoadingLocation ? null : _refreshLocation,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isLoadingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 18),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, indent: 50, color: AppColors.divider),

        // Baris Alamat
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alamat',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    (_isLoadingLocation && _liveAddress.isEmpty)
                        ? const Row(children: [
                            SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                            ),
                            SizedBox(width: 8),
                            Text('Mencari alamat...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ])
                        : Text(
                            _liveAddress.isNotEmpty ? _liveAddress : 'Alamat tidak tersedia',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _liveAddress.isNotEmpty ? AppColors.textPrimary : AppColors.textHint,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _ktpPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_outlined,
              color: AppColors.textHint, size: 40),
          const SizedBox(height: 8),
          Text('Foto tidak tersedia',
              style: TextStyle(color: AppColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }
}
