import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../models/user_data.dart';
import '../services/location_service.dart';
import 'liveness_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _currentStep = 0;

  // Step 2 - KTP
  XFile? _ktpImageFile;
  final ImagePicker _picker = ImagePicker();

  static const _stepLabels = [
    'Langkah 1: Data Diri',
    'Langkah 2: Foto KTP',
    'Langkah 3: Verifikasi Wajah',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_currentStep > 0) {
                            setState(() => _currentStep--);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Buat Akun',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Step bar
                  Row(
                    children: List.generate(3, (i) {
                      final isActive = i <= _currentStep;
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
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
                  const SizedBox(height: 10),
                  Text(
                    _stepLabels[_currentStep],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 0
                    ? _buildStep1()
                    : _currentStep == 1
                        ? _buildStep2()
                        : _buildStep3(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 1: Data Diri ────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Nama Lengkap'),
          const SizedBox(height: 8),
          _textField(_nameController, 'Masukkan nama lengkap',
              Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _fieldLabel('Email'),
          const SizedBox(height: 8),
          _textField(_emailController, 'Masukkan email aktif',
              Icons.email_outlined,
              type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _fieldLabel('Nomor HP'),
          const SizedBox(height: 8),
          _textField(_phoneController, '08xx-xxxx-xxxx',
              Icons.phone_outlined,
              type: TextInputType.phone),
          const SizedBox(height: 16),
          _fieldLabel('NIK (KTP)'),
          const SizedBox(height: 8),
          _textField(_nikController, '16 digit nomor KTP',
              Icons.badge_outlined,
              type: TextInputType.number),
          const SizedBox(height: 16),
          _fieldLabel('Password'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Minimal 8 karakter',
              hintStyle: const TextStyle(color: AppColors.textHint),
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.textHint, size: 20),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _validateStep1,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Lanjut',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Sudah punya akun? Masuk',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: Foto KTP ─────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruksi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.15), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pastikan foto KTP terlihat jelas, tidak buram, dan semua teks terbaca.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Area foto KTP
          GestureDetector(
            onTap: _pickKtpImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              height: 210,
              decoration: BoxDecoration(
                color: _ktpImageFile == null
                    ? AppColors.surfaceVariant
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _ktpImageFile == null
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.primary,
                  width: _ktpImageFile == null ? 1.5 : 2,
                  style: _ktpImageFile == null
                      ? BorderStyle.solid
                      : BorderStyle.solid,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _ktpImageFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.primary, size: 30),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tap untuk upload foto KTP',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG — maks. 5 MB',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        // Preview gambar
                        kIsWeb
                            ? Image.network(
                                _ktpImageFile!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_ktpImageFile!.path),
                                fit: BoxFit.cover,
                              ),
                        // Overlay tombol ganti
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.55),
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Ganti Foto',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Badge sukses
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded,
                                    color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Foto dipilih',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Pilihan sumber foto
          Row(
            children: [
              Expanded(
                child: _sourceButton(
                  Icons.photo_library_outlined,
                  'Galeri',
                  () => _pickKtpImage(fromCamera: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sourceButton(
                  Icons.camera_alt_outlined,
                  'Kamera',
                  () => _pickKtpImage(fromCamera: true),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _ktpImageFile == null ? null : _handleSaveKtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.divider,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Lanjut ke Verifikasi Wajah',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 3: Verifikasi Wajah ─────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ilustrasi
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.12), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.face_retouching_natural_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Siap Verifikasi Wajah',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kamera akan dibuka untuk scan wajah Anda',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Checklist info
          _checkItem('Pastikan wajah terlihat jelas & pencahayaan cukup'),
          _checkItem('Lepas kacamata atau aksesori yang menutupi wajah'),
          _checkItem('Hadap langsung ke kamera, jangan miring'),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleGoToFaceDetection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.camera_front_rounded, size: 20),
              label: Text(
                _isLoading ? 'Memproses...' : 'Mulai Verifikasi Wajah',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _checkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label,
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Future<void> _pickKtpImage({bool fromCamera = false}) async {
    final XFile? file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) setState(() => _ktpImageFile = file);
  }

  void _validateStep1() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Mohon isi semua field yang wajib diisi');
      return;
    }
    setState(() => _currentStep = 1);
  }

  void _handleSaveKtp() {
    // Simpan ke UserData agar bisa ditampilkan di profil
    UserData.ktpImagePath = _ktpImageFile!.path;
    UserData.ktpImageFile = _ktpImageFile;
    setState(() => _currentStep = 2);
  }

  void _handleGoToFaceDetection() async {
    setState(() => _isLoading = true);

    _authService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _passwordController.text,
      _nikController.text.trim(),
    );

    UserData.nama = _nameController.text.trim();
    UserData.email = _emailController.text.trim();
    UserData.phone = _phoneController.text.trim();
    UserData.nik = _nikController.text.trim();

    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LivenessScreen()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );

  Widget _textField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
