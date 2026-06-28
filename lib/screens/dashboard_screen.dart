import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/activity_service.dart';
import '../services/balance_service.dart';
import '../models/user_data.dart';
import 'activity_screen.dart';
import 'profile_screen.dart';
import 'face_history_screen.dart';
import 'transfer_screen.dart';
import 'qris_screen.dart';
import 'topup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _balanceVisible = true;

  @override
  void initState() {
    super.initState();
    ActivityService.addActivity('Login Berhasil');
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomePage(
        balanceVisible: _balanceVisible,
        onToggleBalance: () => setState(() => _balanceVisible = !_balanceVisible),
      ),
      const ActivityScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Aktivitas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePage extends StatefulWidget {
  final bool balanceVisible;
  final VoidCallback onToggleBalance;

  const _HomePage({
    required this.balanceVisible,
    required this.onToggleBalance,
  });

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  bool get balanceVisible => widget.balanceVisible;
  VoidCallback get onToggleBalance => widget.onToggleBalance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh tampilan saat kembali dari layar lain
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with gradient ───────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    // Top bar: greeting + notification
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat datang 👋',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                UserData.nama.isNotEmpty
                                    ? UserData.nama
                                    : 'Nasabah SmartBank',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 26),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5252),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Balance card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Saldo Rekening',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: onToggleBalance,
                                child: Icon(
                                  balanceVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            balanceVisible ? BalanceService.formattedBalance : 'Rp ••••••••',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '1234-5678-9012',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.copy_outlined,
                                          size: 13, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Salin',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Quick action buttons ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _quickAction(
                      context,
                      icon: Icons.send_rounded,
                      label: 'Transfer',
                      color: AppColors.transfer,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const TransferScreen()))
                          .then((_) => setState(() {})),
                    ),
                    _quickAction(
                      context,
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'QRIS',
                      color: AppColors.qris,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const QrisScreen()))
                          .then((_) => setState(() {})),
                    ),
                    _quickAction(
                      context,
                      icon: Icons.add_card_rounded,
                      label: 'Top Up',
                      color: AppColors.topup,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const TopUpScreen()))
                          .then((_) => setState(() {})),
                    ),
                    _quickAction(
                      context,
                      icon: Icons.receipt_long_rounded,
                      label: 'Mutasi',
                      color: AppColors.mutasi,
                      onTap: () {
                        ActivityService.addActivity('Mutasi Dibuka');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Mutasi segera hadir'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                    ),
                    _quickAction(
                      context,
                      icon: Icons.face_retouching_natural_rounded,
                      label: 'Wajah',
                      color: AppColors.history,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FaceHistoryScreen())),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Promo banner ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7C3AED),
                        const Color(0xFF4F46E5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PROMO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Cashback 20%\nTransfer Perdana!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Klaim Sekarang',
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_offer_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Recent transactions header ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaksi Terbaru',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Transaction list — hanya tampil jika ada transaksi nyata
                Builder(builder: (context) {
                  final txList = ActivityService.transactions.take(5).toList();
                  if (txList.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Transaksi akan muncul setelah\nAnda melakukan Transfer, QRIS, atau Top Up',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: List.generate(txList.length, (i) {
                        final tx = txList[i];
                        final isLast = i == txList.length - 1;

                        IconData icon;
                        Color iconColor;
                        Color iconBg;

                        switch (tx.type) {
                          case 'transfer':
                            icon = Icons.send_rounded;
                            iconColor = AppColors.transfer;
                            iconBg = AppColors.transfer.withOpacity(0.1);
                            break;
                          case 'topup':
                            icon = Icons.add_card_rounded;
                            iconColor = AppColors.topup;
                            iconBg = AppColors.topup.withOpacity(0.1);
                            break;
                          case 'qris':
                            icon = Icons.qr_code_rounded;
                            iconColor = AppColors.qris;
                            iconBg = AppColors.qris.withOpacity(0.1);
                            break;
                          default:
                            icon = Icons.swap_horiz_rounded;
                            iconColor = AppColors.primary;
                            iconBg = AppColors.primary.withOpacity(0.1);
                        }

                        final jam = '${tx.time.hour.toString().padLeft(2,'0')}:${tx.time.minute.toString().padLeft(2,'0')}';
                        final subtitle = tx.target != null
                            ? '${tx.target} • $jam'
                            : jam;

                        return _transactionItem(
                          icon: icon,
                          iconBg: iconBg,
                          iconColor: iconColor,
                          title: tx.title,
                          subtitle: subtitle,
                          amount: '-${tx.nominal ?? ''}',
                          isDebit: true,
                          isLast: isLast,
                        );
                      }),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required bool isDebit,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDebit ? AppColors.textPrimary : AppColors.success,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 72,
            color: AppColors.divider,
          ),
      ],
    );
  }
}
