import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/activity_service.dart';
import '../services/balance_service.dart';

// ─── Main Screen ────────────────────────────────────────────────────────────

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});
  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  String? _activeMenu;

  final List<Map<String, dynamic>> _menus = [
    {
      'icon': Icons.savings_rounded,
      'title': 'Top Up Saldo Rekening',
      'desc': 'Tambah saldo dari sumber luar (ATM, setor tunai, dll)',
      'color': Color(0xFF059669),
      'isCredit': true,
    },
    {
      'icon': Icons.account_balance_wallet_rounded,
      'title': 'Top Up E-Wallet',
      'desc': 'GoPay, OVO, Dana, ShopeePay, dll',
      'color': AppColors.transfer,
      'isCredit': false,
    },
    {
      'icon': Icons.phone_android_rounded,
      'title': 'Top Up Pulsa',
      'desc': 'Pulsa untuk semua operator',
      'color': AppColors.topup,
      'isCredit': false,
    },
    {
      'icon': Icons.wifi_rounded,
      'title': 'Top Up Paket Data',
      'desc': 'Beli paket internet hemat',
      'color': AppColors.warning,
      'isCredit': false,
    },
    {
      'icon': Icons.videogame_asset_rounded,
      'title': 'Top Up Game',
      'desc': 'Mobile Legends, Free Fire, PUBG, dll',
      'color': AppColors.history,
      'isCredit': false,
    },
    {
      'icon': Icons.history_rounded,
      'title': 'Riwayat Top Up',
      'desc': 'Lihat semua riwayat top up',
      'color': AppColors.qris,
      'isCredit': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _activeMenu != null
                                ? () => setState(() => _activeMenu = null)
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                          ),
                          Text(
                            _activeMenu ?? 'Top Up',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (_activeMenu == null) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Saldo Rekening',
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12)),
                                    Text(BalanceService.formattedBalance,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: _activeMenu == null
                  ? _buildMenuList()
                  : _activeMenu == 'Riwayat Top Up'
                      ? _buildRiwayat()
                      : _activeMenu == 'Top Up Saldo Rekening'
                          ? _FormSaldoRekening(onDone: () => setState(() => _activeMenu = null))
                          : _FormDebit(
                              menuTitle: _activeMenu!,
                              onDone: () => setState(() => _activeMenu = null),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Isi Saldo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              )),
        ),
        _menuCard(_menus[0]),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 10),
          child: Text('Bayar dari Rekening',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              )),
        ),
        ..._menus.skip(1).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _menuCard(m),
            )),
      ],
    );
  }

  Widget _menuCard(Map<String, dynamic> m) {
    final bool isCredit = m['isCredit'] as bool;
    return GestureDetector(
      onTap: () => setState(() => _activeMenu = m['title']),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isCredit
              ? Border.all(color: const Color(0xFF059669).withOpacity(0.3), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (m['color'] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(m['title'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                      ),
                      if (isCredit) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('+ SALDO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              )),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(m['desc'],
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayat() {
    final txList = ActivityService.getByType('topup').take(10).toList();
    if (txList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('Belum ada riwayat top up',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: txList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final tx = txList[i];
        final isCredit = tx.title == 'Top Up Saldo Rekening';
        final jam =
            '${tx.time.hour.toString().padLeft(2, '0')}:${tx.time.minute.toString().padLeft(2, '0')}';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isCredit ? const Color(0xFF059669) : AppColors.topup)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCredit ? Icons.savings_rounded : Icons.add_card_rounded,
                  color: isCredit ? const Color(0xFF059669) : AppColors.topup,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    Text('${tx.target ?? ''} • $jam',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(
                isCredit ? '+${tx.nominal ?? ''}' : '-${tx.nominal ?? ''}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isCredit ? const Color(0xFF059669) : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Form Top Up Saldo Rekening (CREDIT) ────────────────────────────────────

class _FormSaldoRekening extends StatefulWidget {
  final VoidCallback onDone;
  const _FormSaldoRekening({required this.onDone});
  @override
  State<_FormSaldoRekening> createState() => _FormSaldoRekeningState();
}

class _FormSaldoRekeningState extends State<_FormSaldoRekening> {
  final _nominalController = TextEditingController();
  final _sumberController = TextEditingController();
  String? _selected;

  final List<String> _nominals = [
    '50.000', '100.000', '200.000', '500.000', '1.000.000', '5.000.000'
  ];

  @override
  void dispose() {
    _nominalController.dispose();
    _sumberController.dispose();
    super.dispose();
  }

  void _pilihNominal(String val) {
    setState(() {
      _selected = val;
      _nominalController.text = val;
    });
  }

  InputDecoration _inputDeco(String hint, {required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF059669).withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF059669), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saldo rekening Anda akan BERTAMBAH sesuai nominal yang dipilih.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Sumber Dana',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _sumberController,
            decoration: _inputDeco('Contoh: ATM BCA, Setor Tunai, dll',
                icon: Icons.account_balance_rounded),
          ),
          const SizedBox(height: 20),
          const Text('Pilih Nominal Isi Saldo',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _nominals.map((val) {
              final isSelected = _selected == val;
              return GestureDetector(
                onTap: () => _pilihNominal(val),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF059669)
                        : const Color(0xFF059669).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(color: const Color(0xFF059669).withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Text(
                      'Rp $val',
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Atau masukkan nominal lain',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _selected = null),
            decoration: _inputDeco('Rp 0', icon: Icons.attach_money_rounded),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final nominal = _nominalController.text.trim();
                if (nominal.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Nominal wajib diisi'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16),
                  ));
                  return;
                }
                final amount = BalanceService.parseNominal(nominal);
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Nominal tidak valid'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16),
                  ));
                  return;
                }
                BalanceService.credit(amount);
                final fmt = 'Rp ' +
                    amount.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
                ActivityService.addTransaction(TransactionRecord(
                  type: 'topup',
                  title: 'Top Up Saldo Rekening',
                  nominal: fmt,
                  target: _sumberController.text.trim().isNotEmpty
                      ? _sumberController.text.trim()
                      : 'Setor Saldo',
                  time: DateTime.now(),
                ));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Saldo berhasil ditambahkan! Saldo sekarang: ${BalanceService.formattedBalance}'),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
                widget.onDone();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Isi Saldo Sekarang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Form Top Up Debit (E-Wallet / Pulsa / Data / Game) ─────────────────────

class _FormDebit extends StatefulWidget {
  final String menuTitle;
  final VoidCallback onDone;
  const _FormDebit({required this.menuTitle, required this.onDone});
  @override
  State<_FormDebit> createState() => _FormDebitState();
}

class _FormDebitState extends State<_FormDebit> {
  final _targetController = TextEditingController();
  final _nominalController = TextEditingController();
  String? _selected;

  final List<String> _nominals = [
    '10.000', '20.000', '50.000', '100.000', '200.000', '500.000'
  ];

  @override
  void dispose() {
    _targetController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  void _pilihNominal(String val) {
    setState(() {
      _selected = val;
      _nominalController.text = val;
    });
  }

  InputDecoration _inputDeco(String hint, {required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.topup, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  @override
  Widget build(BuildContext context) {
    final String labelTarget = widget.menuTitle.contains('Pulsa') ||
            widget.menuTitle.contains('Data')
        ? 'Nomor HP'
        : widget.menuTitle.contains('Game')
            ? 'ID Game'
            : 'Nomor / ID Tujuan';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.transfer.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.transfer.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.transfer, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nominal akan dipotong dari saldo rekening Anda.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.transfer,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(labelTarget,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _targetController,
            keyboardType: TextInputType.phone,
            decoration: _inputDeco('Masukkan nomor/ID tujuan',
                icon: Icons.person_outline_rounded),
          ),
          const SizedBox(height: 20),
          const Text('Pilih Nominal',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _nominals.map((val) {
              final isSelected = _selected == val;
              return GestureDetector(
                onTap: () => _pilihNominal(val),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.topup
                        : AppColors.topup.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(color: AppColors.topup.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      'Rp $val',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.topup,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final target = _targetController.text.trim();
                final nominal = _nominalController.text.trim();

                if (target.isEmpty || nominal.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Nomor/ID tujuan dan nominal wajib diisi'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16),
                  ));
                  return;
                }

                final amount = BalanceService.parseNominal(nominal);
                if (!BalanceService.debit(amount)) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Saldo tidak mencukupi. Saldo Anda: ${BalanceService.formattedBalance}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                  ));
                  return;
                }

                final fmt = 'Rp ' +
                    amount.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

                ActivityService.addTransaction(TransactionRecord(
                  type: 'topup',
                  title: widget.menuTitle,
                  nominal: fmt,
                  target: target,
                  time: DateTime.now(),
                ));

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      '${widget.menuTitle} berhasil! Sisa saldo: ${BalanceService.formattedBalance}'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
                widget.onDone();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.topup,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Konfirmasi Top Up',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
